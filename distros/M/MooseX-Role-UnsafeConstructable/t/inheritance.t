#!/usr/bin/env perl

use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib/";

use Parent;
use Parent::Child;
use Uncle;

use Test::Most tests => 9;

for my $class (qw{
	Parent
	Parent::Child
}) {
	can_ok $class, 'unsafe_new';
	is $class->unsafe_class, "$class\::Unsafe";
	ok $class->does('MooseX::Role::UnsafeConstructable');
}

is_deeply
	[sort map { $_->name } Parent::Child::Unsafe->meta->get_all_attributes],
	[qw{child_field parent_field}];

ok ! Uncle->can('unsafe_new');
throws_ok { Uncle::Unsafe->new } qr/\bperhaps you forgot to load "Uncle::Unsafe"/;
