#!/usr/bin/perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Slurp qw(:all);
use File::Temp;
use Test::XML;

use TAP::Harness;

use FindBin;
my $root_dir = "$FindBin::Bin/..";

$ENV{PERL5LIB} = join(':', split(/:/, $ENV{PERL5LIB}), "$root_dir/blib/lib");

my @tests = grep { -f $_ } <t/internal_tests/*.test>;
plan tests => scalar(@tests);

###############################################################################
# Run each of the tests in turn, and compare the output to the expected JUnit
# output.
foreach my $test (@tests) {

    my $f_out = File::Temp->new();
    my $f_err = File::Temp->new();
    my $test_output = File::Temp->new();

    local $ENV{TAP_FORMATTER_BAMBOO_OUTFILE}=$test_output;
    system("prove -b --formatter=TAP::Formatter::Bamboo $test >$f_out 2>$f_err");

    my $stdout = read_file($f_out);
    my $stderr = read_file($f_err);

    #print "STDOUT:\n$stdout";
    #print "STDERR:\n$stderr";

    my $result = read_file( $test_output );
    (my $expect = $test) =~ s{\.test$}{\.expect};
    my $expected = read_file($expect);

    $result =~ s/(<testcase\b.*\b)time="\d+\.\d+"/$1time="TEST_TIME"/g;

    if( ! is_xml($result, $expected, $test) ) {
        diag("---- Expected: ----\n$expected");
        (my $res = $expect) =~ s/\.expect$/.results/;
        write_file("$res", $result);
        diag("Actual results saved to file $res");
    }
}
