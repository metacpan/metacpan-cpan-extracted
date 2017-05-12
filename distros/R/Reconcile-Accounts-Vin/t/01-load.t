#!/usr/bin/perl

use v5.14;
use Test::More;

my $mod_name = "Reconcile::Accounts::Vin";

#test for module load and class creation

eval 'use Test::More';
plan(skip_all => 'Test::More required') if $@;

plan tests => 2;

use_ok($mod_name);

my $obj = $mod_name->new();
isa_ok( $obj, $mod_name,  );  
