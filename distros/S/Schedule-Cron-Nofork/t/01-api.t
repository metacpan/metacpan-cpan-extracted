#!/usr/bin/perl -w
use strict;

use Test::More tests => 21;

use_ok("Schedule::Cron::Nofork");

my $next_minute = "* * * * *";

my @method = qw( new run load_crontab clean_timetable add_entry check_entry );

BEGIN {
  # diag "Checking whether alarm() is supported";

  # Replace alarm() with our dummy version if it isn't supported natively (e.g. Win32)
  eval { alarm(0); };
  if ($@) {
    # diag "alarm() is not supported (installing harmless dummy).";
    eval q!
      use subs 'alarm';
      sub alarm { diag "Press CTRL-C if this test didn't stop after $_[0] seconds" if $_[0] };
    !;
  } else {
    # diag "alarm() is supported. Timeouts will be used.";
  };
};

my @dispatched = ();
my $cron = Schedule::Cron::Nofork->new( sub { push @dispatched, [@_]; die "General dispatch called" } );
isa_ok($cron,"Schedule::Cron::Nofork");
can_ok($cron,@method);

diag "Scheduling an entry for $next_minute, please stand by";
$cron->add_entry($next_minute,sub { die "Cron job called" });
eval {
  $SIG{ALRM} = sub { die "Timeout reached" };
  alarm(90);
  $cron->run();
};
alarm(0);
like($@,"/Cron job called/","Scheduled job was called");

@dispatched = ();
$cron = Schedule::Cron::Nofork->new( sub { push @dispatched, [@_]; die "General dispatch called" } );
isa_ok($cron,"Schedule::Cron::Nofork");

diag "Scheduling an entry for $next_minute, please stand by";
$cron->add_entry($next_minute,MESSAGE => 'just testing' );
eval {
  $SIG{ALRM} = sub { die "Timeout reached" };
  alarm(90);
  $cron->run();
};
alarm(0);
like($@,"/General dispatch called/","Scheduled job was called");
is(scalar @dispatched,1,"One job was dispatched");
is($dispatched[0]->[0],"MESSAGE","General dispatch parameters[0]");
is($dispatched[0]->[1],"just testing","General dispatch parameters[1]");

@dispatched = ();
$cron = Schedule::Cron::Nofork->new( sub { push @dispatched, [@_]; die "General dispatch called" } );
isa_ok($cron,"Schedule::Cron::Nofork");

diag "Scheduling two entries for $next_minute, please stand by";
$cron->add_entry($next_minute,MESSAGE => 'just testing (first)' );
$cron->add_entry($next_minute,MESSAGE => 'just testing (second)' );
eval {
  $SIG{ALRM} = sub { die "Timeout reached" };
  alarm(90);
  $cron->run();
};
alarm(0);
like($@,"/General dispatch called/","Scheduled job was called");
is(scalar @dispatched,1,"Only one job was dispatched");
is($dispatched[0]->[0],"MESSAGE","General dispatch parameters[0]");
like($dispatched[0]->[1],"/^just testing/","General dispatch parameters[1]");

@dispatched = ();
$cron = Schedule::Cron::Nofork->new( sub { push @dispatched, [@_]; goto &{$_[1]} } );
isa_ok($cron,"Schedule::Cron::Nofork");

diag "Scheduling three entries for $next_minute, please stand by";

my $count = 0;
sub work {
  $count++;
  diag "work() was called $count time(s)";
  sleep 20;
  die "Work done" if $count == 3;
};

$cron->add_entry($next_minute,RUN => \&work );
$cron->add_entry($next_minute,RUN => \&work );
$cron->add_entry($next_minute,RUN => \&work );
my $now = time();
eval {
  $SIG{ALRM} = sub { die "Timeout reached" };
  alarm(185);
  $cron->run();
};
alarm(0);
like($@,"/Work done/","Scheduled cleanup was called");
is(scalar @dispatched,3,"All three jobs were dispatched");
# Doing all work takes 60 seconds or more :
cmp_ok(time-$now,'>',59,"No parallel execution");
for (@dispatched) {
  is($_->[0],"RUN","General dispatch parameters[0]");
};