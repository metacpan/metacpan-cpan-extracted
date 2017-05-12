#!/usr/bin/perl
package main;

use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/lib";

our $COUNT = 0;

eval "use MooXTestTestTest;";

my $mooxtesttesttest = MooXTestTestTest->new;

is($COUNT,101,'Correct import function called on NonMooX class');
isa_ok($mooxtesttesttest,'Moo::Object');

done_testing;
