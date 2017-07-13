#!perl

use 5.010;
use strict;
use warnings;

use FindBin '$Bin';
use lib $Bin, "$Bin/t";

use File::Slurper qw(read_text);
use Test::More 0.98;
require "testlib.pl";

test_to_vcf(
    name => '1.org',
    args => {
        source_file=>"$Bin/data/1.org",
        default_country => "ID",
    },
    status => 200,
    result => read_text("$Bin/data/1.vcf"),
);

done_testing();
