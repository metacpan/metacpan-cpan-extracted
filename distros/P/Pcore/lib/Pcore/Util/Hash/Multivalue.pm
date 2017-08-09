package Pcore::Util::Hash::Multivalue;

use Pcore;
use Pcore::Util::Scalar qw[is_arrayref is_hashref is_plain_arrayref];
use Pcore::Util::List qw[pairkeys];
use Storable qw[dclone];
use Tie::Hash;
use base qw[Tie::StdHash];

sub new {
    my $self = shift;

    my $hash = {};

    my $obj = bless $hash, $self;

    tie $hash->%*, $self;

    $obj->add(@_) if @_;

    return $obj;
}

sub STORE {
    $_[0]->{ $_[1] } = is_plain_arrayref $_[2] ? $_[2] : [ $_[2] ];

    return;
}

sub FETCH {
    return $_[0]->{ $_[1] }->[-1] if exists $_[0]->{ $_[1] };

    return;
}

sub clone ($self) {
    return Storable::dclone($self);
}

# return untied $hash->{$key} as ArrayRef
sub get ( $self, $key ) {
    if ( exists $self->{$key} ) {
        return tied( $self->%* )->{$key};
    }
    else {
        return;
    }
}

# return untied HashRef
sub get_hash ($self) {
    return tied $self->%*;
}

sub add {
    my $self = shift;

    my $args = is_arrayref $_[0] ? $_[0] : is_hashref $_[0] ? [ $_[0]->%* ] : [@_];

    my $hash = tied $self->%*;

    for ( my $i = 0; $i <= $args->$#*; $i += 2 ) {
        if ( !exists $hash->{ $args->[$i] } ) {
            $hash->{ $args->[$i] } = is_plain_arrayref $args->[ $i + 1 ] ? $args->[ $i + 1 ] : [ $args->[ $i + 1 ] ];
        }
        else {
            push $hash->{ $args->[$i] }->@*, is_plain_arrayref $args->[ $i + 1 ] ? $args->[ $i + 1 ]->@* : $args->[ $i + 1 ];
        }
    }

    return $self;
}

sub set {    ## no critic qw[NamingConventions::ProhibitAmbiguousNames]
    my $self = shift;

    return $self->clear->add(@_);
}

sub replace {
    my $self = shift;

    my $args = is_arrayref $_[0] ? $_[0] : is_hashref $_[0] ? [ $_[0]->%* ] : [@_];

    my $hash = tied $self->%*;

    delete $hash->@{ pairkeys $args->@* };

    return $self->add($args);
}

sub remove {
    my $self = shift;

    delete $self->get_hash->@{@_};

    return $self;
}

sub clear ($self) {
    $self->get_hash->%* = ();

    return $self;
}

sub to_uri ($self) {
    return P->data->to_uri( $self->get_hash );
}

sub to_array ($self) {
    my $array = [];

    my $hash = $self->get_hash;

    for my $key ( sort keys $hash->%* ) {
        for my $val ( $hash->{$key}->@* ) {
            push $array->@*, $key => $val;
        }
    }

    return $array;
}

sub TO_DUMP ( $self, $dumper, %args ) {
    return dump { $self->get_hash->%* };
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 17                   | Miscellanea::ProhibitTies - Tied variable used                                                                 |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 62                   | ControlStructures::ProhibitCStyleForLoops - C-style "for" loop used                                            |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Hash::Multivalue

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
