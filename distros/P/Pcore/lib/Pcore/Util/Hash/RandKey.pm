package Pcore::Util::Hash::RandKey;

use Pcore;

use overload    #
  q[%{}] => sub {
    return $_[0]->[0];
  },
  fallback => undef;

sub new ($self) {
    my $obj = bless [
        {},     # key => index
        [],     # keys array
        []      # values array
    ], $self;

    tie $obj->[0]->%*, 'Pcore::Util::Hash::RandKey::_HASH', $obj->[1], $obj->[2];

    return $obj;
}

sub rand_key ($self) {
    return $self->[1]->[ rand $self->[1]->@* ];
}

sub rand_val ($self) {
    return $self->[2]->[ rand $self->[2]->@* ];
}

package Pcore::Util::Hash::RandKey::_HASH;

use Pcore;
use Tie::Hash;
use base qw[Tie::ExtraHash];

sub STORE {
    if ( exists $_[0]->[0]->{ $_[1] } ) {
        $_[0]->[2]->[ $_[0]->[0]->{ $_[1] } ] = $_[2];
    }
    else {
        push $_[0]->[1]->@*, $_[1];

        push $_[0]->[2]->@*, $_[2];

        $_[0]->[0]->{ $_[1] } = $_[0]->[1]->$#*;
    }

    return;
}

sub FETCH {
    if ( exists $_[0]->[0]->{ $_[1] } ) {
        return $_[0]->[2]->[ $_[0]->[0]->{ $_[1] } ];
    }
    else {
        return;
    }
}

sub DELETE {
    my $val;

    if ( exists $_[0]->[0]->{ $_[1] } ) {
        my $idx = delete $_[0]->[0]->{ $_[1] };

        # store old value
        $val = $_[0]->[2]->[$idx];

        if ( $idx == $_[0]->[1]->$#* ) {
            pop $_[0]->[1]->@*;

            pop $_[0]->[2]->@*;
        }
        else {

            # move last key to the new index
            $_[0]->[1]->[$idx] = pop $_[0]->[1]->@*;

            # move last value to the new index
            $_[0]->[2]->[$idx] = pop $_[0]->[2]->@*;

            # update index
            $_[0]->[0]->{ $_[0]->[1]->[$idx] } = $idx;
        }
    }

    return $val;
}

sub CLEAR {
    $_[0]->[0]->%* = ();

    $_[0]->[1]->@* = ();

    $_[0]->[2]->@* = ();

    return;
}

sub SCALAR {
    return scalar $_[0]->[1]->@*;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 18                   | Miscellanea::ProhibitTies - Tied variable used                                                                 |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Hash::RandKey

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
