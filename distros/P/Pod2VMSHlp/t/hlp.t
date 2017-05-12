#!perl 

# This version of the regression test ought to be able to run from
# systems that do not have Test.pm or the Test::Harness module.
# Test.pm in conjunction with Test::Harness hides test failures
# on VMS for perl 5.005_03 and 5.6.0 (5.6.1 and 5.7.1 might be
# fixed though).

# Try to be as strict as possible.
use strict;
# In order to run scripts as tests we need perl executable
my $perl_exe = $^X;
if ($] <= 5.005_03 && $^O eq 'VMS') { $perl_exe = "MCR $perl_exe"; }

#my @test_files = qw(testpod0);
#my @test_files = qw(testpod0 platin1 finibusi pod2hlb pod2hlp pod2rno.PL);
my @test_files = qw(testpod0 platin1 finibusi pod2hlb pod2hlp);
my $test_total = 1 + 2*scalar(@test_files);

print "1..$test_total\n";
my $test = 1;

use Pod::Hlp;

print +(defined(&Pod::Hlp::pod2hlp) ? '' : 'not '), "ok $test\n";

my $source_pod = '';
my $reference_file = '';
my $output_file = '';

foreach my $testfile (@test_files) {

# Tests take pod input from $source_pod, produce output in a s/\.pod$/.hlp/
# file then we compare the contents of the .hlp file to a reference.
    if ($testfile !~ /^pod2/) { 
        $source_pod = file_spec('t', "$testfile" . '.pod');
        $output_file = file_spec('t', "$testfile" . '.hlp');
    }
    else {
        $source_pod = $testfile;
        $output_file = $testfile . '.hlp';
    }
    $reference_file = file_spec('t', "$testfile" . '.ref');

    # Make sure that any output file is cleaned up before we test.
    cleanup($output_file);
    # Try to be as strict as possible.
    my $code = system($perl_exe,"-w","-Mstrict","-Mblib","pod2hlp",$source_pod);
    my $rc = eval $code;
    $test++;
    print +($rc == 0) ? '' : 'not ', "ok $test\n";
    open(REF,"<$reference_file");
    my @ref=<REF>;
    close(REF);
    my $ref = join('',@ref);
    open(HLP,"<$output_file");
    my @hlp=<HLP>;
    close(HLP);
    my $hlp = join('',@hlp);
    $test++;
    if ($ref ne $hlp) {
        print "not ok $test # $output_file ne $reference_file \n";
    }
    else {
        print "ok $test\n";
    }

    # final cleanup
    cleanup($output_file);

} # foreach loop

sub file_spec {
    # poor File::Spec so we do not have to load that module
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

