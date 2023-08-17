
#!/usr/bin/env perl
use v5.12;
use warnings;
use Data::Dumper;
# add to library ../lib/
use FindBin qw($RealBin);
use Getopt::Long;
use NBI::Queue;
my $username;
my $queue;
my $name;
my $jobid;
my $state;
GetOptions(
    "username=s" => \$username,
    "queue=s" => \$queue,
    "name=s" => \$name,
    "jobid=i" => \$jobid,
    "state=s" => \$state,
);

say "Hello World! ", $NBI::Queue::VERSION;
my $filter = NBI::Queue->new(
    -username => $username,
    -queue => $queue,
    -name => $name,
    -jobid => $jobid,
    -state => $state,
);
print STDERR "
username: ", $username ? $username : "undef", "
queue:    ", $queue ? $queue : "undef", "
name:     ", $name ? $name : "undef", "
jobid:    ", $jobid ? $jobid : "undef", "
state:    ", $state ? $state : "undef", "
-----------------
";

say "Jobs selected: ", $filter->len();
say "Jobs IDs: ", join(",",@{$filter->ids()});