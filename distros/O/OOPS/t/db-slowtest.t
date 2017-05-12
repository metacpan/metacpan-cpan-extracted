#!/usr/bin/perl -I../lib

BEGIN {
	no warnings;
	$OOPS::SelfFilter::defeat = 1;
}

use FindBin;
require "$FindBin::Bin/slowtest.t";

1;
