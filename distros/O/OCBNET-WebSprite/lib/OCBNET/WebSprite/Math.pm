###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
####################################################################################################
# static helper functions for canvas
####################################################################################################
package OCBNET::WebSprite::Math;
####################################################################################################
our $VERSION = '1.0.0';
####################################################################################################

use strict;
use warnings;

###################################################################################################

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter); }

# define our functions to be exported
BEGIN { our @EXPORT_OK = qw(lcm gcf snap factors); }

####################################################################################################

# try to optimize slow functions
# with memoize oly if available
# eval
# {
# 	# try to load
# 	use Memoize qw(memoize);
# 	# memoize functions
# 	memoize('gcf', LIST_CACHE => 'MERGE');
# 	memoize('lcm', LIST_CACHE => 'MERGE');
# 	memoize('multigcf', LIST_CACHE => 'MERGE');
# 	memoize('multilcm', LIST_CACHE => 'MERGE');
# };

####################################################################################################
# stolen from http://www.perlmonks.org/?node_id=56906
####################################################################################################

# greatest common factor
sub _gcf($$)
{
	my ($x, $y) = @_;
	($x, $y) = ($y, $x % $y) while $y;
	return $x;
}

# least common multiple
sub _lcm($$)
{
	return $_[0] * $_[1] / _gcf($_[0], $_[1]);
}

# greatest common factor
sub gcf(@)
{
	my $x = shift;
	$x = _gcf($x, shift) while @_;
	return $x;
}

# least common multiple
sub lcm(@)
{
	my $x = shift;
	$x = _lcm($x, shift) while @_;
	return $x;
}

####################################################################################################

# snap value to given multiplier
# ******************************************************************************
sub snap
{
	# get rest by modulo divide
	my $rest = $_[0] % $_[1];
	# add rest to fill up to multipler
	$_[0] += $rest ? $_[1] - $rest : 0;
}
# EO sub snap

####################################################################################################

# private helper function
# returns all prime factors
# we shouldn't need many!
# ******************************************************************************
sub factors
{

	# hold all factors
	my @primes;

	# get number to factorize
	my ($number) = @_;

	# loop from 2 up to number
	for ( my $y = 2; $y <= $number; $y ++ )
	{
		# skip if not a factor
		next if $number % $y;
		# divide by factor found
		$number /= $y;
		# store found factor
		push(@primes, $y);
		# restart from 2
		redo;
	}

	# sort the prime factors
	return sort @primes;

};
# EO sub factors

####################################################################################################
####################################################################################################
1;
