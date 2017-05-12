#!/usr/bin/perl -w

use strict;
use Parse::DMIDecode ();

my $dmi = new Parse::DMIDecode;
$dmi->probe;

printf("System: %s, %s\n",
		$dmi->keyword("system-manufacturer"),
		$dmi->keyword("system-product-name"),
	);

