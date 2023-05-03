#!/usr/local/bin/perl -w
######################################################################
### Observe interface counters in real time.
######################################################################
### Copyright (c) 1995-2000, Simon Leinen.
###
### This program is free software; you can redistribute it under the
### "Artistic License" included in this distribution (file "Artistic").
######################################################################
### Author:       Simon Leinen  <simon@switch.ch>
### Date Created: 21-Feb-1999
###
### Real-time full-screen display of the octet and (Cisco-specific)
### CRC error counters on interfaces of an SNMP-capable node
###
### Description: 
###
### Call this script with "-h" to learn about command usage.
###
### The script will poll the RFC 1213 ifTable at specified intervals
### (default is every five seconds).
###
### For each interface except for those that are down, a line is
### written to the terminal which lists the interfaces name (ifDescr),
### well as the input and output transfer rates, as computed from the
### deltas of the respective octet counts since the last sample.
###
### "Alarms"
###
### When an interface is found to have had CRC errors in the last
### sampling interval, or only output, but no input traffic, it is
### shown in inverse video.  In addition, when a link changes state
### (from normal to inverse or vice versa), a bell character is sent
### to the terminal.
###
### Miscellaneous
###
### Note that on the very first display, the actual SNMP counter
### values are displayed.  THOSE ABSOLUTE COUNTER VALUES HAVE NO
### DEFINED SEMANTICS WHATSOEVER.  However, in some versions of
### Cisco's software, the values seem to correspond to the total
### number of counted items since system boot (modulo 2^32).  This can
### be useful for certain kinds of slowly advancing counters (such as
### CRC errors, hopefully).
###
### The topmost screen line shows the name of the managed node, as
### well as a few hard-to-explain items I found useful while debugging
### the script.
###
### Please send any patches and suggestions for improvement to the
### author (see e-mail address above).  Hope you find this useful!
###
### Original Purpose:
###
### This script should serve as an example of how to "correctly"
### traverse the rows of a table.  This functionality is implemented in
### the map_table() subroutine.  The example script displays a few
### columns of the RFC 1213 interface table and Cisco's locIfTable.  The
### tables share the same index, so they can be handled by a single
### invocation of map_table().
###
require 5.003;

use strict;

use BER;
use SNMP_Session "0.96";	# requires map_table_4() and ipv4only
use POSIX;			# for exact time
use Curses;
use Math::BigInt;
use Math::BigFloat;

### Forward declarations
sub out_interface ($$$$$$@);
sub pretty_ps ($$);
sub usage ($ );

my $version = '1';

my $desired_interval = 5.0;

my $switch_engine_p = 0;

my $all_p = 0;

my $port = 161;

my $max_repetitions = 0;

my $suppress_output = 0;

my $suppress_curses = 0;

my $debug = 0;

my $show_out_discards = 0;

my $cisco_p = 0;

## Whether to use 64-bit counters.  Can be requested with `-l' option.
my $counter64_p = 0;

## Whether to select IPv4-only in open().  Can be set using `-4' option.
my $ipv4_only_p = 0;

my $host;

my $community;

my $use_getbulk_p = 1;

