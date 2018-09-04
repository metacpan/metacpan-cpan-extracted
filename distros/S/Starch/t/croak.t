#!/usr/bin/env perl
use strictures 2;

use Test2::V0;

use Starch;
use Starch::Store::Memory;

{
    package Starch::Store::CroakMemory;
    use Moo;
    extends 'Starch::Store::Memory';
    use Starch::Util qw( croak );
    sub set { croak 'foo' }
}

my $starch = Starch->new( store=>{class=>'::CroakMemory'} );
my $state = $starch->state();
$state->mark_dirty();

like(
    dies { $state->save() },
    qr{^foo at \S*croak\.t line \d+},
    'croak reported proper caller',
);

done_testing;
