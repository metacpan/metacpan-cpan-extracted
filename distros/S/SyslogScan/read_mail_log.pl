#!/usr/bin/perl5
#-
#-read_mail_log.pl:  Prints a summary of mail routed through system to STDOUT
#-
#-  Performance note:  summarizing 3 megabytes of sendmail logs
#-  takes about 5 minutes and uses about 7 megabytes of virtual memory
#-  (2 megabytes to run perl5 and the program, plus 5 mb of internal
#-  data structures.)
#-
#-Usage:
#-         $0 [-ugm] [-o cache_outfile]
#-            [-U user_filter] [-T date_filter]
#-            [-y year]
#-            [-hvqD] [-i cache_in | syslog ...]
#-
#-Where:
#-             -u : print report grouped by user (default)
#-             -g : print report grouped by internet domain name
#-             -m : print report of mail deliveries
#-   -o cache_out : store mail deliveries to cache-file "cache_out"
#-
#- -U user_filter : only summarize mail involving certain users
#- -T date_filter : only summarize mail delivered in a certain time-range
#-
#-
#-        -y year : supply year syslogs were written
#-             -q : quiet mode (suppress parsing errors and commentary)
#-    -i cache_in : read in deliveries from cache-file "cache_in"
#-      syslog ...: name of logs to scan (default is to use
#-                  log which mail.info messages currently go to)
#-
#-             -h : print this help message and exit
#-             -v : print the version number and exit
#-             -D : print debugging information
#-
#
#   Version:  0.23
#   Author: Rolf Nelson
#

require 5.002;   #need perl5.002 or later

use SyslogScan::WhereIs;
use SyslogScan::DeliveryIterator;
use SyslogScan::Summary;
use SyslogScan::ByGroup;

use Getopt::Std;
use strict;

sub inform;

&procOpts();

# set at getopts() time by T:U: flags
my ($startDate, $endDate) = ($::gStartDate, $::gEndDate);
my ($selfPattern, $otherPattern) = ($::gSelfPattern, $::gOtherPattern);
my $deliveryYear = $::gYear;

# set at getopts() time by gudo:i: flags
my ($reportByGroup, $reportByUser, $reportByDelivery, $cacheOut, $cacheIn) =
    ($::gReportByGroup, $::gReportByUser, $::gReportByDelivery,
     $::gCacheOut, $::gCacheIn);

my @syslogList = @ARGV;
if (! @syslogList and ! defined $cacheIn)
{
    my $file = SyslogScan::WhereIs::guess('/etc/syslog.conf');
    @syslogList = ($file);
}

if (defined $cacheIn)
{
    inform "reading in deliveries from cached file $cacheIn\n";
    open(CACHE_IN,$cacheIn) or die "could not open $cacheIn: $!";
}
else
{
    inform "Scanning ", join(' ',@syslogList), " for deliveries";
    if (defined $startDate)
    {
	inform "\n  which were delivered on or after " .
	    localtime($startDate);
	inform "\n  AND which were delivered strictly before " .
	    localtime($endDate)  ;
    }
    inform "...\n";
}

if (defined $cacheOut)
{
    inform "writing deliveries out to cache file $cacheOut\n";
    (-e $cacheOut and die "cache-file $cacheOut already exists, bye");
    open(CACHE_OUT,">$cacheOut") or die "could not write to $cacheOut";
}

my $iter = new SyslogScan::DeliveryIterator ('unknownSender' => 'antiquity',
					     'unknownSize' => 0,
					     'startDate' => $startDate,
					     'endDate' => $endDate,
					     'defaultYear' => $deliveryYear);
my $syslog;
foreach $syslog (@syslogList)
{
    $iter -> appendSyslog($syslog);
}

inform "Each . is a registered delivery:\n" unless $reportByDelivery;

