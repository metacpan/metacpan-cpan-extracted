#!/usr/bin/perl
# SPDX-FileCopyrightText: Peter Pentchev <roam@ringlet.net>
# SPDX-License-Identifier: Artistic-2.0

use 5.012;
use strict;
use warnings;

use English      qw(-no_match_vars);
use Scalar::Util qw(blessed);

use lib 't/lib';
use Test::CloneSet qw(test_something);
use Something::Mutable;

use Test::More 0.98;

our $VERSION = v0.1.0;

plan tests => 2;

subtest 'Plain CloneSet' => sub {
	plan tests => 3;

	my $panda =
		Something::Mutable->new( name => 'giant panda', color => 'black & white' );
	test_something 'The original panda', $panda, 'giant panda', 'black & white';

	# We are really not supposed to do this with immutable objects,
	# but it's necessary for demonstrating the difference between
	# the two CloneSet roles.

	$panda->name('another giant panda');
	test_something 'Another panda', $panda, 'another giant panda', 'black & white';

	my $another_panda = $panda->cset( color => 'see for yourself' );
	test_something 'Yet another panda',
		$another_panda, 'another giant panda', 'see for yourself';
};

subtest 'CloneSet::BuildArgs' => sub {
	if (
		!eval {
			require MooX::BuildArgs;
			1;
		}
		)
	{
		plan skip_all => 'MooX::BuildArgs not installed';
	}

	require Something::Else;

	plan tests => 3;

	my $panda = Something::Else->new( name => 'giant panda', color => 'black & white' );
	test_something 'The original panda', $panda, 'giant panda', 'black & white';

	# We are really not supposed to do this with immutable objects,
	# but it's necessary for demonstrating the difference between
	# the two CloneSet roles.

	$panda->name('another giant panda');
	test_something 'Another panda', $panda, 'another giant panda', 'black & white';

	my $another_panda = $panda->cset( color => 'see for yourself' );
	test_something 'Yet another panda', $another_panda, 'giant panda',
		'see for yourself';
};
