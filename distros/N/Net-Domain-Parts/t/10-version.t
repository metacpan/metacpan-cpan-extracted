#!perl
use 5.006;
use strict;
use warnings;
use Data::Dumper;
use Test::More;

use Net::Domain::Parts qw(:all);

my $current_version = '2025-01-21_09-07-06_UTC';
is
    Net::Domain::Parts::version(),
    $current_version,
    "Project's __DATA__ version() is $current_version ok";

done_testing();