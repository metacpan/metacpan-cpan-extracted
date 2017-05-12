#!/usr/bin/perl -T
use strict;
use warnings;

use Test::More 0.88; # for done_testing
use Sub::ArgShortcut::Attr;

sub original() { 'original' }
sub modified() { 'modified' }

sub _test : ArgShortcut { $_ = modified for @_ };

{
	local $_ = original;
	_test;
	is( $_, modified, 'in-place on $_' );
}

{
	local $_ = original;
	my $res = _test;
	is( $_,   original, 'nondestructive from $_' );
	is( $res, modified, '...returned correctly' );
}

{
	my $num = 10;
	my @original = ( original ) x $num;
	my @modified = ( modified ) x $num;
	_test( my @data = @original );
	is_deeply( \@data, \@modified, 'in-place on params' );
}

{
	my $num = 10;
	my @original = ( original ) x $num;
	my @modified = ( modified ) x $num;
	my @res = _test( my @data = @original );
	is_deeply( \@data, \@original, 'non-destructive from params' );
	is_deeply( \@res,  \@modified, '...returned correctly' );
}

done_testing;
