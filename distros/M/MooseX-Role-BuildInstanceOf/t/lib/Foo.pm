package Foo; 

use Moose;

has thingy => ( is => 'ro', );
has this => ( is => 'ro', );

with 'MooseX::Role::BuildInstanceOf' => {
    target => 'Foo::Bar',
    inherited_args => [ qw/ thingy /, { that => 'this', parent => sub { shift } } ],
};

1;