my $summary = new SyslogScan::Summary();
while (1)
{
    my $delivery;
    if (defined $cacheIn)
    {
	$delivery = SyslogScan::Delivery -> restore(\*CACHE_IN);
    }
    else
    {
	$delivery = $iter -> next;
    }
    last unless $delivery;

    if ($reportByGroup or $reportByUser)
    {
	$summary -> registerDelivery($delivery,$selfPattern,$otherPattern);
    }
    if (defined $cacheOut)
    {
	$delivery -> persist(\*CACHE_OUT);
    }

    if ($reportByDelivery)
    {
	print $delivery -> summary();
    }
    else
    {
	inform ".";
    }
}

if ($reportByDelivery)
{
    inform "\nReport by delivery finished successfully.\n\n";
}

if ($reportByUser)
{
    inform "\nGenerating report by user-name...\n";
    &printSummaryReport($summary);
}

if ($reportByGroup)
{
    inform "Grouping by domain name (could take a while)...\n";

    my $byGroup = new SyslogScan::ByGroup($summary);
    inform "...finished grouping by domain name.\n";

    inform "\nSorting domain names...\n";

    my $domainName;
    foreach $domainName (sort keys %$byGroup)
    {
	my $group = $$byGroup{$domainName};
	&printUsageReport($$group{groupUsage},"$domainName TOTAL");
	&printSummaryReport($$group{byAddress});
	print "\n";
    }
}

inform "\n$0 finished executing sucessfully.\n";
exit 0;

sub printSummaryReport
{
    my $summary = shift;
    
    my $address;
    foreach $address (sort keys %$summary)
    {
	my $usage = $$summary{$address};
	&printUsageReport($usage,$address);
    }
}

sub printUsageReport
{
    my $usage = shift;
    my $name = shift;
    
    my $broadcastVolume = $usage -> getBroadcastVolume();
    my $receiveVolume = $usage -> getReceiveVolume();
 
    print "$name: ";
    &printVolumeReport($broadcastVolume,"bcast");
    print ", ";
    &printVolumeReport($receiveVolume,"rcvd");
    print "\n";
}

sub printVolumeReport
{
    my $volume = shift;
    my $tag = shift;

    print "$$volume[0] msgs/$$volume[1] bytes $tag";
}

sub inform
{
    print STDERR @_
	unless $::opt_q;
}

#----------------------------------------------------------------
# procOpts:  process command-line options
#----------------------------------------------------------------
sub procOpts
{
    ($::opt_v, $::opt_h, $::opt_D) = ();  #avoid warning message
    getopts('hvDgi:mo:quy:T:U:') || &showUsage("bad command switches");
    &d();
    $::opt_h && &showUsage();
    $::opt_v && &showVersion();
    $::opt_q and $::gbQuiet = 1;

    # check for incompatibilities
    if ($::opt_m or defined $::opt_c)
    {
	(defined $::opt_U) and &showUsage("-m|-c incompatible with -U, sorry");
    }
    if ($::opt_i)
    {
	@ARGV and &showUsage("-i incompatible with <syslog ...>");
	(defined $::opt_T) and
	    &showUsage("-i incompatible with -T; please time-filter while cacheing");
    }

    if (! $::opt_g and ! $::opt_m and ! $::opt_u and ! defined $::opt_c)
    {
	$::opt_u = 1;
	inform "Using default -u option\n\n";
    }

    ($::gReportByGroup, $::gReportByUser, $::gReportByDelivery,
     $::gCacheOut, $::gCacheIn) =
	($::opt_g, $::opt_u, $::opt_m, $::opt_o, $::opt_i);

    $::gYear = $::opt_y;

    &populateGlobalTimeFilter($::opt_T) if defined($::opt_T);
    &populateGlobalUserFilter($::opt_U) if defined($::opt_U);
}   

