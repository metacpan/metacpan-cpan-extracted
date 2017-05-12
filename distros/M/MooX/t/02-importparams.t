#!/usr/bin/perl
package main;

use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/lib";

our $COUNT = 0;

eval "use MooXTestTest;";

my $mooxtesttest = MooXTestTest->new;

is($COUNT,60,'Correct import function called with proper parameters');
isa_ok($mooxtesttest,'Moo::Object');

done_testing;
