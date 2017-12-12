package Net::Async::Redis::Protocol;

use strict;
use warnings;

our $VERSION = '1.002'; # VERSION

my $CRLF = "\x0D\x0A";

sub encode {
    use B;
    use Scalar::Util qw(blessed reftype);
    use namespace::clean qw(blessed reftype);
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
    } elsif(B::svref_2object(\$data)->FLAGS & B::SVp_IOK) {
        return ':' . (0 + $data) . $CRLF;
    } elsif(!length($data)) {
        return '$0' . $CRLF . $CRLF;
    } elsif(length($data) < 100 and $data !~ /[$CRLF]/) {
        return '+' . $data . $CRLF;
    }
    return '$' . length($data) . $CRLF . $data . $CRLF;
}

sub encode_from_client {
    my ($self, @data) = @_;
    return '*' . (0 + @data) . $CRLF . join '', map {
        '$' . length($_) . $CRLF . $_ . $CRLF
    } @data;
}

sub decode {
    use Scalar::Util qw(looks_like_number);
    use namespace::clean qw(looks_like_number);

    my ($self, $bytes) = @_;

    ITEM:
    for ($$bytes) {
        if(defined(my $len = $self->{parsing_bulk})) {
            last unless length($_) >= $len + 2;
            die 'invalid bulk data, did not end in CRLF' unless substr($_, $len, 2, '') eq $CRLF;
            $self->item(substr $_, 0, delete $self->{parsing_bulk}, '');
            redo;
        }
        if(s{^\+([^$CRLF]*)$CRLF}{}) {
            $self->item("$1");
            redo ITEM;
        } elsif(s{^-([^$CRLF]*)$CRLF}{}) {
            $self->item_error($1);
            redo ITEM;
        } elsif(s{^:([^$CRLF]*)$CRLF}{}) {
            my $int = $1;
            die 'invalid integer value ' . $int unless looks_like_number($int) && int($int) eq $int;
            $self->item(0 + $int);
            redo ITEM;
        } elsif(s{^\$-1$CRLF}{}) {
            $self->item(undef);
            redo ITEM;
        } elsif(s{^\$([0-9]+)$CRLF}{}) {
            my $len = $1;
            die 'invalid numeric value for length ' . $len unless 0+$len eq $len;
            $self->{parsing_bulk} = $len;
            redo;
        } elsif(s{^\*-1$CRLF}{}) {
            $self->item_array(undef);
            redo ITEM;
        } elsif(s{^\*([0-9]+)$CRLF}{}) {
            my $pending = $1;
            die 'invalid numeric value for array ' . $pending unless 0+$pending eq $pending;
            if($pending) {
                push @{$self->{active}}, { array => $pending };
            } else {
                $self->emit([]);
            }
            redo ITEM;
        }
    }
}

sub parse { $_[0]->decode($_[1]) }

sub item {
    my ($self, $data) = @_;
    if(@{$self->{active} || []}) {
        push @{$self->{active}[-1]{items}}, $data;
        return $self if --$self->{active}[-1]{array};
        $self->item((pop @{$self->{active}})->{items});
    } else {
        $self->emit($data);
    }
    $self
}

sub item_error {
    warn "error $_[1]";
    $_[0]
}

sub emit { $_[0]->{handler}->($_[1]) }

sub new { bless { @_[1..$#_] }, $_[0] }

1;

