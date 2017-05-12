#!/usr/bin/env perl

use strict;
use warnings;

use String::Interpolate::Delayed;

my $title = delayed "Lord of the $what\n";

my $what = "Rings";
print $title;

our $what = "Flies";
print $title;

{
	my $what = "Dance";
	print $title;
}
