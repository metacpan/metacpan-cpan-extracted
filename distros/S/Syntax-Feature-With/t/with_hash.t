#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use Syntax::Feature::With qw(with_hash);

# with_hash using %hash
{
	my %h = ( a => 10 );
	my $a;

	my $result = with_hash %h => sub { $a };

	is($result, 10, 'with_hash %h works');
}

# with_hash using \%hash
{
	my %h = ( x => 99 );
	my $x;

	my $result = with_hash \%h, sub { $x };

	is($result, 99, 'with_hash \\%h works');
}

# with_hash + flags
{
	my %h = ( a => 1 );
	my $a;

	my $result = with_hash -strict => %h => sub { $a };

	is($result, 1, 'with_hash supports flags');
}

done_testing();
