#!/usr/bin/perl -I../lib

BEGIN {
	no warnings;
	$OOPS::SelfFilter::defeat = 0;
}

use FindBin;
require "$FindBin::Bin/front_end.t";

1;
