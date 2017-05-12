#!perl -w

use Schedule::Cron;
use File::Basename;
use strict;

my $crontab = dirname($0)."/test.crontab";

my $cron;
my @tests = (
             qq(
                \$cron = new Schedule::Cron( sub {},
                                             file => "$crontab",
                                             eval => 1)
                ),
             qq(
                \$cron = new Schedule::Cron(sub {});
                \$cron->load_crontab("$crontab");
                ),
             qq(
                \$cron = new Schedule::Cron(sub {});
                \$cron->load_crontab(file=>"$crontab",eval=>1);
                ),
             qq(
                \$cron = new Schedule::Cron(sub {});
                \$cron->load_crontab({file=>"$crontab",eval=>1});
                )
	     
);

print "1..",scalar(@tests),"\n";
my $i = 1;
foreach (@tests) {
  eval $_;
  
  if ($@) { 
    print "Error during loading of crontab file: $@\n";
    print "not ok $i\n";
  } else {
    print "ok $i\n";
  }
#  print "Cron:\n",Dumper($cron);
  $i++;
}

# Check for time parsing
$cron = new Schedule::Cron(sub {});
$cron->load_crontab($crontab);



