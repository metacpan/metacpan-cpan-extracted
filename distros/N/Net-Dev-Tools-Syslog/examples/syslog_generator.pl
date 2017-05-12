#!/usr/bin/perl
#
# Perl script to create large amounts of syslog messages
# with differeing PRI (facility, severity) and multiple
# source addresses
# Use random function to generate decimal values for
# an ip address, facility, severity. Convert the facility and severity
# and create a syslog message
#
# Use a flag to output to a file or out on the wire
#

use strict;
use Syslog;
use Time::HiRes qw(sleep);

my ($line,
    $rand_octet, $rand_fac, $rand_sev, $rand_task,
    $ip_addr,
    $facility, $severity, $task, $tag, $message,
    %stats,
    $epoch, $timestamp, $content,
    $send_obj, $error, $ok,
);

my $number_lines = 15000;         # number of syslog line
my $subnet       = '192.168.1';   # ip subnet 
my $host_number  = 20;            # number of host on subnet (0-155)
my $pid          = $$;            # pid for tag

my $preamble     = 1;             # flag to create a log entry with extra info

# logging control
my $log_flag = 1;                 # enable log file creation
my $log;                          # log file filehandle
my $log_file = sprintf("syslog%s_%s_%s.log", $preamble ? '+' : '', $host_number, $number_lines);

# sending (socket) control
my $send_flag = 0;                # enable sending out socket
my $server    = '172.16.1.1';     # syslog server
my $port      = 7971;             # syslog server port
my $proto     = 'udp';            # syslog transport protocol

# time control
my $epoch_flag = 1;               # 0 - get epoch from system time 
                                  # 1 - base epoch, add random num each line
my $sleep      = 0;
my $stat       = 1;



# task lisk to pick from 
my @tasks = qw(tNtp tTelnet tFtp tHttp tSsh tSync tIdle tSystem);

# create send object if sending
if ($send_flag) {
   ($send_obj, $error) = Syslog->send(
      -server    => $server,
      -port      => $port,
      -proto     => $proto,
   );
   unless ($send_obj) {
      printf("ERROR: send object failed: %s\n", $error);
      exit(1);
   }
}

# if log file creation, open file
if ($log_flag) {
   printf("Create log file: %s\n", $log_file);
   open ($log, ">$log_file") || die "ERROR: open log file: $!\n";
}

# get epoch
if ($epoch_flag) {$epoch = time;}

# create the syslog lines
foreach $line (1..$number_lines) {
   # get random numbers
   $rand_octet = int(rand $host_number) + 100;    # subnet.[100-200]
   $rand_fac   = int(rand 24);                    # syslog facility
   $rand_sev   = int(rand 8);                     # syslog severity
   $rand_task  = int(rand 8);                     # pick a tag

   # complete the ip address
   $ip_addr = sprintf("%s.%s", $subnet, $rand_octet);

   # convert decimal values to text strings
   $facility = $Syslog::Facility_Index{$rand_fac} || 23;
   $severity = $Syslog::Severity_Index{$rand_sev} || 7;

   # pick a task for sylog message TAG
   $task = $tasks[$rand_task] || 'tagless';
   $tag = sprintf("%s[%s]:", $task, $pid);

   # incr stats
   $stats{'total'}{'count'}{'all'}++;
   $stats{'total'}{'facility'}{$facility}++;
   $stats{'total'}{'severity'}{$severity}++;
   $stats{'total'}{'task'}{$task}++;

   $stats{'device'}{$ip_addr}{'all'}{'count'}++;
   $stats{'device'}{$ip_addr}{'facility'}{$facility}++;
   $stats{'device'}{$ip_addr}{'severity'}{$severity}++;
   $stats{'device'}{$ip_addr}{'task'}{$task}++;

   # eval to true if you want to see message
   if (0) { 
   printf("Message Values [%s]: ip: %-15s  facility: %2s  severity: %2s  %-20s %s:[%s]\n", 
      $line, $ip_addr, 
      $rand_fac, $rand_sev,
      "$facility.$severity",
      $task, $pid,
   )
   }
   # create timestamp
   # add random number to previous epoch (extends time range)
   if ($epoch_flag) {
      $epoch = $epoch + int(rand 60) + 1;
      $timestamp = epoch_to_syslog_timestamp($epoch);
   }
   # use system time
   else {
       $epoch = time;
       $timestamp = epoch_to_syslog_timestamp($epoch);
   }

   # create content portion of syslog message
   $content = sprintf("created syslog message %s for host %s pri=%s %s.%s",
         $line, $rand_octet,
         ($rand_fac * 8) + $severity,
         $facility, $severity,
   );
   # format vars to crerate syslog message
   $message = sprintf("%s %s %s %s", $timestamp, $ip_addr, $tag, $content); 
   printf("message [%s]: %s\n", $line, $message);

   if ($preamble) {
      $message = sprintf("%s %s.%s %s %s",
                 &preamble_time($epoch), 
                 $facility, $severity, $ip_addr, 
                 $message
      );
   }

   # print to log file if logging
   if ($log_flag) {
     printf $log ("%s\n", $message);
     printf("   log to: line %s to %s\n", $line, $log_file);
   }

   # sendto server if sending enabled
   if ($send_flag) {
      ($ok, $error) = $send_obj->send_msg(
         -facility  => $facility,
         -severity  => $severity,
         -timestamp => $timestamp,
         -device    => $ip_addr,
         -tag       => $tag,
         -pid       => $$,
         -message   => $content,
         -debug     => 0,
      );
      if(!$ok) {
         printf("   ERROR: send_obj->send_msg: %s\n", $error);
      }
      else {
         printf("   sentto: %s:%s %s.%s\n", $server, $port, $facility, $severity);
      } 
   }

   # control loop iteration
   if ($sleep) {
      if ($line != $number_lines)  
         {sleep $sleep}
   }
}
# close log
if ($log_flag) {close($log);}


#
# display stats
#
if ($stat){
printf("\n\n");
printf("Total Counts   %8s\n", $stats{'total'}{'count'}{'all'});
printf("   Facility\n");
foreach $facility (@Syslog::FACILITY) {
   printf("     %-8s  %8s\n", $facility, $stats{'total'}{'facility'}{$facility});  
}
printf("   Severity\n");
foreach $severity (@Syslog::SEVERITY) {
   printf("     %-8s  %8s\n", $severity, $stats{'total'}{'severity'}{$severity});
}
printf("   TAGs\n");
foreach $tag (@tasks) {
   printf("     %-8s  %8s\n", $tag, $stats{'total'}{'task'}{$tag});
}


printf("\n\n");
printf("Device Counts\n",);
foreach $ip_addr (sort keys %{$stats{'device'}}) {
   printf("%-15s   %8s\n", $ip_addr, $stats{'device'}{$ip_addr}{'all'}{'count'});
}
}


exit(0);


#
#=============================================================================
#
# make timestamp for preamble
#  mm-dd-yyyy hh:mm:ss
# $[0] = epoch
# return timestamp
# 
sub preamble_time {

   my @_tokens = localtime($_[0]+1);
   sprintf("%s-%s-%s %02s:%02s:%02s",
      $_tokens[4]+1, $_tokens[3], $_tokens[5]+1900, 
      $_tokens[2], $_tokens[1], $_tokens[0],
   );
}




