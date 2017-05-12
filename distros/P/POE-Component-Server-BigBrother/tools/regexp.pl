#!/usr/bin/perl

use strict;
use Regexp::Assemble;

my $ra = Regexp::Assemble->new;

my @commands = qw( status enable disable page );

foreach (@commands) {
	$ra->add( $_ );
}

print $ra->re,$/;
