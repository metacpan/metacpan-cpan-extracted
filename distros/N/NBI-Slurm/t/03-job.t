use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use Data::Dumper;
use_ok 'NBI::Job';
use_ok 'NBI::Opts';

# Test OK
my $job = NBI::Job->new(-name => "my-job");
print Dumper($job);
ok($job->name eq "my-job", "Job name is my-job: " . $job->name);

$job = NBI::Job->new(-name => "my-command", -command => "pwd");

ok($job->commands_count == 1, "Job has 1 command: " . $job->commands_count);

$job->append_command("echo done");
ok($job->commands_count == 2, "Job has 2 commands: " . $job->commands_count);

# ==== OPTIONS ADDED ====
# Create a new instance of C<NBI::Opts>.
my $opts = NBI::Opts->new(-queue => "nbi-short");
# Add the opts to the job
$job->set_opts($opts);
# Check that the job has opts
ok(defined $job->opts, "Job has opts: " . $job->opts);
# Check that the opts are an instance of NBI::Opts
isa_ok($job->opts, 'NBI::Opts', "Job opts is NBI::Opts: " . $job->opts);
# Check that the opts has the queue
ok(defined $job->opts->queue, "Job opts has queue: " . $job->opts->queue);

#print $job->script();
done_testing();