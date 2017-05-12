#!/usr/bin/perl
#
# chkIFrunning.pl v0.03 5-26-09, michael@bizsystems.com
#
use strict;
use Proc::PidUtil qw(is_running zap_pidfile);

sub usage {
  print STDERR qq|
  $0    path_to_pidfile 
        [optional] excutable filepath arg0 arg0 ... argN]

  check if job in pidfile is running
  if running, exit 0
  if not running, exec the executable if it exists
        
|;
  exit 1;
}

&usage unless @ARGV;

my $pidfile = shift @ARGV;

&usage unless $pidfile;

if (-e $pidfile) {
  exit 0 if is_running($pidfile);
  zap_pidfile($pidfile);
}
exit 0 unless $ARGV[0] && -e $ARGV[0] && -x $ARGV[0];

exec @ARGV;
