package Net::ACME2::X::Generic;

use strict;
use warnings;

use parent qw( X::Tiny::Base );

sub new {
    my ( $class, $string, $props_hr ) = @_;

    my @attrs_kv = $props_hr ? %$props_hr : ();

    return $class->SUPER::new($string, @attrs_kv);
}

1;
