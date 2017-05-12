#!/usr/bin/perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Slurp qw(:all);
use Cwd ();
use Test::XML;
use TAP::Harness;

my @test_files = grep { -f $_ } <t/internal_tests/*.test>;
plan tests => ((scalar(@test_files) * 3) - 2);

# Run each of the tests in turn, and compare the output to the expected output.
foreach my $test_file (@test_files) {
    # keeping this intact was not working with with calling prove
    local $ENV{'HARNESS_PERL_SWITCHES'} = undef;
    system("prove -l --formatter=TAP::Formatter::BambooExtended ${test_file} 1> /dev/null 2> /dev/null");

    my $test_name = $test_file;
    $test_name =~ s/\/|\\/-/g;
    $test_name =~ s/\./_/g;

    my $output_path = Cwd::cwd() . "/prove_db";
    $output_path = $ENV{'FORMATTER_OUTPUT_DIR'} if defined($ENV{'FORMATTER_OUTPUT_DIR'});
    my $output_file = "${output_path}/${test_name}.xml";

    # if this is a bailout example then we don't expect anything
    if ($test_name =~ /bailout/) {
        ok(!(-e $output_file));
    } else {
        my $result = read_file($output_file);
        (my $expect = $test_file) =~ s{\.test$}{\.expect};
        my $expected = read_file($expect);

        # replace the timing because hey it's random
        $result =~ s/(<testsuite\b.*\b)time="\d+\.\d+"/$1time="TEST_TIME"/g;

        is_good_xml($expected, "is expected good xml: ${test_name}");
        is_good_xml($result, "is result good xml: ${test_name}");

        unless (is_xml($result, $expected, $test_name) ) {
            diag("---- Expected: ----\n$expected");
            (my $res = $expect) =~ s/\.expect$/.results/;
            write_file("$res", $result);
            diag("Actual results saved to file $res");
        }
    }
}

