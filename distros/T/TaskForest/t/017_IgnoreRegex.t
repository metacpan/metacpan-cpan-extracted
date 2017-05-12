# -*- perl -*-

my $SLEEP_TIME = 2;
use Test::More tests => 12;

use strict;
use warnings;
use Data::Dumper;
use Cwd;
use File::Copy;
use TaskForest::Test;

BEGIN {
    use_ok( 'TaskForest'  );
}

&TaskForest::LocalTime::setTime( { year  => 2009,
                                   month => 04,
                                   day   => 12,
                                   hour  => 22,
                                   min   => 30,
                                   sec   => 57,
                                   tz    => 'America/Chicago',
                                 });
                                       

my $cwd = getcwd();
my $src_dir = "$cwd/t/family_archive";
my $dest_dir = "$cwd/t/families";
mkdir $dest_dir unless -d $dest_dir;

&TaskForest::Test::cleanup_files($dest_dir);


copy("$src_dir/IGNORE01", $dest_dir);
copy("$src_dir/IGNORE02", $dest_dir);
copy("$src_dir/IGNORE03.bak", $dest_dir);
copy("$src_dir/IGNORE04_HASH", "$dest_dir/#IGNORE04#");
copy("$src_dir/IGNORE05_TILDE", "$dest_dir/IGNORE05~");


$ENV{TF_RUN_WRAPPER} = "$cwd/blib/script/run";
$ENV{TF_LOG_DIR}     = "$cwd/t/logs";
$ENV{TF_JOB_DIR}     = "$cwd/t/jobs";
$ENV{TF_FAMILY_DIR}  = "$cwd/t/families";
$ENV{TF_ONCE_ONLY}   = 1;
$ENV{TF_LOG}         = 1;

my $log_dir = &TaskForest::LogDir::getLogDir($ENV{TF_LOG_DIR}, 'America/Chicago');
&TaskForest::Test::cleanup_files($log_dir);


my $tf = TaskForest->new();
isa_ok($tf,  'TaskForest',  'TaskForest created successfully');

$tf->{options}->{once_only} = 1;

print "Running ready jobs\n";
$tf->runMainLoop();

$tf->{options}->{once_only} = 1;

print "Waiting $SLEEP_TIME seconds for job to finish\n";

my $num_tries = 10;
for (my $n = 1; $n <= $num_tries; $n++) { 
    sleep $SLEEP_TIME;
    last if (-e "$log_dir/IGNORE01.J1.0" 
             and -e "$log_dir/IGNORE02.J2.0" 
        );
    diag("Haven't found job log files on try $n of $num_tries.  Sleeping another $SLEEP_TIME seconds");  # It's possible that the fork failed, or that we don't have write permission to the log dir. OR IT'S NOT TIME YET.
}

my $diag = "Try to increase the value of \$SLEEP_TIME in t/017_IgnoreRegex.t";

ok(-e "$log_dir/IGNORE01.J1.0", "  After first cycle, J1 ran successfully") || diag ($diag) ;
ok(-e "$log_dir/IGNORE02.J2.0", "  After first cycle, J2 ran successfully") || diag ($diag) ;

# make sure the J3, J4 and J5 files are not there
opendir DIR, $log_dir or die "opendir $log_dir: $!";
my $files = join(", ", readdir DIR);
closedir DIR;
unlike ($files, qr/J3/, "J3 was not in contention");
unlike ($files, qr/J4/, "J4 was not in contention");
unlike ($files, qr/J5/, "J5 was not in contention");



# SECOND TIME
&TaskForest::Test::cleanup_files($log_dir);

$ENV{TF_IGNORE_REGEX} = ['02$'];
$tf = TaskForest->new();


$tf->{options}->{once_only} = 1;

print "Running ready jobs a second time\n";
$tf->runMainLoop();

$tf->{options}->{once_only} = 1;

print "Waiting $SLEEP_TIME seconds for job to finish\n";

$num_tries = 10;
for (my $n = 1; $n <= $num_tries; $n++) { 
    sleep $SLEEP_TIME;
    last if (-e "$log_dir/IGNORE01.J1.0" 
        );
    diag("Haven't found job log files on try $n of $num_tries.  Sleeping another $SLEEP_TIME seconds");  # It's possible that the fork failed, or that we don't have write permission to the log dir. OR IT'S NOT TIME YET.
}

$diag = "Try to increase the value of \$SLEEP_TIME in t/017_IgnoreRegex.t";

ok(-e "$log_dir/IGNORE01.J1.0", "  After second cycle, J1 ran successfully") || diag ($diag) ;

# make sure the J2, J3, J4 and J5 files are not there
opendir DIR, $log_dir or die "opendir $log_dir: $!";
$files = join(", ", readdir DIR);
closedir DIR;
unlike ($files, qr/J2/, "J2 was not in contention");
unlike ($files, qr/J3/, "J3 was not in contention");
unlike ($files, qr/J4/, "J4 was not in contention");
unlike ($files, qr/J5/, "J5 was not in contention");

    



&TaskForest::Test::cleanup_files($log_dir);



