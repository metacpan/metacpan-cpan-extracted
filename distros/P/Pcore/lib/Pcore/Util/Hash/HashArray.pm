package Pcore::Util::Hash::HashArray;

use Pcore -const;

our $INSIDEOUT = {};

const our $HASH       => 0;
const our $ARRAY      => 1;
const our $TIED_HASH  => 2;
const our $TIED_ARRAY => 3;

const our $EL_VAL => 0;
const our $EL_IDX => 1;

use overload    #
  '%{}' => sub {
    return $INSIDEOUT->{ $_[0] }->[$TIED_HASH];
  },
  '@{}' => sub {
    return $INSIDEOUT->{ $_[0] }->[$TIED_ARRAY];
  },
  fallback => 1;

sub DESTROY ($self) {
    delete $INSIDEOUT->{$self};

    return;
}

sub new ($self) {
    my $obj;

    $self = bless \$obj, $self;

    my $data = $INSIDEOUT->{$self} = [
        {},    # hash
        [],    # array
        {},    # tied hash
        [],    # tied array
    ];

    tie $data->[$TIED_HASH]->%*,  'HashArray::_TIED_HASH',  $data;
    tie $data->[$TIED_ARRAY]->@*, 'HashArray::_TIED_ARRAY', $data;

    return $self;
}

sub rand_key ($self) {
    my $array = $INSIDEOUT->{$self}->[$ARRAY];

    return $array->[ rand $array->@* ];
}

sub rand_val ($self) {
    my $obj = $INSIDEOUT->{$self};

    my $array = $obj->[$ARRAY];

    my $key = $array->[ rand $array->@* ];

    return $obj->[$HASH]->{$key}->[$EL_VAL];
}

sub TO_DUMP ( $self, $dumper, @ ) {
    my %args = (
        path => undef,
        splice @_, 2,
    );

    my $tags;

    return $dumper->_dump( $INSIDEOUT->{$self}->[$HASH] ), $tags;
}

package HashArray::_TIED_HASH;

use Pcore -const;
use Pcore::Util::Scalar qw[weaken];

sub TIEHASH ( $self, $data_ref ) {
    weaken $data_ref;

    return bless \$data_ref, $self;
}

sub STORE {
    my $data = $_[0]->$*;

    if ( my $el = $data->[$HASH]->{ $_[1] } ) {
        $el->[$EL_VAL] = $_[2];
    }
    else {
        my $el = $data->[$HASH]->{ $_[1] } = [];

        $el->[$EL_VAL] = $_[2];

        push $data->[$ARRAY]->@*, $_[1];

        $el->[$EL_IDX] = $data->[$ARRAY]->$#*;
    }

    return;
}

sub EXISTS {
    my $data = $_[0]->$*;

    return exists $data->[$HASH]->{ $_[1] };
}

sub FETCH {
    my $data = $_[0]->$*;

    return $data->[$HASH]->{ $_[1] }->[$EL_VAL];
}

sub DELETE {
    my $data = $_[0]->$*;

    my $el = delete $data->[$HASH]->{ $_[1] };

    if ( defined $el ) {
        my $idx = $el->[$EL_IDX];

        # last element
        if ( $idx == $data->[$ARRAY]->$#* ) {
            delete $data->[$ARRAY]->[$idx];
        }

        # not last element
        else {
            my $last_key = pop $data->[$ARRAY]->@*;

            $data->[$ARRAY]->[$idx] = $last_key;

            $data->[$HASH]->{$last_key}->[$EL_IDX] = $idx;
        }

        return $el->[$EL_VAL];
    }
    else {
        return;
    }
}

sub CLEAR {
    my $data = $_[0]->$*;

    $data->[$HASH]->%*  = ();
    $data->[$ARRAY]->@* = ();

    return;
}

sub FIRSTKEY {
    my $data = $_[0]->$*;

    my $keys = scalar keys $data->[$HASH]->%*;

    return each $data->[$HASH]->%*;
}

sub NEXTKEY {
    my $data = $_[0]->$*;

    return each $data->[$HASH]->%*;
}

sub SCALAR {
    my $data = $_[0]->$*;

    return scalar $data->[$HASH]->%*;
}

package HashArray::_TIED_ARRAY;

use Pcore;
use Pcore::Util::Scalar qw[weaken];

sub TIEARRAY ( $self, $data_ref ) {
    weaken $data_ref;

    return bless \$data_ref, $self;
}

sub EXISTS {
    my $data = $_[0]->$*;

    return exists $data->[$ARRAY]->[ $_[1] ];
}

sub FETCH {
    my $data = $_[0]->$*;

    my $key = $data->[$ARRAY]->[ $_[1] ];

    return defined $key ? $data->[$HASH]->{$key}->[$EL_VAL] : ();
}

sub FETCHSIZE {
    return scalar $_[0]->$*->[$ARRAY]->@*;
}

sub DELETE {
    my $data = $_[0]->$*;

    my $key = $data->[$ARRAY]->[ $_[1] ];

    if ( defined $key ) {

        # delete element
        my $el = delete $data->[$HASH]->{$key};

        # last element
        if ( $_[1] == $data->[$ARRAY]->$#* ) {
            pop $data->[$ARRAY]->@*;
        }

        # not last element
        else {
            my $last_key = $data->[$ARRAY]->@*;

            $data->[$ARRAY]->[ $_[1] ] = $last_key;

            $data->[$HASH]->{$last_key}->[$EL_IDX] = $_[1];
        }

        return $el->[$EL_VAL];
    }
    else {
        return;
    }
}

sub POP {
    return DELETE( $_[0], $_[0]->$*->[$ARRAY]->$#* );
}

sub SHIFT {
    return DELETE( $_[0], 0 );
}

sub CLEAR {
    my $data = $_[0]->$*;

    $data->[$HASH]->%*  = ();
    $data->[$ARRAY]->@* = ();

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 42, 43               | Miscellanea::ProhibitTies - Tied variable used                                                                 |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Hash::HashArray - efficiently access hash values using pop, shift or array index.

=head1 SYNOPSIS

    my $hash = Pcore::Util::Hash::HashArray->new;

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
