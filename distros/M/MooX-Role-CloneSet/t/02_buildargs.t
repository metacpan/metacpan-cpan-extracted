#!/usr/bin/perl

use v5.12;
use strict;
use warnings;

use Scalar::Util qw(blessed);

use lib 't/lib';
use Test::CloneSet qw(test_something);
use Something::Mutable;

use Test::More 0.98;

plan tests => 2;

subtest 'Plain CloneSet' => sub {
	plan tests => 3;

	my $first = Something::Mutable->new(name => 'giant panda', color => 'black & white');
	test_something 'The original panda',
	    $first, 'giant panda', 'black & white';

	# We are really not supposed to do this with immutable objects,
	# but it's necessary for demonstrating the difference between
	# the two CloneSet roles.
	
	$first->name('another giant panda');
	test_something 'Another panda',
	    $first, 'another giant panda', 'black & white';

	my $second = $first->cset(color => 'see for yourself');
	test_something 'Yet another panda',
	    $second, 'another giant panda', 'see for yourself';
};

subtest 'CloneSet::BuildArgs' => sub {
	my $have_buildargs;
	eval {
		require MooX::BuildArgs;
		$have_buildargs = 1;
	};
	plan skip_all => 'MooX::BuildArgs not installed' unless $have_buildargs;

	require Something::Else;

	plan tests => 3;

	my $first = Something::Else->new(name => 'giant panda', color => 'black & white');
	test_something 'The original panda',
	    $first, 'giant panda', 'black & white';

	# We are really not supposed to do this with immutable objects,
	# but it's necessary for demonstrating the difference between
	# the two CloneSet roles.
	
	$first->name('another giant panda');
	test_something 'Another panda',
	    $first, 'another giant panda', 'black & white';

	my $second = $first->cset(color => 'see for yourself');
	test_something 'Yet another panda',
	    $second, 'giant panda', 'see for yourself';
};
