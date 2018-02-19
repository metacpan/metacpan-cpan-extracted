#!/usr/bin/env perl

use strict;
use warnings;

use Regexp::Parsertron;

# ------------------------------------------------

my($parser)	= Regexp::Parsertron -> new(verbose => 2);
#my($re)	= qr/(?(?!\x{100})b|\x{100})/;
#my($s)		= '\x{100}';
my($re)		= qr/^/;
my($s)		= 'anything';

if ($s =~ $re)
{
	print "'$s' matches $re \n";
}
else
{
	print "'$s' does not match $re \n";
}
