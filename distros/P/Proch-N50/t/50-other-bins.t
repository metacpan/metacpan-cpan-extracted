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

sub execute {
    my ($prog, @args) = @_;
    my $script = catfile($bins, $prog);
    my $cmd = "$^X \"$script\"";
    my $output;
    my $status;
    for my $arg (@args) {
        $cmd .= " \"$arg\" ";
    }
    
    $output = `$cmd`;
    $status = $?;
    return ($status, $output, $cmd);
    
}

sub testbin {
    my ($prog, @args) = @_;
    my ($status, $output, $cmd) = execute($prog, @args); 
    ok($status == 0, "[$prog] Program executed as: \n`$cmd`\n  with status 0: got $status");
}
sub tcmd {
    my $cmd = shift @_;
    eval {
        `$cmd`;
    };
    if ($@) {
        return -1;
    }
    return $?;
}
SKIP: {
    my $hashBin = catfile($bins, "fu-hash");
    skip "Skipping binary tests: $hashBin not found" unless (-e "$hashBin");
    skip "Input file not found: $file" unless (-e "$file");
    skip "Failed calling $^X externally (maybe is perl.exe?)" if (perl_fail());
    my $cmd = qq($^X "$hashBin" "$file");
    my $val = tcmd($cmd);
    skip "Unable to run tests: $cmd: $val" if ($val != 0);
    my $status;
    my $output;
	testbin("fu-grep", "ACACACA", $file); 
    
    testbin("fu-uniq", $file);
    
    testbin("fu-sort", $file);
    
    testbin("fu-rename", $file);
    
    testbin("fu-extract",  $file);
    
}
done_testing();
