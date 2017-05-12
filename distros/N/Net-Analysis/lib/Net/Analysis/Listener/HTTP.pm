package Net::Analysis::Listener::HTTP;
# $Id: HTTP.pm 140 2005-10-21 16:31:29Z abworrall $

# {{{ Boilerplate

use 5.008000;
our $VERSION = '0.02';
use strict;
use warnings;

use Carp qw(carp croak confess);

use Params::Validate qw(:all);

use base qw(Net::Analysis::Listener::Base);

# }}}

use HTTP::Response;
use HTTP::Request;

#### Callbacks
#
# {{{ validate_configuration

sub validate_configuration {
    my $self = shift;

    my %h = validate (@_, { v => {type => SCALAR,
                                  default => 0} });

    return \%h;
}

# }}}

# {{{ setup

# A chance to setup stuff for our listener
sub setup {
    my ($self) = shift;

    $self->{sesh} = {}; # TCP sessions
}

# }}}
# {{{ teardown

sub teardown {
    my ($self) = shift;
}

# }}}

# {{{ tcp_session_start

sub tcp_session_start {
    my ($self, $args) = @_;
    my $pkt = $args->{pkt}; # Might well be undef
    my $k   = $args->{socketpair_key};

    if ($self->{v} & 0x04) {
        $self->trace ("  ==== tcp session start [$pkt->{from} -> $pkt->{to}]");
    }
}

# }}}
# {{{ tcp_session_end

sub tcp_session_end {
    my ($self, $args) = @_;
    my $pkt = $args->{pkt}; # Might well be undef
    my $k   = $args->{socketpair_key};

    $self->trace("  ==== tcp session end [$k]") if ($self->{v} & 0x04);

    my $sesh = $self->_remove_sesh ($k);

    if (defined $sesh) {
        # XXXX we have not yet seen the response to this ...
        delete ($sesh->{req_mono}); # In case it ends up leaking _somehow_
    }
}

# }}}
# {{{ tcp_monologue

sub tcp_monologue {
    my ($self, $args) = @_;
    my $k    = $args->{socketpair_key};
    my $mono = $args->{monologue};
    my $sesh = $self->_get_sesh ($k);
    my $d    = $mono->{data};

    my ($l) = (split('\n', $d))[0];
    my ($first_line) = '';
    if (defined $l) {
        $l = substr($l,0,40) if (length($l) > 40);
        $first_line = _printable($l);
    }

    our $TRACE=0;

#    $TRACE = 1 if ($k eq '10.6.94.7:8080-159.206.22.101:2647');
#    if ($k eq '10.6.94.7:8080-159.206.22.101:2647') {
#        print "mono $k ".$mono->first_packet()->{time}."\n";
#    }

    if ($d =~ m!^(get|post|head)\s+([^ ]+)(HTTP/\d.\d)?!i) {
        if (exists $sesh->{req}) {
            carp "already have a req for $k, overwriting it\n";
        }
        $sesh->{req} = HTTP::Request->parse($d);
        $sesh->{req_mono} = $mono; # Careful ! Must delete this ...

        my $host = $sesh->{req}->header('host') || '(nohost)';
        my $uri = $sesh->{req}->uri() || '/noURI';
        $self->_trace (">>!> $host$uri <<\n");


    } elsif ($d =~ m!^HTTP/\d.\d\s+(\d{3})!i) {
        my $resp = HTTP::Response->parse($d);

        _unchunk_response ($resp); # Should really port this to HTTP::Message

        if (defined $sesh->{req}) {
            my $host = $sesh->{req}->header('host') || '(nohost)';
            my $uri = $sesh->{req}->uri() || '/noURI';
            $self->_trace (">>>> $host$uri <<\n");
        } else {
            $self->_trace (">>>> ????? (no req found in sesh) <<\n");
        }

        $self->_trace ("  << ".$resp->code().", ".
                       length($resp->content())." bytes");

        my $req_mono = $sesh->{req_mono};
        my $args = {socketpair_key => $k,
                    req            => $sesh->{req},
                    req_mono       => $req_mono,
                    resp           => $resp,
                    resp_mono      => $mono,
                    t_end          => $mono->t_end()->clone()};
        if (defined $req_mono) {
            $args->{t_start} = $sesh->{req_mono}->t_start()->clone();
            $args->{t_elapsed} = $args->{t_end} - $args->{t_start};
        }

        $self->emit (name => 'http_transaction', args => $args);

        delete ($sesh->{req});
        delete ($sesh->{req_mono});

    } else {
        $self->_trace ("malformed HTTP monologue in $k starts: $first_line\n");
    }
}

