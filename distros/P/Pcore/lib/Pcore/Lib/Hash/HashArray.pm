package Pcore::Lib::Hash::HashArray;

use Pcore -const;
use Pcore::Lib::Scalar qw[refaddr];

const our $HASH       => 0;
const our $KEYS       => 1;
const our $VALS       => 2;
const our $TIED_HASH  => 3;
const our $TIED_ARRAY => 4;

use overload    #
  '%{}' => sub {
    return $_[0]->$*->[$TIED_HASH];
  },
  '@{}' => sub {
    return $_[0]->$*->[$TIED_ARRAY];
  },
  fallback => 1;

sub new ($self) {
    $self = bless \[
        {},     # hash, key => idx
        [],     # array, keys
        [],     # array, values
        {},     # tied hash
        [],     # tied array
    ], $self;

    tie $self->$*->[$TIED_HASH]->%*,  'HashArray::_TIED_HASH',  $self->$*;
    tie $self->$*->[$TIED_ARRAY]->@*, 'HashArray::_TIED_ARRAY', $self->$*;

    return $self;
}

sub rand_key ($self) {
    my $keys = $self->$*->[$KEYS];

    return $keys->[ rand $keys->@* ];
}

sub rand_val ($self) {
    my $values = $self->$*->[$VALS];

    return $values->[ rand $values->@* ];
}

sub key_at ( $self, $idx ) {
    return $self->$*->[$KEYS]->[$idx];
}

sub TO_DUMP ( $self, $dumper, @ ) {
    my %args = (
        path => undef,
        splice @_, 2,
    );

    my $tags;

    my $data = $self->$*;

    return $dumper->_dump( [ map {qq[$data->[$KEYS]->[$_] = $data->[$VALS]->[$_]]} 0 .. $data->[$KEYS]->$#* ] ), $tags;
}

package HashArray::_TIED_HASH;

use Pcore -const;
use Pcore::Lib::Scalar qw[weaken];

sub TIEHASH ( $self, $data_ref ) {
    weaken $data_ref;

    return bless \$data_ref, $self;
}

sub STORE {
    my $data = $_[0]->$*;

    if ( exists $data->[$HASH]->{ $_[1] } ) {
        $data->[$VALS]->[ $data->[$HASH]->{ $_[1] } ] = $_[2];
    }
    else {
        push $data->[$KEYS]->@*, $_[1];
        push $data->[$VALS]->@*, $_[2];

        $data->[$HASH]->{ $_[1] } = $data->[$KEYS]->$#*;
    }

    return;
}

sub EXISTS {
    return exists $_[0]->$*->[$HASH]->{ $_[1] };
}

sub FETCH {
    my $data = $_[0]->$*;

    if ( exists $data->[$HASH]->{ $_[1] } ) {
        return $data->[$VALS]->[ $data->[$HASH]->{ $_[1] } ];
    }
    else {
        push $data->[$KEYS]->@*, $_[1];
        push $data->[$VALS]->@*, undef;

        $data->[$HASH]->{ $_[1] } = $data->[$KEYS]->$#*;

        return undef;    ## no critic qw[Subroutines::ProhibitExplicitReturnUndef]
    }
}

sub DELETE {
    my $data = $_[0]->$*;

    my $idx = delete $data->[$HASH]->{ $_[1] };

    # key was found and deleted from the hash
    if ( defined $idx ) {

        # last element was deleted
        if ( $idx == $data->[$KEYS]->$#* ) {

            # delete last key
            pop $data->[$KEYS]->@*;

            # delete and return last value
            return pop $data->[$VALS]->@*;
        }

        # hash has other elements
        else {
            my $val = $data->[$VALS]->[$idx];

            my $last_key = pop $data->[$KEYS]->@*;

            # move last element to the idx of the deleted element
            $data->[$HASH]->{$last_key} = $idx;
            $data->[$KEYS]->[$idx]      = $last_key;
            $data->[$VALS]->[$idx]      = pop $data->[$VALS]->@*;

            return $val;
        }
    }
    else {
        return undef;    ## no critic qw[Subroutines::ProhibitExplicitReturnUndef]
    }
}

sub CLEAR {
    my $data = $_[0]->$*;

    $data->[$HASH]->%* = ();
    $data->[$KEYS]->@* = ();
    $data->[$VALS]->@* = ();

    return;
}

sub FIRSTKEY {
    my $data = $_[0]->$*;

    # reset iterator
    scalar keys $data->[$HASH]->%*;

    return each $data->[$HASH]->%*;
}

sub NEXTKEY {
    return each $_[0]->$*->[$HASH]->%*;
}

sub SCALAR {
    return scalar $_[0]->$*->[$HASH]->%*;
}

package HashArray::_TIED_ARRAY;

use Pcore;
use Pcore::Lib::Scalar qw[weaken];

sub TIEARRAY ( $self, $data_ref ) {
    weaken $data_ref;

    return bless \$data_ref, $self;
}

sub EXISTS {
    return exists $_[0]->$*->[$VALS]->[ $_[1] ];
}

sub FETCH {
    return $_[0]->$*->[$VALS]->[ $_[1] ];
}

sub FETCHSIZE {
    return scalar $_[0]->$*->[$VALS]->@*;
}

sub DELETE {
    return delete $_[0]->$*->[$VALS]->[ $_[1] ];
}

sub POP {
    my $data = $_[0]->$*;

    my $key = pop $data->[$KEYS]->@*;

    if ( defined $key ) {
        delete $data->[$HASH]->{$key};

        return pop $data->[$VALS]->@*;
    }
    else {
        return undef;    ## no critic qw[Subroutines::ProhibitExplicitReturnUndef]
    }
}

sub SHIFT {
    my $data = $_[0]->$*;

    my $key = shift $data->[$KEYS]->@*;

    if ( defined $key ) {

        # delete current key
        delete $data->[$HASH]->{$key};

        # delete current val
        my $val = shift $data->[$VALS]->@*;

        # move last key
        if ( defined( my $last_key = pop $data->[$KEYS]->@* ) ) {
            $data->[$HASH]->{$last_key} = 0;
            unshift $data->[$KEYS]->@*, $last_key;
            unshift $data->[$VALS]->@*, pop $data->[$VALS]->@*;
        }

        return $val;
    }
    else {
        return undef;    ## no critic qw[Subroutines::ProhibitExplicitReturnUndef]
    }
}

sub CLEAR {
    my $data = $_[0]->$*;

    $data->[$HASH]->%* = ();
    $data->[$KEYS]->@* = ();
    $data->[$VALS]->@* = ();

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 30, 31               | Miscellanea::ProhibitTies - Tied variable used                                                                 |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Lib::Hash::HashArray - efficiently access hash values using pop, shift or array index.

=head1 SYNOPSIS

    my $hash = Pcore::Lib::Hash::HashArray->new;

    $hash->{1} = 'v1';
    $hash->{2} = 'v2';
    $hash->{3} = 'v3';

    say dump [ keys $hash->%* ];
    say dump [ values $hash->%* ];

    say $hash->[1];
    say shift $hash->@*;
    say pop $hash->@*;

    say $hash->rand_key;
    say $hash->rand_val;

=head1 DESCRIPTION

Efficiently access hash values using pop, shift or array index.

C<$hash-E<gt>[$idx]> works much faster, than standard C<( values $hash-E<gt>%* )[$idx]>.

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
