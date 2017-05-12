#!/usr/bin/perl -w
use strict;
use Test;

use lib '../lib';
use lib 'lib';

use Sys::Hostname::Long;

format STDOUT_TOP =
Method           |Title                            |Result
-----------------|---------------------------------|---------------------------------------
.

my ($method, $title, $ret);

format STDOUT =
@<<<<<<<<<<<<<<<<|@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<|@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$method, $title, $ret
.


$ret = hostname_long();
$method = "AUTOMATIC";
$title = "via " . $Sys::Hostname::Long::lastdispatch;
write;

foreach $method (Sys::Hostname::Long::dispatch_keys()) {
	$title = Sys::Hostname::Long::dispatch_title($method);
	$ret = (Sys::Hostname::Long::dispatcher($method) || ""); 
	write;
}
