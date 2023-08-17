
#!/usr/bin/env perl
use v5.12;
use Data::Dumper;
# add to library ../lib/
use FindBin qw($RealBin);

use lib "$RealBin/../lib";
use NBI::Slurm;

my $user_current_dir = `pwd`;
chomp $user_current_dir;
my $opt = NBI::Opts->new(
    -queue => "nbi-short",
    -threads => 1,
    -memory => "12Gb",
    -time   => "0d 1h",
    -tmpdir => "/tmp"
);

my $job = NBI::Job->new(
    -name => "my-job",
    -command => "cd $user_current_dir",
    -opts => $opt
);
$job->append_command("ls -l > temporary-example-list.txt");

say "-------- JOB DUMP --------";
say Dumper $job;    
say "-------- JOB SCRIPT --------";
say $job->script();
say "-------- /JOB  --------";
if (my $j = $job->run()) {
    say "Job submitted: $j";
} else {
    say "Job not submitted: $j";
}