# }}}
# {{{ http_transaction

# Listen to our own event and print very basic report, if asked
sub http_transaction {
    my ($self, $args) = @_;
    return if (! $self->{v});

    my $req = $args->{req};
    my $uri = (defined $req) ? $req->uri() : "(no uri)";
    my $t = $args->{t_elapsed} || -1.0;
    printf "%8.4fs : %s\n", $t, $uri;
}

# }}}

# {{{ as_string

sub as_string {
    my ($self) = @_;
    my $s = '';

    $s .= "[".ref($self)."]";

    return $s;
}

# }}}

#### Support funcs
#
# {{{ _trace

# This may become more clever ...

our $TRACE=0;

sub _trace {
    my ($self) = shift;

    return if (! $TRACE);

    foreach (@_) {
        my $l = $_; #  Skip 'Modification of a read-only value' errors
        chomp ($l);
        print "$l\n";
    }
}

# }}}
# {{{ _{get|remove}_sesh

sub _get_sesh {
    my ($self, $sesh_key) = @_;

    if (! exists $self->{sesh}{$sesh_key}) {
        $self->{sesh}{$sesh_key} = {};
    }

    return $self->{sesh}{$sesh_key};
}

sub _remove_sesh {
    my ($self, $sesh_key) = @_;

    return delete ($self->{sesh}{$sesh_key});
}

# }}}
# {{{ _printable

sub _printable {
    my $raw = shift;
    $raw =~ s {([^\x20-\x7e])} {.}g;
    return $raw;
}

# }}}
# {{{ _unchunk_response

sub _unchunk_response {
    my ($resp) = @_;

    my $transfer_encoding = $resp->header('transfer-encoding');

    return if (!$transfer_encoding);

    # http://www.jmarshall.com/easy/http/#http1.1c2
    if ($transfer_encoding eq 'chunked') {
        my $chunked_data = $resp->content();
        my $unchunked_data = '';

        my ($chunk_size_hex, $chunk_size, $chunk);
        while ($chunked_data) {
            # Read chunk size. Discard chunking comments.
            ($chunk_size_hex, $chunked_data) = ($chunked_data =~ /^([0-9a-fA-F]+)(?:;.*)?\r\n(.*)/s);
            last if (!defined $chunk_size_hex);
            $chunk_size = oct("0x$chunk_size_hex");

            last if ($chunk_size == 0); # Sod trailing headers!

            # allow for \r\n trailing the chunk
            $chunk = substr ($chunked_data, 0, $chunk_size+2, '');
            substr ($chunk, -2, 2, '');

            $unchunked_data .= $chunk;
        }

        $resp->content($unchunked_data);
    }
}

# }}}

1;
__END__
# {{{ POD

=head1 NAME

Net::Analysis::Listener::HTTP - an HTTP listener

=head1 SYNOPSIS

Listens for:
  tcp_session_start
  tcp_session_end
  tcp_monologue

Emits:
  http_transaction

=head1 CONFIGURATION

 v - verbosity. If >0, print out sample one-line summary for each transaction

=head1 EMITTED EVENTS

=head2 C<http_transaction>

Marries together two <tcp_monologues> that correspond to a HTTP request and
response. The event will contain the following arguments:

 socketpair_key - uniquely identifies the TCP session
 req            - HTTP::Request object
 resp           - HTTP::Response object
 t_start        - Net::Analysis::Time object, start of xaction
 t_end          - Net::Analysis::Time object, end of xaction
 t_elapsed      - Net::Analysis::Time object, duration of xaction
 req_mono       - Net::Analysis::TCPMonologue object for the request
 resp_mono      - Net::Analysis::TCPMonologue object for the response

If you need packet level info, you can dig it out of the TCPMonologue objects.

Note that this particular module does not currently support HTTP
pipelining; it expects requests/responses to correspond to
back-and-forth monologues. Look at the
L<Net::Analysis::Listener::HTTPPipelining> for an alpha implementation
of handling pipelined HTTP.

=head1 SEE ALSO

L<Net::Analysis::Listener::Base>, L<Net::Analysis::Listener::HTTPPipelining>.

=head1 AUTHOR

Adam B. Worrall, E<lt>worrall@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Adam B. Worrall

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut

# }}}

# {{{ -------------------------={ E N D }=----------------------------------

# Local variables:
# folded-file: t
# end:

# }}}
