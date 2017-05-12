#!perl -w

# Check no-fork option:
use Test::More tests => 5;
use Schedule::Cron;

$| = 1;

# Simple no fork execution
my $toggle = 0;
my $count = 0;
my $dispatch_1 = 
  sub {
      print "# Job 1.1\n";
      $toggle = 1;
  };
my $dispatch_2 = 
  sub {
      print "# Job 1.2\n";
      if ($toggle)
      {
          pass("Simple nofork - Second Job finished");
          die "ok\n";
      }
      $count++;
      fail("Job 1 has not run") if $count == 2;
      sleep 2;
  };

my $cron = new Schedule::Cron($dispatch_1,{nofork => 1});
$cron->add_entry("* * * * * *",$dispatch_2);
$cron->add_entry("* * * * * *");
eval
{
    $cron->run();
};
my $error = $@;
chomp $error;
ok($error eq "ok","Simple nofork - Cron has been run: $error");

# No fork with 'skip' option
$count = 0;
$dispatch_1 = 
  sub {
      print "# Job 2.1  ",scalar(localtime),"\n";
      if ($count == 1)
      {
          pass("Nofork with skip - Skip test passed");
          die "ok\n";
      }
      $count++;
      sleep(3);
      sleep(1) if ((localtime)[0] % 3 == 0);
  };
$dispatch_2 = 
  sub {
      print "# Job 2.2  ",scalar(localtime),"\n";
      die "Job 2.2 should never run\n";
  };

$cron = new Schedule::Cron($dispatch_1,{nofork => 1,log => sub {print "# ",$_[1],"\n"}});
$cron->add_entry("* * * * * *");
$cron->add_entry("* * * * * */3",$dispatch_2);
eval
{
    $cron->run(skip => 1);
};
$error = $@;
chomp $error;
ok($error eq "ok","Nofork with skip - Cron has been run: $error");

# No-Fork with 'catch' option.
$count = 0;

SKIP: {
    eval { alarm 0 };
    skip "alarm() not available", 1 if $@;

    $dispatch_1 = 
      sub {
          $count++;
          die "Exception";
      };
    
    $SIG{ALRM} = sub { 
        ok($count > 0,"Nofork with skip - Job has run");
        exit;
    };
    
    $cron = new Schedule::Cron($dispatch_1,{nofork => 1,log => sub {print "# ",$_[1],"\n"}});
    $cron->add_entry("* * * * * *");
    eval
    {
        alarm(3);
        $cron->run(catch => 1);
    };
    ok(!$@,"Nofork with skip - Job has died: $@");
 }





