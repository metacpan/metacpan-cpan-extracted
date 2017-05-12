#!/usr/bin/env perl
use strictures 2;

use Test::More;
use Test::Fatal;

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
    exception { $state->save() },
    qr{^foo at t/croak\.t line \d+},
    'croak reported proper caller',
);

done_testing;
