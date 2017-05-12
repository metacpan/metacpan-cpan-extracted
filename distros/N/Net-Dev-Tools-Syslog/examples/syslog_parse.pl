#!/usr/bin/perl
#
# Perl script to test Net::Dev::Tools::Syslog parsing
#
#

use strict;
use Net::Dev::Tools::Syslog;

# get sylog file from cli 
my $syslog_file = shift || die "usage: $0 <syslog file>\n";

my ($syslog_obj, $error,
    $parse_href,
    $report_href,
    $fh,
    $device, $tag, $facility, $severity,
);

# create syslog parsing object
($syslog_obj, $error) = Syslog->parse(
   -report    => 1,
   -parseTag  => 1,
   -dump      => './somepath',
   -debug     => 0,
   -moreTime  => 1,
   -format    => 'noHost',
);

unless ($syslog_obj) {
   printf("sylog object constructor failed: %s\n", $error);
   exit(1);
}

# open syslog file to parse
printf("parse syslog file: %s\n", $syslog_file);
open ($fh, "$syslog_file") || die "ERROR: open failed: $!\n";
while(<$fh>) {
   ($parse_href, $error) = $syslog_obj->parse_syslog_line($_);
   unless ($parse_href) {
      printf("ERROR: line %s: %s\n", $., $error);
   }
}
close($fh);
printf("parse syslog file done: %s lines\n", $.);

# convert epoch time in report hash
&syslog_stats_epoch2datestr;

# reference report hash and display
$report_href = &syslog_stats_href;

# stats for entire syslog file
printf("Syslog:  messages %s   %s -> %s\n\n\n",
   $report_href->{'syslog'}{'messages'},
   $report_href->{'syslog'}{'min_date_str'},
   $report_href->{'syslog'}{'max_date_str'},
);

# stats for each device found in syslog
foreach $device (keys %{$report_href->{'device'}}) {
   printf("Device: %s  messages: %s   %s -> %s\n", 
      $device, 
      $report_href->{'device'}{$device}{'messages'},
      $report_href->{'device'}{$device}{'min_date_str'},
      $report_href->{'device'}{$device}{'max_date_str'},
   );
   printf("   Tags:\n",);
   foreach $tag (keys %{$report_href->{'device'}{$device}{'tag'}}) {
      printf("     %8s %s\n", 
         $report_href->{'device'}{$device}{'tag'}{$tag}{'messages'}, $tag
      );  
   }
   printf("   Facility:\n",);
   foreach $facility (keys %{$report_href->{'device'}{$device}{'facility'}}) {
      printf("     %8s %s\n", 
         $report_href->{'device'}{$device}{'facility'}{$facility}{'messages'}, 
         $facility
      );
   }
   printf("   Severity:\n",);
   foreach $severity (keys %{$report_href->{'device'}{$device}{'severity'}}) {
      printf("     %8s %s\n", 
         $report_href->{'device'}{$device}{'severity'}{$severity}{'messages'}, 
         $severity
      );
   }
   printf("\n");
}

exit(0);
