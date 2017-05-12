#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Test::BrewBuild::Dispatch;

my $d = Test::BrewBuild::Dispatch->new(forks => 8);

is ($d->{forks}, 8, "forks param works");

done_testing();

