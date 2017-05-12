#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Test::Fatal;

use B;
use Package::Stash;
use Scalar::Util qw(reftype);
use Symbol;

my $Bar = Package::Stash->new('Bar');

my $pviv = 3;
$pviv =~ s/3/4/;
isa_ok(B::svref_2object(\$pviv), 'B::PVIV');
is(exception { $Bar->add_symbol('$pviv', \$pviv) }, undef,
   "can add PVIV values");

my $pvnv = 4.5;
$pvnv =~ s/4/5/;
isa_ok(B::svref_2object(\$pvnv), 'B::PVNV');
is(exception { $Bar->add_symbol('$pvnv', \$pvnv) }, undef,
   "can add PVNV values");

my $pvmg = "foo";
bless \$pvmg, 'Foo';
isa_ok(B::svref_2object(\$pvmg), 'B::PVMG');
is(exception { $Bar->add_symbol('$pvmg', \$pvmg) }, undef,
   "can add PVMG values");

my $regexp = qr/foo/;
isa_ok(B::svref_2object($regexp), ($] < 5.012 ? 'B::PVMG' : 'B::REGEXP'));
is(exception { $Bar->add_symbol('$regexp', $regexp) }, undef,
   "can add REGEXP values");

my $pvgv = Symbol::gensym;
isa_ok(B::svref_2object($pvgv), 'B::GV');
isnt(exception { $Bar->add_symbol('$pvgv', $pvgv) }, undef,
     "can't add PVGV values");

my $pvlv = "foo";
isa_ok(B::svref_2object(\substr($pvlv, 0, 1)), 'B::PVLV');
is(exception { $Bar->add_symbol('$pvlv', \substr($pvlv, 0, 1)) }, undef,
   "can add PVLV values");

my $vstring = v1.2.3;
is(reftype(\$vstring), ($] < 5.010 ? 'SCALAR' : 'VSTRING'));
is(exception { $Bar->add_symbol('$vstring', \$vstring) }, undef,
   "can add vstring values");

done_testing;
