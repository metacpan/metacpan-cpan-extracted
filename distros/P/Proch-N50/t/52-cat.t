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

sub countseqs {
    my ($cmd) = @_;
    my @output = `$cmd`;
    if (substr($output[0], 0, 1) eq ">") {
        return int(scalar(@output) / 2);
    } elsif (substr($output[0], 0, 1) eq "@")  {
        return int(scalar(@output) / 4);
    } else {
        return -1;
    }
}
SKIP: {
    my $script = catfile($bins, "fu-cat");
    skip "Unable to run perl from here" if (perl_fail());
    skip "Skipping binary tests: $script not found" unless (-e "$script");
    skip "Input file not found: $file" unless (-e "$file");
    
    my $cmd = qq($^X "$script" "$file" );
    my $seqs = countseqs($cmd);
    ok($seqs == 6, "[fu-cat] got $seqs sequences, expected 6");

    $cmd = qq($^X "$script" -l 50 "$file" );
    $seqs = countseqs($cmd);
    ok($seqs == 1, "[fu-cat] got $seqs sequences > 50, expected 1");

    $cmd = qq($^X "$script" -l 50 "$file" );
    $seqs = countseqs($cmd);
    ok($seqs == 1, "[fu-cat] got $seqs sequences > 50, expected 1");


    
}

done_testing();
