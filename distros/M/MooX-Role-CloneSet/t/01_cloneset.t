#!/usr/bin/perl
# SPDX-FileCopyrightText: Peter Pentchev <roam@ringlet.net>
# SPDX-License-Identifier: Artistic-2.0

use 5.012;
use strict;
use warnings;

use Scalar::Util qw(blessed);

use lib 't/lib';
use Test::CloneSet qw(test_something);
use Something;

use Test::More 0.98;

our $VERSION = v0.1.0;

plan tests => 4;

my $first = Something->new( name => 'giant panda', color => 'black & white' );
test_something 'The original panda', $first, 'giant panda', 'black & white';

my $intermediate = $first->cset( color => 'reddish-brown' );
test_something 'A weird animal with an identity crisis',
	$intermediate, 'giant panda', 'reddish-brown';

my $final = $intermediate->cset( name => 'red panda' );
test_something 'The cute and cuddly fox-like thing', $final, 'red panda', 'reddish-brown';

my $else = $intermediate->cset( name => 'mimic octopus', color => 'whatever you like' );
test_something 'And now for something completely different',
	$else, 'mimic octopus', 'whatever you like';
