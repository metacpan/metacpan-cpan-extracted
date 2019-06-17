package Net::Async::Redis::Protocol;

use strict;
use warnings;

our $VERSION = '2.000'; # VERSION

=head1 NAME

Net::Async::Redis::Protocol - simple implementation of the Redis wire protocol

=head1 DESCRIPTION

Used internally by L<Net::Async::Redis> and L<Net::Async::Redis::Server>.

=cut

use Scalar::Util qw(blessed reftype looks_like_number);
use Log::Any qw($log);

my $CRLF = "\x0D\x0A";

sub new { bless { @_[1..$#_] }, $_[0] }

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
            return '*' . (0 + @$data) . $CRLF . join '', map $self->encode($_), @$data
        } elsif($type eq 'HASH') {
            die 'no hash support'
        }
        die 'no support for ' . $type
    }
    if(!defined($data)) {
        return '$-1' . $CRLF;
    } elsif(!length($data)) {
        return '$0' . $CRLF . $CRLF;
    } elsif(($data ^ $data) eq "0" and int(0+$data) eq $data) {
        return ':' . (0 + $data) . $CRLF;
    } elsif(length($data) < 100 and $data !~ /[$CRLF]/) {
        return '+' . $data . $CRLF;
    }
    return '$' . length($data) . $CRLF . $data . $CRLF;
}

=head2 encode_from_client

Handles client format encoding. Expects a list of data items, and will
convert them into length-prefixed bulk strings as a single response item.

=cut

sub encode_from_client {
    my ($self, @data) = @_;
    return '*' . (0 + @data) . $CRLF . join '', map {
        '$' . length($_) . $CRLF . $_ . $CRLF
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
        if(defined($len)) {
            last ITEM unless length($_) >= $len + 2;
            die 'invalid bulk data, did not end in CRLF' unless substr($_, $len, 2, '') eq $CRLF;
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
        } elsif(s{^\$-1$CRLF}{}) {
            $self->item(undef);
        } elsif(s{^\$([0-9]+)$CRLF}{}) {
            $len = $1;
            die 'invalid numeric value for length ' . $len unless 0+$len eq $len;
            $self->{parsing_bulk} = $len;
        } elsif(s{^\*-1$CRLF}{}) {
            $self->item(undef);
        } elsif(s{^\*([0-9]+)$CRLF}{}) {
            my $pending = $1;
            die 'invalid numeric value for array ' . $pending unless 0+$pending eq $pending;
            if($pending) {
                push @{$self->{active}}, { array => $pending };
            } else {
                $self->item([]);
            }
        } elsif(s{^-([^\x0D]*)$CRLF}{}) {
            $self->item_error($1);
        } else {
            last ITEM;
        }
        redo ITEM if length;
    }
}

sub parse { $_[0]->decode($_[1]) }

sub item {
    my ($self, $data) = @_;
    while(1) {
        return $self->{handler}->($data) unless @{$self->{active} || []};

        push @{$self->{active}[-1]{items}}, $data;
        return if --$self->{active}[-1]{array};
        $data = (pop @{$self->{active}})->{items};
    }
}

sub item_error {
    my ($self, $err) = @_;
    $self->{error}->($err) if $self->{error};
    $self
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth and others 2015-2019. Licensed under the same terms as Perl itself.

