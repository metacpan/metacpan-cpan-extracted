package Net::Async::Redis::Protocol;

use strict;
use warnings;

our $VERSION = '3.021'; # VERSION

=head1 NAME

Net::Async::Redis::Protocol - simple implementation of the Redis wire protocol

=head1 DESCRIPTION

Used internally by L<Net::Async::Redis> and L<Net::Async::Redis::Server>.

=cut

use Scalar::Util qw(blessed reftype looks_like_number);
use Log::Any qw($log);
use List::Util qw(min);

# Normal string interpolation
use constant CRLF => "\x0D\x0A";

# Regex usage
my $CRLF = CRLF;

sub new { bless { protocol => 'resp3', hashrefs => 0, @_[1..$#_] }, $_[0] }

=head2 encode

Given a Perl data structure, will return data suitable for sending
back as a response as from a Redis server.

Note that this is not the correct format for client requests,
see L</encode_from_client> instead.

=cut

sub encode {
    my ($self, $data) = @_;
    die 'blessed data is not ok' if blessed $data;
    if(my $type = reftype $data) {
        if($type eq 'ARRAY') {
            return '*' . (0 + @$data) . CRLF . join '', map $self->encode($_), @$data
        } elsif($type eq 'HASH') {
            return '%' . (0 + keys %$data) . CRLF . join '', map $self->encode($_), map { $_ => $data->{$_} } sort keys %$data
        }
        die 'no support for ' . $type
    }
    if(!defined($data)) {
        return $self->{protocol} eq 'resp3' ? '_' . CRLF : '$-1' . CRLF;
    } elsif(!length($data)) {
        return '$0' . CRLF . CRLF;
    } elsif(($data ^ $data) eq "0" and int(0+$data) eq $data and $data !~ /inf/i) {
        return ':' . (0 + $data) . CRLF;
    } elsif(($data ^ $data) eq "0" and 0+$data eq $data) {
        return ',' . lc(0 + $data) . CRLF;
    } elsif(length($data) < 100 and $data !~ /[$CRLF]/) {
        return '+' . $data . CRLF;
    }
    return '$' . length($data) . CRLF . $data . CRLF;
}

=head2 encode_from_client

Handles client format encoding. Expects a list of data items, and will
convert them into length-prefixed bulk strings as a single response item.

=cut

sub encode_from_client {
    my ($self, @data) = @_;
    return '*' . (0 + @data) . CRLF . join '', map {
        '$' . length($_) . CRLF . $_ . CRLF
    } @data;
}

=head2 decode

Decodes wire protocol data into Perl data structures.

Expects to be called with a reference to a byte string, and will
extract as much as it can from that string (destructively).

Likely to call L</item> or L</item_error> zero or more times.

=cut

sub decode {
    my ($self, $bytes) = @_;

    my $len = $self->{parsing_bulk};
    ITEM:
    for ($$bytes) {
        if($log->is_trace) {
            my $bytes = substr $_, 0, min(16, length($_));
            $log->tracef('Next few bytes: %s (%v02x)', $bytes, $bytes);
        }
        if(defined($len)) {
            last ITEM unless length($_) >= $len + 2;
            die 'invalid bulk data, did not end in CRLF' unless substr($_, $len, 2, '') eq CRLF;
            $self->item(substr $_, 0, delete $self->{parsing_bulk}, '');
            undef $len;
            last ITEM unless length;
        }
        if(s{^\+([^\x0D]*)$CRLF}{}) {
            $self->item("$1");
        } elsif(s{^:([^\x0D]*)$CRLF}{}) {
            my $int = $1;
            die 'invalid integer value ' . $int unless looks_like_number($int) && int($int) eq $int;
            $self->item(0 + $int);
        } elsif(s{^,([^\x0D]*)$CRLF}{}) {
            my $num = $1;
            die 'invalid numeric value ' . $num unless looks_like_number($num) && lc(0 + $num) eq lc($num);
            $self->item(0 + $num);
        } elsif(s{^#([tf])$CRLF}{}) {
            $self->item($1 eq 't');
        } elsif(s{^\$([0-9]+)$CRLF}{}) {
            $len = $1;
            die 'invalid numeric value for length ' . $len unless 0+$len eq $len;
            $self->{parsing_bulk} = $len;
        } elsif(s{^=([0-9]+)$CRLF}{}) {
            $len = $1;
            die 'invalid numeric value for length ' . $len unless 0+$len eq $len;
            $self->{parsing_bulk} = $len;
        } elsif(s{^\$-1$CRLF}{} or s{^\*-1$CRLF}{} or s{^_$CRLF}{}) {
            $self->item(undef);
        } elsif(s{^>([0-9]+)$CRLF}{}) {
            my $pending = $1;
            die 'invalid numeric value for push ' . $pending unless 0+$pending eq $pending;
            push @{$self->{active}}, {
                type => 'push',
                pending => $pending
            } if $pending;
        } elsif(s{^\*([0-9]+)$CRLF}{}) {
            my $pending = $1;
            die 'invalid numeric value for array ' . $pending unless 0+$pending eq $pending;
            if($pending) {
                push @{$self->{active}}, { type => 'array', pending => $pending };
            } else {
                $self->item([ ]);
            }
        } elsif(s{^~([0-9]+)$CRLF}{}) {
            my $pending = $1;
            die 'invalid numeric value for set ' . $pending unless 0+$pending eq $pending;
            if($pending) {
                push @{$self->{active}}, { type => 'set', pending => $pending };
            } else {
                $self->item([ ]);
            }
        } elsif(s{^%([0-9]+)$CRLF}{}) {
            my $pending = $1;
            die 'invalid numeric value for map ' . $pending unless 0+$pending eq $pending;
            if($pending) {
                # We provide 2x the count here, for key/value pairs, and expect
                # the handler to convert to a hash once it's received sufficient
                # items to emit the full element
                push @{$self->{active}}, { type => 'map', pending => 2 * $pending };
            } else {
                $self->item({ });
            }
        } elsif(s{^\|([0-9]+)$CRLF}{}) {
            my $pending = $1;
            die 'invalid numeric value for attribute ' . $pending unless 0+$pending eq $pending;
            push @{$self->{active}}, {
                type => 'attribute',
                pending => 2 * $pending
            } if $pending;
        } elsif(s{^-([^\x0D]*)$CRLF}{}) {
            $self->item_error($1);
        } elsif(s{^!([^\x0D]*)$CRLF}{}) {
            die 'cannot handle blob error yet';
        } else {
            last ITEM;
        }
        redo ITEM if length;
    }
}

sub parse { $_[0]->decode($_[1]) }

sub item {
    my ($self, $data) = @_;
    $data = [ %$data ] if ref $data eq 'HASH' and not $self->{hashrefs};
    while(1) {
        return $self->{handler}->($data) unless @{$self->{active} || []};

        push @{$self->{active}[-1]{items}}, $data;
        return if --$self->{active}[-1]{pending};
        my $active = pop @{$self->{active}};
        $data = $active->{type} eq 'map'
        ? ($self->{hashrefs}
            ? { @{$active->{items}} }
            : [ @{$active->{items}} ]
        )
        : $active->{items};

        # Skip attributes entirely for now
        return if $active->{type} eq 'attribute';
        return $self->item_pubsub($data) if $active->{type} eq 'push';
    }
}

sub item_error {
    my ($self, $err) = @_;
    $self->{error}->($err) if $self->{error};
    $self
}

sub item_pubsub {
    my ($self, $item) = @_;
    $self->{pubsub}->(@$item) if $self->{pubsub};
    $self
}

1;

__END__

=head1 AUTHOR

Tom Molesworth C<< <TEAM@cpan.org> >> plus contributors as mentioned in
L<Net::Async::Redis/CONTRIBUTORS>.

=head1 LICENSE

Copyright Tom Molesworth and others 2015-2022. Licensed under the same terms as Perl itself.

