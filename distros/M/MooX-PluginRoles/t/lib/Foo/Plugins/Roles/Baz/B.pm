package Foo::Plugins::Roles::Baz::B;

# ABSTRACT: Foo::B with Baz plugin role

use Moo::Role;
use namespace::clean;

has baz_b => ( is => 'ro' );

1;
