#!/usr/local/bin/perl 

use Register;


printf "Testing Register\:\:Generic\n";
my($r)=new Register::Generic 
	(
	'regpath' => ".",
	'regname' => "INIFILE"
	);

$r->savesettings("FOO","BOR",10);   
$r->savesettings("FAA","BAR",10);   
$r->savesettings("FEE","BAR",10);   
$r->savesettings("FOO","BAR",10);   
foreach($r->getsections) { printf $_."\n" };
