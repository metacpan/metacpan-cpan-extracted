#!/usr/bin/perl

use warnings;
use strict;

use Test::More no_plan =>;#<

use Postal::US::State;

my $x = 'Postal::US::State';

is($x->code('texas'), 'TX');
is($x->code('teXas'), 'TX');
is($x->code('TEXAS'), 'TX');
is($x->code('Texas'), 'TX');

is($x->state('TX'), 'Texas');
is($x->state('DC'), 'District of Columbia');

# vim:ts=2:sw=2:et:sta