while (defined $ARGV[0]) {
    if ($ARGV[0] =~ /^-v/) {
	if ($ARGV[0] eq '-v') {
	    shift @ARGV;
	    usage (1) unless defined $ARGV[0];
	} else {
	    $ARGV[0] = substr($ARGV[0], 2);
	}
	if ($ARGV[0] eq '1') {
	    $version = '1';
	} elsif ($ARGV[0] eq '2c' or $ARGV[0] eq '2') {
	    $version = '2c';
	} else {
	    usage (1);
	}
    } elsif ($ARGV[0] =~ /^-m/) {
	if ($ARGV[0] eq '-m') {
	    shift @ARGV;
	    usage (1) unless defined $ARGV[0];
	} else {
	    $ARGV[0] = substr($ARGV[0], 2);
	}
	if ($ARGV[0] =~ /^[0-9]+$/) {
	    $max_repetitions = $ARGV[0];
	} else {
	    usage (1);
	}
    } elsif ($ARGV[0] =~ /^-p/) {
	if ($ARGV[0] eq '-p') {
	    shift @ARGV;
	    usage (1) unless defined $ARGV[0];
	} else {
	    $ARGV[0] = substr($ARGV[0], 2);
	}
	if ($ARGV[0] =~ /^[0-9]+$/) {
	    $port = $ARGV[0];
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
    } elsif ($ARGV[0] eq '-B') {
	$use_getbulk_p = 0;
    } elsif ($ARGV[0] eq '-s') {
	$switch_engine_p = 1;
    } elsif ($ARGV[0] eq '-a') {
	$all_p = 1;
    } elsif ($ARGV[0] eq '-c') {
	$cisco_p = 1;
    } elsif ($ARGV[0] eq '-l') {
	$counter64_p = 1;
    } elsif ($ARGV[0] eq '-n') {
	$suppress_output = 1;
	$suppress_curses = 1;
    } elsif ($ARGV[0] eq '-C') {
	$suppress_output = 0;
	$suppress_curses = 1;
    } elsif ($ARGV[0] eq '-d') {
	$suppress_output = 0;
	$suppress_curses = 1;
	$debug = 1;
    } elsif ($ARGV[0] eq '-D') {
	$show_out_discards = 1;
    } elsif ($ARGV[0] eq '-4') {
	$ipv4_only_p = 1;
    } elsif ($ARGV[0] eq '-h') {
	usage (0);
	exit 0;
    } elsif ($ARGV[0] =~ /^-/) {
	usage (1);
    } else {
	if (!defined $host) {
	    $host = $ARGV[0];
	} elsif (!defined $community) {
	    $community = $ARGV[0];
	} else {
	    usage (1);
	}
    }
    shift @ARGV;
}
defined $host or usage (1);
defined $community or $community = 'public';
usage (1) if $#ARGV >= $[;

my $ifDescr = [1,3,6,1,2,1,2,2,1,2];
my $ifAdminStatus = [1,3,6,1,2,1,2,2,1,7];
my $ifOperStatus = [1,3,6,1,2,1,2,2,1,8];
my $ifInOctets = [1,3,6,1,2,1,2,2,1,10];
my $ifOutOctets = [1,3,6,1,2,1,2,2,1,16];
my $ifInUcastPkts = [1,3,6,1,2,1,2,2,1,11];
my $ifOutUcastPkts = [1,3,6,1,2,1,2,2,1,17];
my $ifOutDiscards = [1,3,6,1,2,1,2,2,1,19];
my $ifAlias = [1,3,6,1,2,1,31,1,1,1,18];
## Counter64 variants
my $ifHCInOctets = [1,3,6,1,2,1,31,1,1,1,6];
my $ifHCOutOctets = [1,3,6,1,2,1,31,1,1,1,10];
## Cisco-specific variables enabled by `-c' option
my $locIfInCRC = [1,3,6,1,4,1,9,2,2,1,1,12];
my $locIfOutCRC = [1,3,6,1,4,1,9,2,2,1,1,12];

my $cseL3SwitchedTotalPkts = [1,3,6,1,4,1,9,9,97,1,4,1,1,1];
my $cseL3SwitchedTotalOctets = [1,3,6,1,4,1,9,9,97,1,4,1,1,2];
my $cseL3CandidateFlowHits = [1,3,6,1,4,1,9,9,97,1,4,1,1,3];
my $cseL3EstablishedFlowHits = [1,3,6,1,4,1,9,9,97,1,4,1,1,4];
my $cseL3ActiveFlows = [1,3,6,1,4,1,9,9,97,1,4,1,1,5];
my $cseL3FlowLearnFailures = [1,3,6,1,4,1,9,9,97,1,4,1,1,6];
my $cseL3IntFlowInvalids = [1,3,6,1,4,1,9,9,97,1,4,1,1,7];
my $cseL3ExtFlowInvalids = [1,3,6,1,4,1,9,9,97,1,4,1,1,8];

my $clock_ticks = POSIX::sysconf( &POSIX::_SC_CLK_TCK );

my $win = new Curses
    unless $suppress_curses;

my %old;
my $sleep_interval = $desired_interval + 0.0;
my $interval;
my $linecount;

sub rate_32 ($$$@) {
    my ($old, $new, $interval, $multiplier) = @_;
    $multiplier = 1 unless defined $multiplier;
    my $diff = $new-$old;
    if ($diff < 0) {
	$diff += (2**32);
    }
    return $diff / $interval * $multiplier;
}

sub rate_64 ($$$@) {
    my ($old, $new, $interval, $multiplier) = @_;
    $multiplier = 1 unless defined $multiplier;
    return 0 if $old == $new;
    my $diff = Math::BigInt->new ($new-$old);
    if ($diff < 0) {
	$diff = $diff->add (2**64);
    }
    warn "rate_64 ($old, $new, $interval, $multiplier)\n"
	if $debug;
    warn "  diff: $diff\n"
	if $debug;
    ## hrm.  Why is this so complicated?
    ## I want a real programming language (such as Lisp).
    my $result = new Math::BigFloat ($diff->bnorm ());
    warn "  result: $result\n"
	if $debug;
    $result /= $interval;
    warn "  result: $result\n"
	if $debug;
    $result *= $multiplier;
    warn "  result: $result\n"
	if $debug;
    return $result;
}

sub rate ($$$$@) {
    my ($old, $new, $interval, $counter64_p, $multiplier) = @_;
    $multiplier = 1 unless defined $multiplier;
    return $counter64_p
	? rate_64 ($old, $new, $interval, $multiplier)
	: rate_32 ($old, $new, $interval, $multiplier);
}

sub rate_or_0 ($$$@) {
    my ($old, $new, $interval, $counter64_p, $multiplier) = @_;
    $counter64_p = 0 unless defined $counter64_p;
    $multiplier = 1 unless defined $multiplier;
    return defined $new
	? rate ($old, $new, $interval, $counter64_p, $multiplier)
	: 0;
}

sub out_interface ($$$$$$@) {
    my ($index, $descr, $admin, $oper, $in, $out);
    my ($crc, $comment);
    my ($drops);
    my ($clock) = POSIX::times();
    my $alarm = 0;

    ($index, $descr, $admin, $oper, $in, $out, $comment, @_) = @_;
    ($crc, @_) = @_ if $cisco_p;
    ($drops, @_) = @_ if $show_out_discards;

    grep (defined $_ && ($_=pretty_print $_),
	  ($descr, $admin, $oper, $in, $out, $crc, $comment, $drops));
    $win->clrtoeol ()
	unless $suppress_curses;
    return unless $all_p || defined $oper && $oper == 1; # up
    return unless defined $in && defined $out;
    ## Suppress interfaces called "unrouted VLAN..."
    return if $descr =~ /^unrouted VLAN/;
    if (!defined $old{$index}) {
	if ($suppress_output) {
	    # do nothing
	} elsif ($suppress_curses) {
	    printf STDOUT ("%5d  %-24s %10s %10s",
			   $index,
			   defined $descr ? $descr : '',
			   defined $in ? $in : '-',
			   defined $out ? $out : '-');
	} else {
	    $win->addstr ($linecount, 0,
			  sprintf ("%5d  %-24s %10s %10s",
				   $index,
				   defined $descr ? $descr : '',
				   defined $in ? $in : '-',
				   defined $out ? $out : '-'));
	}
	if ($show_out_discards) {
	    if ($suppress_output) {
		# do nothing
	    } elsif ($suppress_curses) {
		printf STDOUT (" %8s", defined $drops ? $drops : '-');
	    } else {
		$win->addstr (sprintf (" %8s",
				       defined $drops ? $drops : '-'));
	    }
	}
	if ($cisco_p) {
	    if ($suppress_output) {
		# do nothing
	    } elsif ($suppress_curses) {
		printf STDOUT (" %10s", defined $crc ? $crc : '-');
	    } else {
		$win->addstr (sprintf (" %10s",
				       defined $crc ? $crc : '-'));
	    }
	}
	if ($suppress_output) {
	    # do nothing
	} elsif ($suppress_curses) {
	    printf STDOUT (" %s", defined $comment ? $comment : '');
	} else {
	    $win->addstr (sprintf (" %s", defined $comment ? $comment : ''));
	}
	print "\n" if !$suppress_output and $suppress_curses;
    } else {
	my $old = $old{$index};

	$interval = ($clock-$old->{'clock'}) * 1.0 / $clock_ticks;
	my $d_in = rate_or_0 ($old->{'in'}, $in, $interval, $counter64_p, 8);
	my $d_out = rate_or_0 ($old->{'out'}, $out, $interval, $counter64_p, 8);
	my $d_drops = rate_or_0 ($old->{'drops'}, $drops, $interval, 0);
	my $d_crc = rate_or_0 ($old->{'crc'}, $crc, $interval, 0);
	$alarm = ($d_crc != 0)
	    || 0 && ($d_out > 0 && $d_in == 0);
	print STDERR "\007" if $alarm && !$old->{'alarm'};
	print STDERR "\007" if !$alarm && $old->{'alarm'};
	$win->standout() if $alarm && !$suppress_curses;
	if ($suppress_output) {
	    # do nothing
	} elsif ($suppress_curses) {
	    printf STDOUT ("%5d  %-24s %s %s",
			   $index,
			   defined $descr ? $descr : '',
			   pretty_ps ($in, $d_in),
			   pretty_ps ($out, $d_out));
	} else {
	    $win->addstr ($linecount, 0,
			  sprintf ("%5d  %-24s %s %s",
				   $index,
				   defined $descr ? $descr : '',
				   pretty_ps ($in, $d_in),
				   pretty_ps ($out, $d_out)));
	}
	if ($show_out_discards) {
	    if ($suppress_output) {
		# do nothing
	    } elsif ($suppress_curses) {
		printf STDOUT (" %8.1f %s", defined $drops ? $d_drops : 0);
	    } else {
		$win->addstr (sprintf (" %8.1f %s",
				       defined $drops ? $d_drops : 0));
	    }
	}
	if ($cisco_p) {
	    if ($suppress_output) {
		# do nothing
	    } elsif ($suppress_curses) {
		printf STDOUT (" %10.1f", defined $crc ? $d_crc : 0);
	    } else {
		$win->addstr (sprintf (" %10.1f",
				       defined $crc ? $d_crc : 0));
	    }
	}
	if ($suppress_output) {
	    # do nothing
	} elsif ($suppress_curses) {
	    printf STDOUT (" %s", defined $comment ? $comment : '');
	} else {
	    $win->addstr (sprintf (" %s",
				   defined $comment ? $comment : ''));
	}
	$win->standend() if $alarm && !$suppress_output;
	print "\n" if !$suppress_output and $suppress_curses;
    }
    $old{$index} = {'in' => $in,
		    'out' => $out,
		    'crc' => $crc,
		    'drops' => $drops,
		    'clock' => $clock,
		    'alarm' => $alarm};
    ++$linecount;
    $win->refresh ()
	unless $suppress_output;
}

sub out_switching_engine ($$$$$$@) {
    my ($index,
	$pkts, $octets,
	$candidate_flow_hits,
	$established_flow_hits,
	$active_flows,
	$flow_learn_failures,
	$int_flow_invalids,
	$ext_flow_invalids) = @_;
    my ($clock) = POSIX::times();
    my $alarm = 0;

    grep (defined $_ && ($_=pretty_print $_),
	  ($pkts, $octets,
	   $candidate_flow_hits,
	   $established_flow_hits,
	   $active_flows,
	   $flow_learn_failures,
	   $int_flow_invalids,
	   $ext_flow_invalids));
    warn "RETRIEVED: pkts: $pkts\noctets: $octets\n"
	if $debug;
    $win->clrtoeol ()
	unless $suppress_curses;
    return unless defined $pkts and defined $octets;
    ## Suppress interfaces called "unrouted VLAN..."
    if (!defined $old{$index}) {
	if ($suppress_output) {
	    # do nothing
	} elsif ($suppress_curses) {
	    printf STDOUT ("%5d %10s %10s\n",
			   $index,
			   defined $pkts ? $pkts : '-',
			   defined $octets ? $octets : '-');
	} else {
	    $win->addstr ($linecount, 0,
			  sprintf ("%5d %10s %10s",
				   $index,
				   defined $pkts ? $pkts : '-',
				   defined $octets ? $octets : '-'));
	}
    } else {
	my $old = $old{$index};

	$interval = ($clock-$old->{'clock'}) * 1.0 / $clock_ticks;
	my $d_pkts = rate_or_0 ($old->{'pkts'}, $pkts, $interval, 0);
	my $d_octets = rate_or_0 ($old->{'octets'}, $octets, $interval, 1, 8);
	warn "RATE: pkts: $d_pkts\nbits: $d_octets\n"
	    if $debug;
	$alarm = 0;
	print STDERR "\007" if $alarm && !$old->{'alarm'};
	print STDERR "\007" if !$alarm && $old->{'alarm'};
	$win->standout() if $alarm && !$suppress_curses;
	if ($suppress_output) {
	    # do nothing
	} elsif ($suppress_curses) {
	    printf STDOUT ("%2d  %s %s",
			   $index,
			   pretty_ps ($pkts, $d_pkts),
			   pretty_ps ($octets, $d_octets));
	} else {
	    $win->addstr ($linecount, 0,
			  sprintf ("%2d  %s %s",
				   $index,
				   pretty_ps ($pkts, $d_pkts),
				   pretty_ps ($octets, $d_octets)));
	}
	$win->standend() if $alarm && !$suppress_curses;
	print "\n" if !$suppress_output and $suppress_curses;
    }
    $old{$index} = {'pkts' => $pkts,
		    'octets' => $octets,
		    'clock' => $clock,
		    'alarm' => $alarm};
    ++$linecount;
    $win->refresh ()
	unless $suppress_curses;
}

sub pretty_ps ($$) {
    my ($count, $bps) = @_;
    if (! defined $count) {
	return '      -   ';
    } elsif ($bps > 1000000) {
	return sprintf ("%8.4f M", $bps/1000000);
    } elsif ($bps > 1000) {
	return sprintf ("%9.1fk", $bps/1000);
    } else {
	return sprintf ("%10.0f", $bps);
    }
}

$win->erase ()
    unless $suppress_curses;
my $session =
    ($version eq '1' ? SNMPv1_Session->open ($host, $community, $port, undef, undef, undef, undef, $ipv4_only_p)
     : $version eq '2c' ? SNMPv2c_Session->open ($host, $community, $port, undef, undef, undef, undef, $ipv4_only_p)
     : die "Unknown SNMP version $version")
  || die "Opening SNMP_Session";
$session->debug (1) if $debug;
$use_getbulk_p = 0 if $version eq '1';
$session->{'use_getbulk'} = 0 unless $use_getbulk_p;

### max_repetitions:
###
### We try to be smart about the value of $max_repetitions.  Starting
### with the session default, we use the number of rows in the table
### (returned from map_table_4) to compute the next value.  It should
### be one more than the number of rows in the table, because
### map_table needs an extra set of bindings to detect the end of the
### table.
###
$max_repetitions = $session->default_max_repetitions
    unless $max_repetitions;
while (1) {
    unless ($suppress_output) {
	if ($suppress_curses) {
	    printf STDOUT ("interval: %4.1fs %d reps\n",
			   $interval || $desired_interval,
			   $max_repetitions);
	} else {
	    $win->addstr (0, 0, sprintf ("%-20s interval %4.1fs %d reps",
					 $host,
					 $interval || $desired_interval,
					 $max_repetitions));
	    $win->standout();
	    $win->addstr (1, 0,
			  sprintf (("%5s  %-24s %10s %10s"),
				   "index", "name",
				   "bits/s", "bits/s"));
	    if ($show_out_discards) {
		$win->addstr (sprintf ((" %8s"),
				       "drops/s"));
	    }
	    if ($cisco_p) {
		$win->addstr (sprintf ((" %10s"), "pkts/s"));
	    }
	    $win->addstr (sprintf ((" %s"), "description"));
	    $win->addstr (2, 0,
			  sprintf (("%2s  %-24s %10s %10s"),
				   "", "",
				   "in", "out"));
	    if ($show_out_discards) {
		$win->addstr (sprintf ((" %8s"),
				       ""));
	    }
	    if ($cisco_p) {
		$win->addstr (2, 0,
			      sprintf ((" %10s %s"),
				       "CRC",
				       ""));
	    }
	    $win->clrtoeol ();
	    $win->standend();
	}
    }
    $linecount = 3;
    my @oids;

    if ($switch_engine_p) {
	@oids = (
		 $cseL3SwitchedTotalPkts,
		 $cseL3SwitchedTotalOctets,
		 $cseL3CandidateFlowHits,
		 $cseL3EstablishedFlowHits,
		 $cseL3ActiveFlows,
		 $cseL3FlowLearnFailures,
		 $cseL3IntFlowInvalids,
		 $cseL3ExtFlowInvalids
		 );
    } else {
	@oids = ($ifDescr,$ifAdminStatus,$ifOperStatus);
	if ($counter64_p) {
	    @oids = (@oids,$ifHCInOctets,$ifHCOutOctets);
	} else {
	    @oids = (@oids,$ifInOctets,$ifOutOctets);
	}
	@oids = (@oids,$ifAlias);
	if ($cisco_p) {
	    push @oids, $locIfInCRC;
	}
	if ($show_out_discards) {
	    push @oids, $ifOutDiscards;
	}
    }
    my $calls =
	$switch_engine_p
	? $session->map_table_4
	(\@oids, \&out_switching_engine, $max_repetitions)
	: $session->map_table_4
	(\@oids, \&out_interface, $max_repetitions);
    $win->clrtobot (), $win->refresh ()
	unless $suppress_curses;
    $max_repetitions = $calls + 1
	if $calls > 0;
    $sleep_interval -= ($interval - $desired_interval)
	if defined $interval;
    select (undef, undef, undef, $sleep_interval);
}
1;

sub usage ($) {
    warn <<EOM;
Usage: $0 [-t secs] [-v (1|2c)] [-c] [-l] [-m max] [-4] [-p port] host [community]
       $0 -h

  -h           print this usage message and exit.

  -c           also use Cisco-specific variables (locIfInCrc)

  -l           use 64-bit counters (requires SNMPv2 or higher)

  -t secs      specifies the sampling interval.  Defaults to 5 seconds.

  -v version   can be used to select the SNMP version.  The default
   	       is SNMPv1, which is what most devices support.  If your box
   	       supports SNMPv2c, you should enable this by passing "-v 2c"
   	       to the script.  SNMPv2c is much more efficient for walking
   	       tables, which is what this tool does.

  -B           do not use get-bulk

  -m max       specifies the maxRepetitions value to use in getBulk requests
               (only relevant for SNMPv2c).

  -4           use only IPv4 addresses, even if host also has an IPv6
               address.  Use this for devices that are IPv6-capable
               but whose SNMP agent doesn\'t listen to IPv6 requests.

  -m port      can be used to specify a non-standard UDP port of the SNMP
               agent (the default is UDP port 161).

  host         hostname or IP address of a router

  community    SNMP community string to use.  Defaults to "public".
EOM
    exit (1) if $_[0];
}
