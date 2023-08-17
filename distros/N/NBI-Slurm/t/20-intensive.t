use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;

# This test checks the loadability of the module
# and that the object is correctly blessed as FASTX::Reader

use_ok 'NBI::Slurm';

my $TOTAL = 100;
my $queue = "slurm-queue";
my $threads = 1;
my $memory = 2;
my $time = "3d 4h 5m 6s";
my $tmpdir = "/7TB";
my $email_address = "test\@test.com";
my $mail_type = "ALL";
my $afterok_string = "afterok:1234";
my $name = "TEST";

my $opt_last;
my $job_last;

for (my $i = 0; $i <= $TOTAL; $i++) {
    my $opts = NBI::Opts->new(
        -queue => $queue,
        -threads => $threads,
        -memory => $memory,
        -time   => $time,
        -tmpdir => $tmpdir,
        -email_address => $email_address,
        -email_type => $mail_type,
        -opts => [$afterok_string],
    );


    

    my $job = NBI::Job->new(
        -name => $name,
        -command =>  "cd \$HOME",
        -opts => $opts
    );

    if (defined $opt_last and $opt_last->view() ne $opts->view() or $i == $TOTAL) {
        is($opt_last->view(), $opts->view(), "Opts->view() is self-consistent ($i/$TOTAL times)");
    }
    if (defined $job_last and $job_last->script() ne $job->script() or $i == $TOTAL) {
        is($job_last->script(), $job->script(), "Job->script() is self-consistent ($i/$TOTAL times)");
    }
    $opt_last = $opts;
    $job_last = $job;
}
done_testing();