package Pcore::Util::Hash::LRU::_CONST;

use Pcore -const, -export => { CONST => [qw[$HASH $TIED_HASH $FIRST $LAST $ATTRS $KEY $VAL $PREV $LAST]] };

const our $HASH      => 0;
const our $TIED_HASH => 1;
const our $FIRST     => 2;
const our $LAST      => 3;
const our $ATTRS     => 4;

const our $KEY  => 0;
const our $VAL  => 1;
const our $PREV => 2;
const our $NEXT => 3;

package Pcore::Util::Hash::LRU;

use Pcore;

Pcore::Util::Hash::LRU::_CONST->import(qw[:CONST]);

our $INSIDEOUT = {};

use overload    #
  q[%{}] => sub {
    return $INSIDEOUT->{ $_[0] }->[$TIED_HASH];
  },
  fallback => 1;

sub DESTROY ($self) {
    delete $INSIDEOUT->{$self};

    return;
}

sub new ( $self, $max_size ) {
    die q[Max. size is required] if !$max_size;

    my $obj;

    $self = bless \$obj, $self;

    my $data = [
        {},       # hash
        {},       # tied hash
        undef,    # first el. ref
        undef,    # last el. ref
        {         # attrs
            max_size => $max_size,
        },
    ];

    $INSIDEOUT->{$self} = $data;

    tie $data->[$TIED_HASH]->%*, 'Pcore::Util::Hash::LRU::_HASH', $data;

    return $self;
}

sub rand_key ($self) {
    my $data = $INSIDEOUT->{$self};

    if ( my $size = scalar values $data->[$HASH]->%* ) {
        my $rand_el = ( values $data->[$HASH]->%* )[ rand $size ];

        return $rand_el->[$KEY];
    }
    else {
        return;
    }
}

sub rand_val ($self) {
    my $data = $INSIDEOUT->{$self};

    if ( my $size = scalar values $data->[$HASH]->%* ) {
        my $rand_el = ( values $data->[$HASH]->%* )[ rand $size ];

        return $rand_el->[$VAL];
    }
    else {
        return;
    }
}

sub TO_DUMP ( $self, $dumper, @ ) {
    my %args = (
        path => undef,
        splice @_, 2,
    );

    my $data = $INSIDEOUT->{$self};

    my $res = q[first key: ] . ( $data->[$FIRST] ? qq["$data->[$FIRST]->[$KEY]"] : 'undef' );

    $res .= qq[\nlast key: ] . ( $data->[$LAST] ? qq["$data->[$LAST]->[$KEY]"] : 'undef' );

    $res .= qq[\n] . dump { map { $_->[$KEY] => $_->[$VAL] } values $data->[$HASH]->%* };

    my $tags;

    return $res, $tags;
}

package Pcore::Util::Hash::LRU::_HASH;

use Pcore;
use Pcore::Util::Scalar qw[weaken];

Pcore::Util::Hash::LRU::_CONST->import(qw[:CONST]);

sub TIEHASH ( $self, $data_ref ) {
    weaken $data_ref;

    return bless \$data_ref, $self;
}

sub STORE {
    my $data = $_[0]->$*;

    # key already exists
    if ( my $el = $data->[$HASH]->{ $_[1] } ) {

        # set el. value
        $el->[$VAL] = $_[2];

        # move on top, if not on top
        if ( my $prev_el = $el->[$PREV] ) {

            # element is not last
            if ( my $next_el = $el->[$NEXT] ) {
                $prev_el->[$NEXT] = $next_el;

                weaken $prev_el->[$NEXT];

                $next_el->[$PREV] = $prev_el;

                weaken $next_el->[$PREV];
            }

            # element is last
            else {
                undef $prev_el->[$NEXT];

                $data->[$LAST] = $prev_el;
            }

            # move element on top
            undef $el->[$PREV];

            $el->[$NEXT] = $data->[$FIRST];

            weaken $el->[$NEXT];

            $el->[$NEXT]->[$PREV] = $el;

            weaken $el->[$NEXT]->[$PREV];

            $data->[$FIRST] = $el;
        }
    }

    # create new element
    else {
        my $max_size = $data->[$ATTRS]->{max_size};

        my $size = scalar keys $data->[$HASH]->%*;

        # max size is reached
        if ( $size == $max_size ) {

            # delete last element
            {
                # delete last element key
                my $last_el = delete $data->[$HASH]->{ $data->[$LAST]->[$KEY] };

                # not single element
                if ( my $prev_el = $last_el->[$PREV] ) {
                    undef $prev_el->[$NEXT];

                    $data->[$LAST] = $prev_el;
                }

                # single element
                else {
                    undef $data->[$FIRST];

                    undef $data->[$LAST];
                }
            }
        }

        # create new element on top
        my $el = $data->[$HASH]->{ $_[1] } = [ $_[1], $_[2], undef, $data->[$FIRST] ];

        if ( $el->[$NEXT] ) {
            $el->[$NEXT]->[$PREV] = $el;

            weaken $el->[$NEXT];

            weaken $el->[$NEXT]->[$PREV];
        }

        # set first element
        $data->[$FIRST] = $el;

        # set last element
        $data->[$LAST] = $el if !$data->[$LAST];
    }

    return;
}

