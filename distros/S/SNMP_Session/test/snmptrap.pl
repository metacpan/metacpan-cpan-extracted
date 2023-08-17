#! /usr/local/bin/perl5
# -*- mode: Perl -*-
BEGIN{
$main::OS = 'UNIX';
#$main::OS = 'NT';
#$main::OS = 'VMS';
##################################################################
   # The path separator is a slash, backslash or semicolon, depending
   # on the platform.
   $main::SL = {
     UNIX=>'/',
     WINDOWS=>'\\',
     NT=>'\\',
     VMS=>''
     }->{$main::OS};

   # The search path separator is a colon or semicolon depending on the
   # operating system.
   $main::PS = {
     UNIX=>':',
     WINDOWS=>';',
     NT=>';',
     VMS=>':'
     }->{$main::OS};

  # We need to find the place where this is installed, and
  # then take the .pm programms from there.
  $main::binpath ="";
  if ($0 =~ /^(.+\Q${main::SL}\E)/) {
    $main::binpath="$1";
  } else {
    foreach $pathname ( split ${main::PS}, $ENV{'PATH'}) {
      if ((($main::OS eq 'NT') &&
           (-e "$pathname${main::SL}$0")) ||
           (-x "$pathname${main::SL}$0")) {
	$main::binpath=$pathname;
  	last;
      }
    }
  }
  die "ERROR: Can\'t find location of mrtg executable\n" 
    unless $main::binpath; 
  unshift (@INC,$main::binpath);
}

# The older perls tend to behave peculiar with
# large integers ... 
require 5.003;

if ($main::OS eq 'UNIX' || $main::OS eq 'NT') {
    use SNMP_util "0.54";
    $main::SNMPDEBUG =0;
}

use strict;

$main::DEBUG=0;

sub main {
  
  my($trapid, $sev, $message);
  my($machine, $ret);
  # unbuffer stdout to see everything immediately
  $|=1 if $main::DEBUG;   

  $trapid = 1100;
  $sev = "Major";
  $message = "MCM -- I'm testing, please ignore";
  $machine = `hostname` ;
  chop($machine);

  $ret = &snmptrap("dizzy.unx.sas.com", "",
		"1.3.6.1.4.1.11.2.17.1", $machine, 6, $trapid, 
		"1.3.6.1.4.1.11.2.17.2.1.0", "Integer", 14,
		"1.3.6.1.4.1.11.2.17.2.2.0", "OctetString", $machine,
		"1.3.6.1.4.1.11.2.17.2.4.0", "OctetString", $message,
		"1.3.6.1.4.1.11.2.17.2.5.0", "OctetString", $sev);

  print "ret = <$ret>\n";
}

main;
exit(0);
