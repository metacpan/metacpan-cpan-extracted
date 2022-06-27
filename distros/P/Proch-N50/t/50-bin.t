use strict;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use File::Spec::Functions;


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
    my $n50bin = catfile($bins, "n50");

    skip "Skipping binary tests: $n50bin not found" unless (-e "$n50bin");
    skip "Input file not found: $file" unless (-e "$file");
    
    # check if perl can run
    skip "Unable to run perl from here" if (perl_fail());
    my $cmd = qq($^X "$n50bin" "$file");
    my $output = `$cmd`;
    chomp($output);
    ok($? == 0, "Exit status OK for n50: $?");
    ok($output == 65, "N50 calculated for $file as 65: $output");
}

done_testing();
