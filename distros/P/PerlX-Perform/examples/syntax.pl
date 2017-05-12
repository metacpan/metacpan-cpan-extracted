#!/usr/bin/perl

use 5.010;
use strict;
use syntax qw(function perform);

fun announce ($str)
{
	chomp $str;
	say ">>> $str";
}

perform { announce ($_) } wherever 1;
perform { announce ($_) } wherever undef;
perform { announce ($_) } wherever 2;
perform { announce ($_) } wherever 3;