sub populateGlobalUserFilter
{
    my $userFilter = shift;  # $::opt_U

    my ($selfSwitch, $notOtherSwitch, $otherSwitch);
    
    if ($::opt_U =~ /(.+):NOT:(.+)/i)
    {
	$selfSwitch = $1;
	$notOtherSwitch = $2;
    }
    else
    {
	$selfSwitch = $::opt_U;
    }
    $selfSwitch =~ s/\./\\\./g;
    $selfSwitch .= '$';              # end ' emacs format
    
    my $otherSwitch;
    if (defined ($notOtherSwitch))
    {
	$notOtherSwitch =~ s/\./\\\./g;      # escape for pattern
	$notOtherSwitch .= '$';              # end ' emacs format
	
	$otherSwitch = '^(?!.*' . $notOtherSwitch . '$)';  #reverse pattern
    }
    
    $::gSelfPattern = $selfSwitch;
    $::gOtherPattern = $otherSwitch;
}

sub populateGlobalTimeFilter
{
    my $timeFilter = shift;   # $::opt_T

    if ($timeFilter =~ /(\d+)\.(\d+)\.(\d+)/)
    {
	my ($mon, $day, $year) = ($1, $2, $3);
	require 'timelocal.pl';
	
	$year =~ s/^19(\d\d)$/$1/;
	$year =~ s/^20(\d\d)$/1$1/;
	$::gStartDate = timelocal(0,0,0,$day,$mon-1,$year);
	$::gEndDate = $::gStartDate + 24 * 60 * 60;
    }
    elsif ($timeFilter =~ /^(\d+)\.\.(\d+)$/)
    {
	$::gStartDate = $1;
	$::gEndDate = $2;
    }
    else
    {
	&showUsage("bad -T date format: $timeFilter");
    }
}

