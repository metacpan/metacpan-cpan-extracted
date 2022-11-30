#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Promise::XS;

my $d1 = Promise::XS::deferred();
my $clone1 = ref($d1->promise())->can('AWAIT_CLONE')->();
my $refcnt = Internals::SvREFCNT($clone1);
is( $refcnt, 1, 'AWAIT_CLONE() function return refcount' );
$d1->resolve();

my $d2 = Promise::XS::deferred();
my $clone2 = $d2->promise()->AWAIT_CLONE();
$refcnt = Internals::SvREFCNT($clone2);
is( $refcnt, 1, 'AWAIT_CLONE() method return refcount' );
$d2->resolve();

done_testing;
