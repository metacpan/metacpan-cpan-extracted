#!/usr/bin/perl -Ilib
#-------------------------------------------------------------------------------
# Trim leading and trailing space from strings.
# Mike Limberger, 2021
#-------------------------------------------------------------------------------
use warnings FATAL => qw(all);
use strict;
use Carp;
use Test::More tests=>3;
use feature qw(say state current_sub);
use String::Trim::Regex qw(trim);

# Undef test
if (1)                                                                          
{
	 my $s;
	 eval { trim($s) };
	 ok $@ =~ m~^String needs to be defined\.~;
}

# Leading whitespace test
if (1)                                                                          
{
	 my $s = q[ wow];
	 is_deeply trim($s), q[wow];	 
}
 
# Leading & trailing whitespace test
if (1)                                                                          
{
	 my $s = q[ wow    ];
	 is_deeply trim($s), q[wow];	 
}
