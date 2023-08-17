#!/usr/local/bin/perl -w
###
### Author:       Simon Leinen  <simon@switch.ch>
### Date Created: 03-Mar-1999
###
### Try to work with Counter64 values
###
require 5.003;

use strict;

### Forward declarations
sub usage ($);

use BER;
use SNMP_Session "0.67";	# requires map_table_4
use POSIX;			# for exact time
use Curses;
use Math::BigInt;

my $version = '1';

my $desired_interval = 5.0;

while (defined $ARGV[0] && $ARGV[0] =~ /^-/) {
    if ($ARGV[0] =~ /^-v/) {
	if ($ARGV[0] eq '-v') {
	    shift @ARGV;
	    usage (1) unless defined $ARGV[0];
	} else {
	    $ARGV[0] = substr($ARGV[0], 2);
	}
	if ($ARGV[0] eq '1') {
	    $version = '1';
	} elsif ($ARGV[0] eq '2c') {
	    $version = '2c';
	} else {
	    usage (1);
	}
    } elsif ($ARGV[0] =~ /^-t/) {
	if ($ARGV[0] eq '-t') {
	    shift @ARGV;
	    usage (1) unless defined $ARGV[0];
	} else {
	    $ARGV[0] = substr($ARGV[0], 2);
	}
	if ($ARGV[0] =~ /^[0-9]+(\.[0-9]+)?$/) {
	    $desired_interval = $ARGV[0];
	} else {
	    usage (1);
	}
    } elsif ($ARGV[0] eq '-h') {
	usage (0);
	exit 0;
    } else {
	usage (1);
    }
    shift @ARGV;
}
my $host = shift @ARGV || usage (1);
my $community = shift @ARGV || "public";
usage (1) if $#ARGV >= $[;

my $ifDescr = [1,3,6,1,2,1,2,2,1,2];
my $ifAdminStatus = [1,3,6,1,2,1,2,2,1,7];
my $ifOperStatus = [1,3,6,1,2,1,2,2,1,8];
my $ifInOctets = [1,3,6,1,2,1,2,2,1,10];
my $ifOutOctets = [1,3,6,1,2,1,2,2,1,16];
my $ifHCInOctets = [1,3,6,1,2,1,31,1,1,1,6];
my $ifHCOutOctets = [1,3,6,1,2,1,31,1,1,1,10];
my $ifInUcastPkts = [1,3,6,1,2,1,2,2,1,11];
my $ifOutUcastPkts = [1,3,6,1,2,1,2,2,1,17];

my $clock_ticks = POSIX::sysconf( &POSIX::_SC_CLK_TCK );

my $win = new Curses;

my %old;
my $sleep_interval = $desired_interval + 0.0;
my $interval;
my $linecount;

sub out_interface {
    my ($index, $descr, $admin, $oper, $in, $out) = @_;
    my ($clock) = POSIX::times();
    my $alarm = 0;

    grep (defined $_ && ($_=pretty_print $_),
	  ($descr, $admin, $oper, $in, $out));
    $win->clrtoeol ();
    return unless defined $oper && $oper == 1;	# up
    return unless defined $in && defined $out;
    if (!defined $old{$index}) {
	$win->addstr ($linecount, 0,
		      sprintf ("%2d  %-24s %10s %10s\n",
			       $index,
			       defined $descr ? $descr : '',
			       defined $in ? $in : '-',
			       defined $out ? $out : '-'));
    } else {
	my $old = $old{$index};

	$interval = ($clock-$old->{'clock'}) * 1.0 / $clock_ticks;
	my $d_in = $in ? ("".$in-$old->{'in'})*8000
	    /int ($interval*1000)
	    : 0;
	my $d_out = $out ? ("".$out-$old->{'out'})*8000
	    /int ($interval*1000)
	    : 0;
	warn "in: $in out: $out d_in: $d_in d_out: $d_out old->{in}: ",$old->{in}," old->{out}: ",$old->{out};
	$alarm = ($d_out > 0 && $d_in == 0);
	print STDERR "\007" if $alarm && !$old->{'alarm'};
	print STDERR "\007" if !$alarm && $old->{'alarm'};
	$win->standout() if $alarm;
	$win->addstr ($linecount, 0,
		      sprintf ("%2d  %-24s %10.1f %10.1f\n",
			       $index,
			       defined $descr ? $descr : '',
			       defined $in ? $d_in : 0,
			       defined $out ? $d_out : 0));
	$win->standend() if $alarm;
    }
    $old{$index} = {'in' => $in,
		    'out' => $out,
		    'clock' => $clock,
		    'alarm' => $alarm};
    ++$linecount;
    $win->refresh ();
}

$win->erase ();
my $session =
    ($version eq '1' ? SNMPv1_Session->open ($host, $community, 161)
     : $version eq '2c' ? SNMPv2c_Session->open ($host, $community, 161)
     : die "Unknown SNMP version $version")
  || die "Opening SNMP_Session";

### max_repetitions:
###
### We try to be smart about the value of $max_repetitions.  Starting
### with the session default, we use the number of rows in the table
### (returned from map_table_4) to compute the next value.  It should
### be one more than the number of rows in the table, because
### map_table needs an extra set of bindings to detect the end of the
### table.
###
my $max_repetitions = $session->default_max_repetitions;
while (1) {
    $win->addstr (0, 0, sprintf ("%-20s interval %4.1fs %d reps",
				 $host,
				 $interval || $desired_interval,
				 $max_repetitions));
    $win->standout();
    $win->addstr (1, 0,
		  sprintf ("%2s  %-24s %10s %10s\n",
			   "ix", "name",
			   "bits/s", "bits/s"));
    $win->addstr (2, 0,
		  sprintf ("%2s  %-24s %10s %10s\n",
			   "", "",
			   "in", "out"));
    $win->clrtoeol ();
    $win->standend();
    $linecount = 3;
    my $calls = $session->map_table_4
	([$ifDescr,
	  $ifAdminStatus,
	  $ifOperStatus,
	  $version ne '1' ? $ifHCInOctets : $ifInOctets,
	  $version ne '1' ? $ifHCOutOctets : $ifOutOctets],
	 \&out_interface,
	 $max_repetitions);
    $max_repetitions = $calls + 1
	if $calls > 0;
    $sleep_interval -= ($interval - $desired_interval)
	if defined $interval;
    select (undef, undef, undef, $sleep_interval);
}
1;

sub usage ($) {
    warn <<EOM;
Usage: $0 [-t secs] [-v (1|2c)] switch [community]
       $0 -h

  -h           print this usage message and exit.

  -t secs      specifies the sampling interval.  Defaults to 5 seconds.

  -v version   can be used to select the SNMP version.  The default
   	       is SNMPv1, which is what most devices support.  If your box
   	       supports SNMPv2c, you should enable this by passing "-v 2c"
   	       to the script.  SNMPv2c is much more efficient for walking
   	       tables, which is what this tool does.

  switch       hostname or IP address of an LS1010 switch

  community    SNMP community string to use.  Defaults to "public".
EOM
    exit (1) if $_[0];
}
