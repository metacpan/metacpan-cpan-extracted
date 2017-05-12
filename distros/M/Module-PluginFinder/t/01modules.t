#!/usr/bin/perl -w

use strict;

use Test::More tests => 4;
use Test::Exception;

use Module::PluginFinder;

dies_ok( sub { Module::PluginFinder->new(); },
         '->new() without search_path fails' );

my $f = Module::PluginFinder->new(
   search_path => 't::lib',
   filter => sub {},
);

ok( defined $f, 'defined $f' );
isa_ok( $f, "Module::PluginFinder", '$f isa Module::PluginFinder' );

is_deeply( [ sort $f->modules ],
           [qw( t::lib::Black t::lib::Blue t::lib::Green t::lib::Red t::lib::Yellow )],
           '$f->modules' );
