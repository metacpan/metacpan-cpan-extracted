#!/usr/bin/perl
package main;

use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/lib";

our $COUNT = 0;

eval "use MooXTest;";

my $mooxtest = MooXTest->new;

is($COUNT,7,'Correct import functions called');
isa_ok($mooxtest,'Moo::Object');

done_testing;
