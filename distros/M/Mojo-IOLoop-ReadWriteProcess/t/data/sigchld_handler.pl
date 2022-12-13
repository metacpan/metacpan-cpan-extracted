#!/usr/bin/perl
use warnings;
use strict;
use Time::HiRes 'sleep';

my $collected_pid = -1;
$SIG{CHLD} = sub {
  $collected_pid = waitpid(-1, 0);
  print "SIG_CHLD $collected_pid exit:" . ($? >> 8) . "\n";
};

my $pid = fork();
if ($pid == 0) {
  print "I'm the child $$\n";
  exit 0;
}
print "Forked child is $pid\n";
sleep 0.1 while ($collected_pid != $pid);
print "Exit graceful\n";
exit 0;
