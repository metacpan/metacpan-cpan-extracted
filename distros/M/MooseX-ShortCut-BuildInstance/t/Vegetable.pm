package Vegetable;
use Moose;
use MooseX::StrictConstructor;

has 'type_of_mineral' =>( is => 'ro' );

no Moose;
__PACKAGE__->meta->make_immutable;

1;