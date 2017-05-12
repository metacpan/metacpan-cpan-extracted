package Net::ACME::X::HashBase;

use strict;
use warnings;

use parent qw( Net::ACME::X::OverloadBase );

sub new {
    my ( $class, $string, $props_hr ) = @_;

    $class->_check_overload();

    my %attrs = $props_hr ? %$props_hr : ();

    return bless [ $string, \%attrs ], $class;
}

sub get {
    my ( $self, $attr ) = @_;

    #Do we need to clone this? Could JSON suffice, or do we need Clone?
    return $self->[1]{$attr};
}

sub to_string {
    my ($self) = @_;

    return $self->[0];
}

1;
