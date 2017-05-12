#!/usr/bin/env perl -w

# check_mem2.pl Copyright (C) 2012 Gisbert W. Selke <gws@cpan.org>
# Modelled after
# check_mem.pl Copyright (C) 2000 Dan Larsson <dl@tyfon.net>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program (or with Nagios);  if not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA

## no critic   # added by M.S.

# Tell Perl what we need to use
use strict;
use warnings;
use Getopt::Long qw(:config bundling);

BEGIN { eval('require Win32::SystemInfo') if ($^O =~ /Win/i); }

my $PROGNAME  = 'check_mem2.pl';
my $VERSION   = '1.1';

my ($check_free, $check_used, $level_warn, $level_crit, $verbose);

# Predefined exit codes for Nagios
my %exit_codes = ('UNKNOWN'  => -1,
                  'OK'       =>  0,
                  'WARNING'  =>  1,
                  'CRITICAL' =>  2,
                 );

# Get the options
GetOptions('critical|c=f' => \$level_crit,
           'warning|w=f'  => \$level_warn,
           'free|f!'      => \$check_free,
           'used|u!'      => \$check_used,
           'verbose|v!'   => \$verbose,
          );

my $opt_count = 0;
$opt_count++  if $check_free;
$opt_count++  if $check_used;
if ($opt_count != 1) {
  print '*** You must select to monitor either USED or FREE memory!' if $verbose;
  usage();
}

# Check the levels
if (($level_warn <= 0) || ($level_crit <= 0)) {
  print '*** You must define positive WARN and CRITICAL levels!' if $verbose;
  usage();
}

# Check if levels are sane
if ($check_free && ($level_warn <= $level_crit)) {
  print '*** WARN level must not be less than or equal to CRITICAL when checking FREE memory!' if $verbose;
  usage();
}

if ($check_used && ($level_warn >= $level_crit)) {
  print '*** WARN level must not be greater than or equal to CRITICAL when checking USED memory or PROCESSOR load!' if $verbose;
  usage();
}

my($memory, $percent);
if ($^O !~ /Win/i) {
  # This the unix command string that brings Perl the data
  my $command_line = `vmstat | tail -1`;
  if (!$command_line) {
    print "*** System command vmstat not found or yielded no result!";
    exit $exit_codes{'UNKNOWN'};
  }
  my @memlist      = split(/\s+/, $command_line);
  my $total_memory = $memlist[3] + $memlist[4];
  $memory          = $memlist[$check_used ? 3 : 4];
  $percent         = $memory/$total_memory * 100;
} else {
  my %info;
  Win32::SystemInfo::MemoryStatus(%info);
  my $total_memory = $info{'TotalPhys'};       # Or TotalVirtual??
  $percent = $check_used ? $info{'MemLoad'} : (100 - $info{'MemLoad'});
  $memory  = sprintf '%d', $total_memory*$percent*0.01;
}

my $state   = 'OK';
if ($check_used) {
  $state    = 'WARNING'  if ($percent >= $level_warn);
  $state    = 'CRITICAL' if ($percent >= $level_crit);
} else {
  $state    = 'WARNING'  if ($percent <= $level_warn);
  $state    = 'CRITICAL' if ($percent <= $level_crit);
}
printf "Memory %s - %1.1f%% (%d kB) %s\n", $state, $percent, $memory, ($check_used ? 'used' : 'free');
exit $exit_codes{$state};

# Show usage
sub usage {
  print "\n$PROGNAME $VERSION - Nagios Plugin\n\n";
  print "usage:\n";
  print " $PROGNAME -<f|u> -w <warnlevel> -c <critlevel> [-v]\n\n";
  print "options:\n";
  print " --free                   Check FREE memory\n";
  print " --used                   Check USED memory\n";
  print " --warning  PERCENT       Percent free/used/load when to warn\n";
  print " --critical PERCENT       Percent free/used/load when critical\n";
  print " --verbose                Show verbose error messages\n";
  print "All options may be abbreviated.\n";
  print "\nCopyright (C) 2012 Dan Larsson <dl\@tyfon.net> / Gisbert W. Selke <gws\@cpan.org)\n";
  print "$PROGNAME comes with absolutely NO WARRANTY either implied or explicit\n";
  print "This program is licensed under the terms of the\n";
  print "GNU General Public License (check source code for details)\n";
  exit $exit_codes{'UNKNOWN'};
}
