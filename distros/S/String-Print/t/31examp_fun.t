#!/usr/bin/env perl
# Demonstrate the functional examples

use warnings;
use strict;

use Test::More tests => 4;

use String::Print 'sprinti', 'sprintp'
  , modifiers   => [ EUR   => sub { sprintf "%5.2f e", $_[2] } ]
  , serializers => [ UNDEF => sub {'-'} ];

is(sprinti("price: {p EUR}#", p => 3.1415), 'price:  3.14 e#');

is(sprinti("count: {c}#", c => undef), 'count: -#');

my @dumpfiles = qw/f1 f2/;
is(sprintp("dumpfiles: %s\n", \@dumpfiles, _join => ', ')
  , "dumpfiles: f1, f2\n");

is(sprinti("dumpfiles: {filenames}\n",filenames => \@dumpfiles, _join => ', ')
  , "dumpfiles: f1, f2\n");

