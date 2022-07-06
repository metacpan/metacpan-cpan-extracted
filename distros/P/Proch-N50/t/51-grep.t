use strict;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use File::Spec::Functions;
use Proch::Seqfu;


my $file = catfile($RealBin, "..", "data", "small_test.fa"); # "$RealBin/../data/small_test.fa";
my $bins  = catfile($RealBin, "..", "bin/");

sub perl_fail {
    # Return non zero if perl does not work
    my $cmd = "$^X --version";
    my @lines = ();
    my $status;
    eval {
      @lines = `$cmd`;
      $status = $?;
    };
    
    if ($@) {
        return -2;
    } elsif ($status != 0) {
        return $status
    } else {
        # OK
        return 0
    }
}

SKIP: {
    my $script = catfile($bins, "fu-grep");
    skip "Unable to run perl from here" if (perl_fail());
    skip "Skipping binary tests: $script not found" unless (-e "$script");
    skip "Input file not found: $file" unless (-e "$file");
    
    # 
    my %patterns = (
        'acagcgtacgtgatcgacgt' => 1,
        'acac' => 2,
        'gattaca' => 0,
    );
    for my $p (sort keys %patterns) {
        my $cmd = qq($^X "$script" "$p" "$file" );
        my @output = `$cmd`;
        my $lines = scalar @output;
        ok($? == 0, "[fu-grep: $p] Exit status OK for grep: $?");
        ok($lines == 2 * $patterns{$p}, "[fu-grep: $p] output sequences expected: 2*$patterns{$p}=$lines");
    }
    for my $p (sort keys %patterns) {
        my $r = Proch::Seqfu::rc($p);
        my $cmd = qq($^X "$script" "$r" "$file" );
        my @output = `$cmd`;
        my $lines = scalar @output;
        ok($? == 0, "[fu-grep: ^$p] Exit status OK for grep: $?");
        ok($lines == 2 * $patterns{$p}, "[fu-grep: $r] reverse matches: 2*$patterns{$p} = $lines");
    }
    for my $p (sort keys %patterns) {
        my $r = Proch::Seqfu::rc($p);
        my $cmd = qq($^X "$script" --stranded "$r" "$file" );
        my @output = `$cmd`;
        my $lines = scalar @output;
        ok($? == 0, "[fu-grep: ^$p] Exit status OK for grep: $?");
        ok($lines <= 2 * $patterns{$p}, "[fu-grep: $r] stranded search: 2*$patterns{$p} >= $lines");
    }     
    my $cmd = qq($^X "$script" -n "Seq1" "$file" );
    my @output = `$cmd`;
    my $lines = scalar @output;
    ok($? == 0, "[fu-grep: -n] Exit status OK for grep: $?");
    ok($lines == 2*1, "[fu-grep: -n] output sequences expected: 1=$lines");
}

done_testing();
