#!/usr/bin/perl -w

use strict;
use Net::Dev::Tools::SyslogMessage;

my $MSG = '<123>Feb  3 19:14:11 localhost program[1234]: Message test';
my $msg = syslog_parseMessage($MSG);
print STDOUT "$MSG\n";
print STDOUT "------------------------------\n";
syslog_dumpMessage(\*STDOUT, $msg);
print STDOUT "==============================\n\n";

$MSG = '<34>Oct 11 22:14:15 mymachine su: \'su root\' failed for lonvick on /dev/pts/8';
$msg = syslog_parseMessage($MSG);
print STDOUT $MSG."\n";
print STDOUT "------------------------------\n";
syslog_dumpMessage(\*STDOUT, $msg);
print STDOUT "==============================\n\n";

$MSG = '<13>Feb  5 17:32:18 10.0.0.99 Use the BFG!';
$msg = syslog_parseMessage($MSG);
print STDOUT $MSG."\n";
print STDOUT "------------------------------\n";
syslog_dumpMessage(\*STDOUT, $msg);
print STDOUT "==============================\n\n";

$MSG = '<165>Aug 24 05:34:00 CST 1987 mymachine myproc[10]: %% It\'s time to make the do-nuts.  %%  Ingredients: Mix=OK, Jelly=OK # Devices: Mixer=OK, Jelly_Injector=OK, Frier=OK # Transport: Conveyer1=OK, Conveyer2=OK # %%';
$msg = syslog_parseMessage($MSG);
print STDOUT $MSG."\n";
print STDOUT "------------------------------\n";
syslog_dumpMessage(\*STDOUT, $msg);
print STDOUT "==============================\n\n";

exit(0);

