#!/usr/bin/perl -w

use warnings;
use strict;


use Stlgen;

my $inst = Stlgen->New(
	Template=>'list', 
	Instancename => 'uint',
	payload => [
		{name=>'uint',   type=>'unsigned int', dumper=>'printf("\t\tuint = %u\n", currelement->uint);'},
	],
);

$inst->Instantiate();

