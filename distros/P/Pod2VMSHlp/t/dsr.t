#!perl 

# This version of the regression test ought to be able to run from
# systems that do not have Test.pm or the Test::Harness module.
# Test.pm in conjunction with Test::Harness hides test failures
# on VMS for perl 5.005_03 and 5.6.0 (5.6.1 and 5.7.1 might be
# fixed though).

# Try to be as strict as possible.
use strict;

# In order to run scripts as tests we need perl executable
# The extracted pod2rno.PL script will have a platform 
# dependent name.
my $perl_exe = "$^X";
my $extra_args = "\"-w\" \"-Mstrict\"";
my $pod2rno_exe = 'pod2rno';
# Try to be as strict as possible.
if ($^O eq 'VMS') {
    $perl_exe = "MCR $perl_exe";
    $pod2rno_exe .= '.com';
    # -x to get past $Config{startperl}
    $extra_args .= " -x";
}

#my @test_files = qw(testpod0);
#my @test_files = qw(testpod0 platin1 finibusi pod2hlb pod2hlp pod2rno.PL);
my @test_files = qw(testpod0 platin1 finibusi pod2hlb pod2hlp);
my $test_total = 1 + 2 * scalar(@test_files);

print "1..$test_total\n";
my $test = 1;

use Pod::Dsr;

print +(defined($Pod::Dsr::PREAMBLE ) ? '' : 'not '), "ok $test\n";

my $source_pod = '';
my $reference_file = '';
my $output_file = '';

foreach my $testfile (@test_files) {

# Tests take pod input from $source_pod, direct output to s/\.pod$/.rno/
# file then we compare the contents of the .rno file to a .dsr reference.
    if ($testfile !~ /^pod2/) {
        $source_pod = file_spec('t', "$testfile" . '.pod');
        $output_file = file_spec('t', "$testfile" . '.rno');
    }
    else {
        $source_pod = $testfile;
        $output_file = $testfile . '.rno';
    }
    $reference_file = file_spec('t', "$testfile" . '.dsr');

    # Make sure that any output file is cleaned up before we test.
    cleanup($output_file);

    # Not sure about the backtick on MacOS
    # _maybe_ this will work with toolserver(???)
    my @swallow_run =
     `$perl_exe $extra_args $pod2rno_exe $source_pod >$output_file`;
    $test++;
    print +($@ eq '') ? '' : 'not ', "ok $test\n";
    open(REF,"<$reference_file");
    my @ref=<REF>;
    close(REF);
    # Time and date stamps must be removed before a fair comparison can be made
    # There is a date stamp on the second line and the 19th line.
    my $ref = join('',@ref[0,2..17,19..$#ref]);
    open(RNO,"<$output_file");
    my @rno=<RNO>;
    close(RNO);
    my $rno = join('',@rno[0,2..17,19..$#ref]);
    $test++;
    if ($ref ne $rno) {
        print "not ok $test # $output_file ne $reference_file\n";
    }
    else {
        print "ok $test\n";
    }

    # final cleanup
    cleanup($output_file);

} # foreach loop

sub file_spec {
    # Poor implementation of File::Spec so we do not have to load 
    # that module, which may not be present on older perl installations.
    my $file_spec = '';
    if ($^O eq 'MacOS') {
        $file_spec = ':' . join(':',@_);
    }
    else {
        $file_spec = join('/',@_);
    }
    return $file_spec;
}

sub cleanup {
    my $file_spec = shift;

    if (-e $file_spec) {
        1 while unlink($file_spec); #Possibly pointless VMSism
    }
}