#----------------------------------------------------------------
# showUsage : display a usage string, then exit.
#----------------------------------------------------------------
sub showUsage
{
    my $errMsg = shift;
    if ($errMsg ne "")
    {
	print STDERR "Usage error: $errMsg\n\n";
    }

    seek(DATA,0,0);
    while (<DATA>)
    {
	if (s/^\#\-//)
	{
	    s/\$0/$0/;
	    print STDERR $_ unless /^\-/;
	}
    }

    exit ($errMsg ne "");
}

#----------------------------------------------------------------
# showVersion : print Version and exit.
#----------------------------------------------------------------
sub showVersion
{
    seek(DATA,0,0);
    while (<DATA>)
    {
	print STDERR $_ if /\s+Version:/;
    }

    exit(0);
}

#----------------------------------------------------------------
# d : print debugging message if -D verbose flag is on.
#----------------------------------------------------------------
sub d
{
    return unless $::opt_D;
    my $msg = shift;
    if ($msg eq "")
    {					       
	print STDERR "found -D flag; running $0 in verbose DEBUG mode.\n";
    }
    else
    {
	print STDERR $msg, "\n";
    }
}

__END__

=head1 NAME

read_mail_log.pl -- Summarizes amount of mail routed through host,
sorted by e-mail address

=head1 SYNOPSIS

 # summarize mail from syslog by user-name
 % read_mail_log.pl
 # which, if your mail loging goes to /var/log/syslog, is equivalent to:
 % read_mail_log.pl -u /var/log/syslog

 # summarize mail by internet domain name from /var/log/syslog,
 # suppressing parse errors
 % read_mail_log.pl -q -g /var/log/syslog

 # summarize mail by mail deliveries, filtering out mail which
 # was not delivered on September 18 1996
 % read_mail_log.pl -m -T 9.18.1996 /var/log/syslog 

 # cache mail deliveries to file ./syslog.cache
 % read_mail_log.pl -o syslog.cache /var/log/syslog

 # now read deliveries in from cache, and summarize the usage
 # of all users at your domain
 % read_mail_log.pl -i syslog.cache -U `hostname -d`

 # now summarize the usage of all users at foo.com, not counting
 # mail sent to/from bar.com
 % read_mail_log.pl -i syslog.cache -U foo.com:NOT:bar.com

=head1 DESCRIPTION

  Usage:

        read_mail_log.pl [-ugm] [-o cache_outfile]
              [-U user_filter] [-T date_filter]
              [-hvqD] [-i cache_in | syslog ...]
  
  Where:
               -u : print report grouped by user (default)
               -g : print report grouped by internet domain name
               -m : print report of mail deliveries
     -o cache_out : store mail deliveries to cache-file "cache_out"
  
   -U user_filter : only summarize mail involving certain users
   -T date_filter : only summarize mail delivered in a certain time-range
  
               -q : quiet mode (suppress parsing errors and commentary)
      -i cache_in : read in deliveries from cache-file "cache_in"
        syslog ...: name of logs to scan (default is to use
                    log which mail.info messages currently go to)
  
               -h : print this help message and exit
               -v : print the version number and exit
               -D : print debugging information

=head2 CACHES

To save time for multiple reports, you can cache the deliveries
generated from an execution of read_mail_log.pl with the C<-o> flag.
The cachefile specified may not already exist.

Subsequent executions can read in the information from the cachefile
and increase the executation rate by a factor of about 10.

=head2 FILTERS

There are two legal formats for user filters:

     -U foo.com      (summarizes mail foo.com users sent or delivered)
     -U foo.com:NOT:bar.com (summarizes mail foo.com users sent or delivered
                          to users who are _not_ at bar.com)

There are two legal format for date filters:

     -T 9.14.1996
     -T 845251200..845337600  

Both these filters will process only mail successfully delivered on
Sept. 14, 1996.  The second format allows you to specify any two
bounding time_t values such as those produced by timelocal.pl.

=head2 HOW CACHES AND FILTERS INTERACT

The C<-T> date/time filter should only act upon the data as it is
generated from a syslog file.  Using the C<-T> filter when reading
from a cachefile is not allowed.

The C<-U> address/user filter should only act upon the data as it is
being generated into a user or domain summary.  Using the C<-U> filter
when writing to a cachefile or when generating only a list of
deliveries is not allowed.

So, these two lines are legal and will generate a summary of mail sent
and received by users at mydomain.org on 9.18.1996:

 read_mail_log.pl -T 9.18.1996 -o /tmp/syslog.cache /var/log/syslog
 read_mail_log.pl -u -U mydomain.org -i /tmp/syslog.cache

But neither of these lines is currently legal:

 read_mail_log.pl -U mydomain.org -o /tmp/syslog.cache /var/log/syslog
 read_mail_log.pl -u -T 9.18.1996 -i /tmp/syslog.cache

=head1 PERFORMANCE

Expect processing mail deliveries to take about 90 sec/megabyte of
mail log-lines.  If you expect to run multiple reports, consider
cacheing your syslog with the C<-o> switch.

 > ls -lL syslog.960801
 -rw-r--r--   1 rolf     30        2364752 Aug  5 18:58 syslog.960801

 > time read_mail_log.pl -m -o /tmp/syslog.cache syslog.960801 > /dev/null 2>&1
 184.226s real  178.220s user  1.560s system  97%

 > cat big_file > /dev/null  # clear out cache for performance test

 > time read_mail_log.pl -m -i /tmp/syslog.cache > /dev/null 2>&1
 17.801s real  14.540s user  0.530s system  84%

Summarizing mail by delivery takes up constant memory.  Summarizing by
user-name takes up O(n) memory; expect roughly 1 extra megabyte of
virtual memory usage per megabyte of syslog file.

=head1 AUTHOR and COPYRIGHT

The author (Rolf Nelson) can currently be e-mailed as
rolf@usa.healthnet.org.

This code is Copyright (C) SatelLife, Inc. 1996.  All rights reserved.
This code is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

In no event shall SatelLife be liable to any party for direct,
indirect, special, incidental, or consequential damages arising out of
the use of this software and its documentation (including, but not
limited to, lost profits) even if the authors have been advised of the
possibility of such damage.

=head1 SEE ALSO

L<SyslogScan::DeliveryIterator>, L<SyslogScan::Summary>,
L<SyslogScan::WhereIs>
