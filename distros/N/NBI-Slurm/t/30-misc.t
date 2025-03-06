use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use File::Spec;
use_ok 'NBI::Slurm';

my @bins = ('printslurm', 'printpath');

# Set a safe PATH when running in taint mode
if ($^T) {  # $^T is non-zero when taint mode is on
    $ENV{PATH} = '/usr/local/bin:/usr/bin:/bin';
}

for my $bin (@bins) {
    my $path = File::Spec->catfile($RealBin, '..', 'bin', $bin);
    $path = File::Spec->rel2abs($path);  # Get absolute path
    
    ok(-e $path, "$bin exists");
    
    # Use a full path to perl interpreter
    my $perl_interpreter = $^X;
    
    # When in taint mode (-t), ensure paths are untainted
    if ($^T) {
        # Untaint the perl path
        ($perl_interpreter) = $perl_interpreter =~ m/^(.*)$/;
        
        # Untaint the script path
        ($path) = $path =~ m/^(.*)$/;
    }
    
    my @cmd = ($perl_interpreter, $path, '--help');
    my $exit_code = system(@cmd);
    is($exit_code, 0, "$bin runs successfully");
}

done_testing();