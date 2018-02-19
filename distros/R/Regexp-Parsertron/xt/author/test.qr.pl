#!/usr/bin/env perl

use strict;
use warnings;

use File::Slurper 'read_lines';

use Try::Tiny;

# -----------------------------

my($count)				= 0;
my($prefix)				= 'xt/author/';
my($input_file_name)	= "$prefix/perl-5.21.11.tests";

my(@result, $re);
my($stdout, $stderr);

for my $s (read_lines($input_file_name) )
{
	$count++;

	try
	{
		($stdout, $stderr, @result) = capture
		{
			$re = qr/$s/;
		};

		print "$re. $count. re: $s. \n";
	};

}

