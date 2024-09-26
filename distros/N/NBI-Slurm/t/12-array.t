use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;

# This test checks the loadability of the module
# and that the object is correctly blessed as FASTX::Reader

use_ok 'NBI::Slurm';
my $placeholder = '{placeholder}';
# List files in current dir:
opendir(my $dh, $RealBin) || die "Can't opendir $RealBin: $!";
my @files = readdir($dh);
closedir $dh;

my $opts = NBI::Opts->new(
    -queue => 'default',
    -threads => 1,
    -memory => 12000,
    -time   => "1-00:00:00",
    -tmpdir => '/tmp',
    -files => \@files,
    -placeholder => $placeholder,
);

my $job = NBI::Job->new(
    -name => 'job-name',
    -command => "ls -l $placeholder",
    -opts => $opts,
);

my $script = $job->script;
ok ($script =~ /\$\{selected_file\}/, 'Array script has variable selected_file');
ok ($script !~ /$placeholder/, "No $placeholder in script");
done_testing();