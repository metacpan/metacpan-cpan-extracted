#!/usr/bin/perl -w
use strict;
use Test::More;
use Test::Deep;
use Test::NoWarnings;
use Module::ExtractUse;

my @tests=
  (
    ['use utf8;','utf8'],
    ['use Foo::Bar123;','Foo::Bar123'],
    ['use Foo::Bar3;','Foo::Bar3'],
    ['use Bar3;','Bar3'],
    ['use bar3;','bar3'],
);


plan tests => (scalar @tests)+1;

foreach my $t (@tests) {
    my ($code,$expected)=@$t;
    my $p=Module::ExtractUse->new;
    my $used=$p->extract_use(\$code)->string;

    is($used,$expected,"is $expected");
}

