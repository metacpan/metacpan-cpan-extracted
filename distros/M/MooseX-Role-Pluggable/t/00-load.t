#! perl

use strict;
use warnings;

{
  package Foo;
  use Moose;
  with 'MooseX::Role::Pluggable';
}

package main;
use Test::More;

diag( "Testing MooseX::Role::Pluggable $MooseX::Role::Pluggable::VERSION, Perl $], $^X" );

my $foo = Foo->new();
ok( $foo->does( 'MooseX::Role::Pluggable' ) , 'role was consumed' );

ok( $foo->can( 'plugin_list' ), 'can look at plugin list' );
is( $foo->plugin_list , undef , 'plugin list is undef with no plugins loaded' );

ok( $foo->can( 'plugin_hash' ), 'can look at plugin hash' );
is( $foo->plugin_hash , undef , 'plugin hash is undef with no plugins loaded' );

done_testing();
