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

sub tot {
    my ($cmd) = @_;
    my @output = `$cmd`;
    my $sum = 0;
    for my $line (@output) {
        chomp($line);
        my ($id, $n) = split(/\t/, $line);
        $sum += $n;
    }
    return $sum;
}
SKIP: {
    my $script = catfile($bins, "fu-count");
    skip "Unable to run perl from here" if (perl_fail());
    skip "Skipping binary tests: $script not found" unless (-e "$script");
    skip "Input file not found: $file" unless (-e "$file");
    
    my $cmd = qq($^X "$script" "$file" );
    my $seqs = tot($cmd);
    ok($seqs == 6, "[fu-count] got $seqs sequences, expected 6");
 
    
}

done_testing();
