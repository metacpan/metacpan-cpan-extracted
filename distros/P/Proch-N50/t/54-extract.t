use strict;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use File::Spec::Functions;
use Proch::Seqfu;


my $file = catfile($RealBin, "..", "data", "small_test.fa"); # "$RealBin/../data/small_test.fa";
my $bins  = catfile($RealBin, "..", "bin/");
my $program = 'fu-extract';
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

sub cmdSeqs {
    my ($cmd) = @_;
    my @output = `$cmd`;
    my $sum = 0;
    if ($?) {
        return -1;
    }
    for my $line (@output) {
        chomp($line);
        $sum += 1 if ($line =~ /^>/);
    }
    return $sum;
}
SKIP: {
    my $script = catfile($bins, $program);
    skip "Unable to run perl from here" if (perl_fail());
    skip "Skipping binary tests: $script not found" unless (-e "$script");
    skip "Input file not found: $file" unless (-e "$file");
    
    # Check "seq" containing headers: none expected
    my $cmd = qq($^X $script -p seq "$script" "$file" );
    my $seqs = cmdSeqs($cmd);
    ok($seqs == 0, "[$program] got $seqs sequences, expected 0");
 
    # 5/6 sequences starts with "Seq"
    my $cmd2 = qq($^X $script -p Seq "$script" "$file" );
    my $seqs = cmdSeqs($cmd2);
    ok($seqs == 5, "[$program] got $seqs sequences, expected 5");
    
    # Case insensitive: all sequences match (6)
    my $icmd = qq($^X $script -i -p seq "$script" "$file" );
    my $iseqs = cmdSeqs($icmd);
    ok($iseqs == 6, "[$program] got $iseqs sequences, expected 6");    
}

done_testing();
