#!perl -w

# Check that rescheduling entries within an entry callback works properly
# in nofork mode.
#
# by Andrew Danforth <acd@weirdness.net> based on existing testcases

use Test::More tests => 1;
use Schedule::Cron;

$| = 1;

my $cron = new Schedule::Cron(\&dispatch_1,{nofork => 1});
my $job1count = 0;
my $job2count = 0;

sub dispatch_1 {
   print "# Job 1.1, job1count: $job1count, job2count: $job2count\n";
   if ($job1count++ == 0) {
      $cron->clean_timetable;
      $cron->add_entry("* * * * * 0-59/4", \&dispatch_2);
      $cron->add_entry("* * * * * 2-59/4");
   } else {
      die "ok\n" if $job2count;
      die "job2 never ran";
   }
}

sub dispatch_2 {
   print "# Job 1.2, job1count: $job1count, job2count: $job2count\n";
   if ($job2count++) {
      die "job1 got lost -- job2 ran again before job1 a second time";
   }
}

$cron->add_entry("* * * * * 2-59/4");
eval
{
    $cron->run();
};
my $error = $@;
chomp $error;
ok($error eq "ok","rescheduled jobs work properly ($error)");