sub FETCH {
    my $data = $_[0]->$*;

    if ( my $el = $data->[$HASH]->{ $_[1] } ) {

        # move on top, if not on top
        if ( my $prev_el = $el->[$PREV] ) {

            # element is not last
            if ( my $next_el = $el->[$NEXT] ) {
                $prev_el->[$NEXT] = $next_el;

                weaken $prev_el->[$NEXT];

                $next_el->[$PREV] = $prev_el;

                weaken $next_el->[$PREV];
            }

            # element is last
            else {
                undef $prev_el->[$NEXT];

                $data->[$LAST] = $prev_el;
            }

            # move element on top
            undef $el->[$PREV];

            $el->[$NEXT] = $data->[$FIRST];

            weaken $el->[$NEXT];

            $el->[$NEXT]->[$PREV] = $el;

            weaken $el->[$NEXT]->[$PREV];

            $data->[$FIRST] = $el;
        }

        return $el->[$VAL];
    }
    else {
        return;
    }
}

sub EXISTS {
    my $data = $_[0]->$*;

    if ( my $el = $data->[$HASH]->{ $_[1] } ) {

        # move on top, if not on top
        if ( my $prev_el = $el->[$PREV] ) {

            # element is not last
            if ( my $next_el = $el->[$NEXT] ) {
                $prev_el->[$NEXT] = $next_el;

                weaken $prev_el->[$NEXT];

                $next_el->[$PREV] = $prev_el;

                weaken $next_el->[$PREV];
            }

            # element is last
            else {
                undef $prev_el->[$NEXT];

                $data->[$LAST] = $prev_el;
            }

            # move element on top
            undef $el->[$PREV];

            $el->[$NEXT] = $data->[$FIRST];

            weaken $el->[$NEXT];

            $el->[$NEXT]->[$PREV] = $el;

            weaken $el->[$NEXT]->[$PREV];

            $data->[$FIRST] = $el;
        }

        return 1;
    }
    else {
        return;
    }
}

sub DELETE {
    my $data = $_[0]->$*;

    if ( my $el = delete $data->[$HASH]->{ $_[1] } ) {
        my $prev_el = $el->[$PREV];

        my $next_el = $el->[$NEXT];

        # not first element
        if ($prev_el) {

            # middle element
            if ($next_el) {
                $prev_el->[$NEXT] = $next_el;

                weaken $prev_el->[$NEXT];

                $next_el->[$PREV] = $prev_el;

                weaken $next_el->[$PREV];
            }

            # last element
            else {
                undef $prev_el->[$NEXT];

                $data->[$LAST] = $prev_el;
            }
        }

        # first element
        else {

            # not single element
            if ($next_el) {
                undef $next_el->[$PREV];

                $data->[$FIRST] = $next_el;
            }

            # single element
            else {
                undef $data->[$FIRST];

                undef $data->[$LAST];
            }
        }

        return $el->[0];
    }
    else {
        return;
    }
}

sub CLEAR {
    my $data = $_[0]->$*;

    undef $data->[$FIRST];

    undef $data->[$LAST];

    $data->[$HASH]->%* = ();

    return;
}

sub SCALAR {
    return scalar $_[0]->$*->[$HASH]->%*;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 55                   | Miscellanea::ProhibitTies - Tied variable used                                                                 |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Hash::LRU

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
