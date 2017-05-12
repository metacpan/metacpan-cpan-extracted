#!perl

use 5.010;
use strict;
use warnings;

use FindBin '$Bin';
use lib $Bin, "$Bin/t";

use File::Slurp::Tiny qw(read_file);
use Test::More 0.98;
require "testlib.pl";

test_to_vcf(
    name => '1.org',
    args => {
        source_file=>"$Bin/data/1.org",
        default_country => "ID",
    },
    status => 200,
    result => scalar read_file("$Bin/data/1.vcf"),
);

done_testing();
