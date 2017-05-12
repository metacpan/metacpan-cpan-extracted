package Net::Analysis::Listener::HTTPPipelining;
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

use Net::Analysis::Packet qw(:pktslots :func);
use Net::Analysis::TCPMonologue;

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
    return if (! defined $sesh);

    $self->_unpipeline_data($sesh);
}

# }}}
# {{{ tcp_monologue

# In a pipelined request, the concept of orderly back-and-forth
#  monologues breaks down. Conceptually, all the requests are
#  glued together into one big monologue, and then all the responses
#  are returned in another big monologue.
# These jumbo monlogues may be transmitted simultaneusly (that is
#  kinda the point of pipelining ;), so from the perspective of our
#  pcap files, the divisions between monologues are arbitrary.
# So, we assign no meaning to the monologues that arrive; all we do
#  is steal the packets from them.
# All the hard work - breaking apart the jumbo monologues into separate
#  requests and responses, pairing them up, and generating synthetic
#  monologues, is done in tcp_session_end.

sub tcp_monologue {
    my ($self, $args) = @_;
    my $k    = $args->{socketpair_key};
    my $mono = $args->{monologue};
    my $sesh = $self->_get_sesh ($k);

    # Decide which jumbo monologue to place these pkts in
    my $socketpair_from = $mono->first_packet()->[PKT_SLOT_FROM];

    my $pkts = $sesh->{$socketpair_from} ||= [];
    push (@$pkts, @{ $mono->_data_packets }); # POTENTIAL MEM LEAK !! TAKE CARE
}

# }}}
# {{{ http_transaction

