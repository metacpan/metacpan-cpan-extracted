use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use File::Spec;

# Skip all tests on Windows
BEGIN {
    if ($^O eq 'MSWin32') {
        plan skip_all => "Binary tests not supported on Windows";
        exit 0; # Ensure early exit
    }
}

# Ensure we handle taint mode properly
my $PERL_INTERPRETER = $^X;
if ($^T) {  # Check if running in taint mode
    $ENV{PATH} = '/usr/local/bin:/usr/bin:/bin';
    ($PERL_INTERPRETER) = $PERL_INTERPRETER =~ m/^(.*)$/;
}

# Remove duplicate 'whojobs' from the list
my @BINARIES_NAMES = qw(lsjobs whojobs session waitjobs);

# Optional: Add version checking if there's a common module with version
my $expected_version = eval { require NBI::Slurm; $NBI::Slurm::VERSION } || '0';

subtest 'Binary version tests' => sub {
    plan tests => scalar(@BINARIES_NAMES) * 1;
    
    for my $prog (@BINARIES_NAMES) {
        subtest "$prog version check" => sub {
            # Construct the full path to the binary
            my $bin_path = File::Spec->catfile($RealBin, '..', 'bin', $prog);
            
            # Ensure the binary exists
            ok(-e $bin_path, "$prog exists");
            
            # Untaint the path if in taint mode
            if ($^T) {
                ($bin_path) = $bin_path =~ m/^(.*)$/;
            }
            
            # Run the version command using core Perl
            my $cmd = "$PERL_INTERPRETER $bin_path --version 2>&1";
            my $output = `$cmd`;
            my $exit_code = $? >> 8;
            
            # Check exit code
            is($exit_code, 0, "bin [$prog]: exit code is 0");
            
            # Check that output contains the program name
            like($output, qr/$prog/, "[$prog]: output contains program name ($prog)");
            
            # Optional: Check that output contains expected version
            if ($expected_version ne '0') {
                like($output, qr/$expected_version/, 
                     "$prog: output contains expected version $expected_version");
            }
            
            # Display the actual version output for debugging
            diag("$prog version output: $output") if $ENV{TEST_VERBOSE};
        };
    }
};

done_testing();