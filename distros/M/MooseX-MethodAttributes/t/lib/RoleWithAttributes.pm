package RoleWithAttributes;
use MooseX::MethodAttributes::Role;
use namespace::autoclean;

sub foo : AnAttr { 'foo' }

sub fnord {}

after 'fnord' => sub {}; # Just test we get the Moose::Role sugar

1;

