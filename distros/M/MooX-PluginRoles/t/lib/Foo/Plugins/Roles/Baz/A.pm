package Foo::Plugins::Roles::Baz::A;

# ABSTRACT: Foo::A with Baz plugin role

use Moo::Role;
use namespace::clean;

has baz_a => ( is => 'ro' );

1;
