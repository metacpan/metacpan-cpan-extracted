
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use strict;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use File::Spec::Functions;
use Proch::Seqfu;
use lib $RealBin;
use TestFu;

my $file = catfile($RealBin, "..", "data", "small_test.fa"); # "$RealBin/../data/small_test.fa";
my $bins  = catfile($RealBin, "..", "bin/");
sub test_bin {
    my ($prog, @args) = @_;
    my ($status, $out, $err) = run_bin($prog, @args);
    ok($status == 0, "[$prog] ran successfully with @args");
}

SKIP: {
    
    skip "Unable to run perl from here" if (not has_perl());
    skip "Input file not found: $file" unless (-e "$file");
    
    # 
    my %patterns = (
        'acagcgtacgtgatcgacgt' => 1,
        'acac' => 2,
        'gattaca' => 0,
    );
    for my $p (sort keys %patterns) {
        my ($status, $out, $err) = run_bin("fu-grep", ("$p", "$file"));
        my $lines = scalar ( split "\n", $out);
        ok($status == 0,  "[fu-grep: $p] Exit status OK for grep: $?");
        ok($lines  == 2 * $patterns{$p}, "[fu-grep: $p] output sequences expected: 2*$patterns{$p}=$lines");
    }
    for my $p (sort keys %patterns) {
        my $r = Proch::Seqfu::rc($p);
        my ($status, $out, $err) = run_bin("fu-grep", ("$p", "$file"));
        my $lines = scalar ( split "\n", $out);
        ok($status == 0, "[fu-grep: ^$p] Exit status OK for grep: $?");
        ok($lines == 2 * $patterns{$p}, "[fu-grep: $r] reverse matches: 2*$patterns{$p} = $lines");
    }
    for my $p (sort keys %patterns) {
        my $r = Proch::Seqfu::rc($p);
        my ($status, $out, $err) = run_bin("fu-grep", ("$p", "$file"));
        my $lines = scalar ( split "\n", $out);
        ok($status == 0, "[fu-grep: ^$p] Exit status OK for grep: $?");
        ok($lines <= 2 * $patterns{$p}, "[fu-grep: $r] stranded search: 2*$patterns{$p} >= $lines");
    }     
    my ($status, $out, $err) = run_bin("fu-grep", ("Seq1", "-n", "$file"));
    my $lines = scalar ( split "\n", $out);
    ok($? == 0, "[fu-grep: -n] Exit status OK for grep: $?");
    ok($lines == 2*1, "[fu-grep: -n] output sequences expected: 1=$lines");
}

done_testing();
