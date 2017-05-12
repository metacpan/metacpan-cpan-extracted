#!/usr/bin/perl -I../lib

BEGIN {
	no warnings;
	$OOPS::SelfFilter::defeat = 0;
}

$ENV{OOPSTEST_SLOW} = 1; 

use FindBin;
require "$FindBin::Bin/integrety.t";

1;