# Listen to our own event and print very basic report, if asked
sub http_transaction {
    my ($self, $args) = @_;
    return if (! $self->{v});

    my $req = $args->{req};
    my $uri = (defined $req) ? $req->uri() : "(no uri)";
    my $method = (defined $req) ? $req->method() : "(no method)";
    my $t = $args->{t_elapsed} || -1.0;
    printf "%8.4fs : $method %s\n", $t, $uri;
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

# {{{ _unpipeline_data

sub _unpipeline_data {
    my $self = shift;
    my ($sesh) = @_;

    my @jumbo_monos;
    foreach my $k (keys %$sesh) {
        my $mono = Net::Analysis::TCPMonologue->new();
        foreach my $pkt (@{ $sesh->{$k} }) {
            $mono->add_packet ($pkt);
        }
        push (@jumbo_monos, $mono);
    }

    my ($req_mono, $resp_mono);
    if ($jumbo_monos[0]->data =~ m!^(get|post|head)\s+([^ ]+)(HTTP/\d.\d)?!i) {
        ($req_mono, $resp_mono) = @jumbo_monos;
    } elsif ($jumbo_monos[1]->data =~ m!^(get|post|head)\s+([^ ]+)(HTTP/\d.\d)?!i) {
        ($resp_mono, $req_mono) = @jumbo_monos;
    } else {
        carp ("This TCP session doesn't look very HTTPish");
    }

    my (@reqs)  = $self->_unpipeline_http_requests ($req_mono);
    my (@resps) = $self->_unpipeline_http_responses ($resp_mono);
    if (@reqs != @resps) {
        carp ("found ".scalar(@reqs)." reqs but ".scalar(@resps).
              " resps in pipelined HTTP");
        return;
    }

    while (@reqs) {
        my ($req_data, $req_mono) = @{ shift (@reqs) };
        my ($resp_data, $resp_mono) = @{ shift (@resps) };

        my ($http_req) = HTTP::Request->parse($req_data);
        my ($http_resp) = HTTP::Response->parse($resp_data);
        _unchunk_response ($http_resp); # Should port this to HTTP::Message

        my $host = $http_req->header('host') || '(nohost)';
        my $uri = $http_req->uri() || '/noURI';
        $self->_trace (">>>> $host$uri <<\n");

        $self->_trace ("  << ".$http_resp->code().", ".
                       length($http_resp->content())." bytes");

        my $args = {socketpair_key => $req_mono->socketpair_key(),
                    req            => $http_req,
                    req_mono       => $req_mono,
                    resp           => $http_resp,
                    resp_mono      => $resp_mono,
                    t_end          => $resp_mono->t_end()->clone()};

        $args->{t_start} = $req_mono->t_start()->clone();
        $args->{t_elapsed} = $args->{t_end} - $args->{t_start};

        $self->emit (name => 'http_transaction', args => $args);
    }
}

# }}}
# {{{ _unpipeline_http_requests

sub _unpipeline_http_requests {
    my $self = shift;
    my ($mono) = @_;

    # rfc 2612/8.1.2.2 : "Clients SHOULD NOT pipeline requests using
    #                     non-idempotent methods"
    # rfc 2612/9.1.2   : (GET, HEAD, PUT, DELETE) are idempotent.
    # But, PUT may contain a data block (like POST), so we need to take care

    my @ret;
    my ($n_start,$n_end) = (0,0);
    my @blocks = (map {$_."\r\n\r\n"} split ("\r\n\r\n", $mono->data()));
    while (@blocks) {
        $_ = shift(@blocks);

        # PUT and POST requests have data after the request/header block;
        #  snarf it if needed
        $_ .= shift(@blocks) if (/^(put|post) /i);

        $n_end = $n_start + length($_) - 1;

        #print "  >> [$n_start, $n_end] ".(split("\n",$_))[0]."\n";

        # Now build a mono from the packets that made up this block
        my $sub_mono = Net::Analysis::TCPMonologue->new();
        foreach my $pkt (@{ $mono->which_pkts($n_start,$n_end) }) {
            $sub_mono->add_packet ($pkt);
        }

        push (@ret, [$_, $sub_mono]);

        $n_start = $n_end+1;
    }

    #print ">>>>[".($n_end+1)." / ".$mono->length()." ]>>>>\n";
    return @ret;
}

# }}}
# {{{ _unpipeline_http_responses

# This is knottier than it looks.

# I just split on what looks like the start of a response. But if a response
#  just so happened to contain a string that matched "HTTP/1.1 200 OK", this
#  breaks.
# Ideally, I'd parse the Content-Length header instead, and only read the
#  right amount of data. But, a HEAD request generates a response with no
#  body data, but a content-length that indicates what the response *would*
#  have been (for a GET).
# So: I need to know the request method in order to know whether to trust
#  the Content-Length header, which is altogether too much irritation for now.

sub _unpipeline_http_responses {
    my $self = shift;
    my ($mono) = @_;
    my (@ret);

    my @bits = split (qr{(HTTP/\d\.\d \d\d\d)}, $mono->data());
    shift (@bits); # Grr, empty field to the left of first "HTTP/1.1..."

    my ($n_start,$n_end) = (0,0);
    while (@bits) {
        $_ = shift (@bits);
        $_ .= shift (@bits);

        $n_end = $n_start + length($_) - 1;

        # print "  << [$n_start, $n_end] ".(split("\n",$_))[0]."\n";

        # Now build a mono from the packets that made up this block
        my $sub_mono = Net::Analysis::TCPMonologue->new();
        foreach my $pkt (@{ $mono->which_pkts($n_start,$n_end) }) {
            $sub_mono->add_packet ($pkt);
        }

        push (@ret, [$_, $sub_mono]);

        $n_start = $n_end+1;
    }

    #print "<<<<[".($n_end+1)." / ".$mono->length()." ]<<<<\n";
    return @ret;
}

# }}}

1;
__END__
# {{{ POD

=head1 NAME

Net::Analysis::Listener::HTTPPipelining - another HTTP listener

=head1 SYNOPSIS

This is an alternate version of N::A::L::HTTP, which has support for
pipelined HTTP requests. It is experimental; eventually, it will
become the default version of N::A::L::HTTP.

=head1 SEE ALSO

Net::Analysis::Listener::HTTP

=head1 AUTHOR

Adam B. Worrall, E<lt>worrall@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Adam B. Worrall

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut

# }}}

# {{{ tcp_session_end

sub tcp_session_end {
    my ($self, $args) = @_;
    my $pkt = $args->{pkt}; # Might well be undef
    my $k   = $args->{socketpair_key};

    $self->trace("  ==== tcp session end [$k]") if ($self->{v} & 0x04);

    my $sesh = $self->_remove_sesh ($k);
    return if (! defined $sesh);

    my ($req_k, $resp_k);
    foreach my $k (keys %$sesh) {
        my $d = $sesh->{$k}->data();
        # If a HTTP response happens to contain this string, this breaks
        $req_k = $k if ($d =~ m!^(get|post|head)\s+([^ ]+)(HTTP/\d.\d)?!i);
    }
    foreach my $k (keys %$sesh) {
        $resp_k = $k if ($k ne $req_k);
    }

    # Basically, I'm assuming that we got all packets in question
    #  (e.g. we're not missing a few initial request packets).

    # split up all the requests ...
    if ($sesh->{$req_k} !~ /^(get|post|head)\s+/i) {
        carp "HTTP request stream in $k had leading junk\n";
    }
    my @reqs = split ("\r\n\r\n", $sesh->{$req_k});

    # ... split up all the responses
    if ($sesh->{$resp_k} !~ m{^http/\d.\d \d.\d\s+}i) {
        carp "HTTP response stream in $k had leading junk\n";
    }
    my @t_resps = split (qr{(http/\d.\d \d{3}\s+[^\n]+)}i, $sesh->{$resp_k});
    shift(@t_resps); # LHS of the first split is the empty string
    # Recombine the elements, to glue the split field (HTTP ...) onto the data
    my @resps;
    while (@t_resps) {
        push (@resps, shift(@t_resps).shift(@t_resps));
    }

    if (@reqs != @resps) {
        carp "number of HTTP reqs not the same as HTTP resps";
    }

    while (@reqs) {
        my $d_req = shift (@reqs);
        my $d_resp = shift (@resps);

        #print "$d_req\n";

        my $req = HTTP::Request->parse ($d_req);
        my $resp = HTTP::Response->parse($d_resp);
        _unchunk_response ($resp); # Should really port this to HTTP::Message

        my $host = $req->header('host') || '(nohost)';
        my $uri = $req->uri() || '/noURI';
        $self->_trace (">>>> $host$uri <<\n");

        $self->_trace ("  << ".$resp->code().", ".
                       length($resp->content())." bytes");

        my $args = {socketpair_key => $k,
                    req            => $req,
                    #req_mono       => $req_mono,
                    resp           => $resp,
                    #resp_mono      => $mono,
                    #t_end          => $mono->t_end()->clone(),
                   };
        #if (defined $req_mono) {
        #    $args->{t_start} = $sesh->{req_mono}->t_start()->clone();
        #    $args->{t_elapsed} = $args->{t_end} - $args->{t_start};
        #}

        $self->emit (name => 'http_transaction', args => $args);
    }
}

# }}}
# {{{ tcp_monologue2

sub tcp_monologue2 {
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
# {{{ _http_message_has_body

sub _http_message_has_body {
    my $self = shift;
    my ($str,$str2) = @_;

    if ($str =~ m!^(get|post|head|put|delete)\s+([^ ]+)(HTTP/\d.\d)?!i) {
        return (($1 eq 'PUT') || ($1 eq 'POST')) ? 1 : 0;

    } elsif ($str =~ m!^HTTP/\d.\d\s+(\d{3})!i) {
        return 0;
    }
}

# }}}

# {{{ -------------------------={ E N D }=----------------------------------

# Local variables:
# folded-file: t
# end:

# }}}
