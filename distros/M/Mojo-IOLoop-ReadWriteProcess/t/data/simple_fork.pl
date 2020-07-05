use warnings;
use strict;

my $pid1 = fork();
if ($pid1 == 0) {
  print "fork 1\n";
  sleep 1000;
}
my $pid2 = fork();
if ($pid2 == 0) {
  print "fork 2\n";
  sleep 1000;
}
waitpid $pid1, 0;
waitpid $pid2, 0;
