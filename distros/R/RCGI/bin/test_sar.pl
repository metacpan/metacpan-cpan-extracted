#!/usr/local/bin/perl
#
#

use lib '.';
use RCGI;

$base_url = shift;
$timeperiod = shift;
if ($base_url =~ /^\s*$/ ||
    $timeperiod !~ /^\d+$/) {
    die "Usage is: $0 'http://machine.wustl.edu/cgi-bin/perlcall.cgi' timeperiod\n";
}
$library_path = '.';
$module = 'SAR';
$subroutine = 'system_activity_report';
# Possible options are:
#   async      -- do an asynchronous call
#   wantarray  -- force array or scalar (usefull for using with async)
#   username   -- username to login to remote web server
#   password   -- password to login to remote web server
#   user_agent -- user_agent to use for remote web server
#   timeout    -- timeout for web call
$remote_subroutine = new RCGI($base_url,$library_path,$module,$subroutine,
			      'timeout' => 4000);


@my_result = $remote_subroutine->Call($timeperiod);
$, = "\t";
if ($remote_subroutine->Success()) {
    print @my_result;
    print "\n";
} else {
    print STDERR "Call to " . $remote_subroutine->Base_URL() .
	" failed with status: " . $remote_subroutine->Status() .
	    ' ' . $remote_subroutine->Error_Message() . "\n";
}

