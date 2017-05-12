package Quux::MyPlugins::Roles::Bar::A;

# ABSTRACT: Quux::A with Bar plugin role

use Moo::Role;
use namespace::clean;

has bar_a => ( is => 'ro' );

1;
