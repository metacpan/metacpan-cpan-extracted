#!/usr/bin/perl -w

use strict;

use Test::More tests => 7;
use Test::Exception;

use Module::PluginFinder;

dies_ok( sub { Module::PluginFinder->new(
                  search_path => 't::lib',
                  filter => "hello",
               ); },
         '->new() without filter CODE ref fails' );

my $f = Module::PluginFinder->new(
   search_path => 't::lib',
   filter => sub {
      my ( $module, $searchkey ) = @_;
      return $module =~ m/::Red$/;
   },
);

is( $f->find_module(), 't::lib::Red', '$f->find_module()' );

$f = Module::PluginFinder->new(
   search_path => 't::lib',
   filter => sub {
      my ( $module, $searchkey ) = @_;
      return $module =~ $searchkey;
   },
);

is( $f->find_module( qr/::Blue$/ ), 't::lib::Blue', '$f->find_module( qr/::Blue$/ )' );

is( $f->find_module( qr/::Missing$/ ), undef, '$f->find_module( qr/::Missing$/ )' );

my $colour = $f->construct( qr/::Red$/, 10 );

ok( defined $colour, 'defined $colour' );
isa_ok( $colour, "t::lib::Red", '$colour isa t::lib::Red' );

is_deeply( $colour, [ 10 ], 'forwarded constructor args for $colour' );
