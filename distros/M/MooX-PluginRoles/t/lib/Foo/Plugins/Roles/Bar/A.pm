package Foo::Plugins::Roles::Bar::A;

# ABSTRACT: Foo::A with Bar plugin role

use Moo::Role;
use namespace::clean;

has bar_a => ( is => 'ro' );

1;
