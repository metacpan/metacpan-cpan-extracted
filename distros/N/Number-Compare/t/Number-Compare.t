#!perl -w
# $Id$
use strict;
use Test::More tests => 24;

BEGIN { use_ok("Number::Compare") };

my $c = Number::Compare->new('>20');
ok(  $c->test(21), ">20" );
ok( !$c->test(20) );
ok( !$c->test(19) );

$c = Number::Compare->new('<20');
ok( !$c->test(21), "<20" );
ok( !$c->test(20) );
ok(  $c->test(19) );

$c = Number::Compare->new('>=20');
ok(  $c->test(21), ">=20" );
ok(  $c->test(20) );
ok( !$c->test(19) );

$c = Number::Compare->new('<=20');
ok( !$c->test(21), "<=20" );
ok(  $c->test(20) );
ok(  $c->test(19) );

$c = Number::Compare->new('20');
ok( !$c->test(21), "== 20" );
ok(  $c->test(20) );
ok( !$c->test(19) );

# well that's all the comparisons done, we'll not repeat that for each
# of the magnitudes though

ok( Number::Compare->new("2K")->test(        2_000), "K" );
ok( Number::Compare->new("2M")->test(    2_000_000), "M" );
ok( Number::Compare->new("2G")->test(2_000_000_000), "G" );

ok( Number::Compare->new("2Ki")->test(        2_048), "Ki" );
ok( Number::Compare->new("2Mi")->test(    2_097_152), "Mi" );
ok( Number::Compare->new("2Gi")->test(2_147_483_648), "Gi" );

# okay, how about if we become a blessed coderef

ok( Number::Compare->new("1Ki")->(1024), "directly call the coderef" );

# expose parse_to_perl

is( Number::Compare->parse_to_perl(">1Ki"), '> 1024', "->parse_to_perl" );
