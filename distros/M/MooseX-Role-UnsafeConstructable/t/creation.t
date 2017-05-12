#!/usr/bin/env perl

use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/../lib";

use Test::Most tests => 5;

{
	package Foo;
	use Moose;
	with 'MooseX::Role::UnsafeConstructable';

	has val1 => (is => 'ro', isa => 'Str');
	has val2 => (is => 'ro', isa => 'Str');

	__PACKAGE__->meta->make_immutable;
}

my $class = 'Foo';

isa_ok $class->new, $class;
isa_ok $class->unsafe_class->new, $class->unsafe_class;
isa_ok $class->unsafe_new, $class;
isa_ok $class->unsafe_class->new->promote, $class;
is_deeply
	[sort map { $_->name } $class->unsafe_class->meta->get_all_attributes],
	[sort map { $_->name } $class->meta->get_all_attributes];

