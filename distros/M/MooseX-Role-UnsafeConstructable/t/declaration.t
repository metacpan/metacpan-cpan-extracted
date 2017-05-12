#!/usr/bin/env perl

use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/../lib";

use Test::Most tests => 6;

{
	package Foo;
	use Moose;
	with 'MooseX::Role::UnsafeConstructable';
}

my $class = 'Foo';

is $class->unsafe_class, "$class\::Unsafe";
throws_ok { $class->unsafe_class->new } qr/\bperhaps you forgot to load "${\( $class->unsafe_class )}"/;
lives_ok { $class->declare_unsafe_class };
lives_ok { $class->declare_unsafe_class } 'declare_unsafe_class is safe to call multiple times';
lives_ok { $class->unsafe_class->new };
isa_ok $class->unsafe_class->new, $class->unsafe_class;
