#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use Benchmark qw{cmpthese};

use lib "$FindBin::Bin/../lib";

{
	package Foo;
	use Moose;
	with 'MooseX::Role::UnsafeConstructable';

	has val1 => (is => 'ro', isa => 'Str');
	has val2 => (is => 'ro', isa => 'Str', default => 'mom');
	has val3 => (is => 'ro', isa => 'Str', default => sub { 'dad' });
	has val4 => (is => 'ro', isa => 'Str', builder => '_build_val4');
	has val5 => (is => 'ro', isa => 'Str', init_arg => undef);
	has _val6 => (is => 'ro', isa => 'Str', init_arg => 'val6');

	sub _build_val4 { 'bro' }

	__PACKAGE__->meta->make_immutable;
}

{
	package Bar;
	use Moose;
	with 'MooseX::Role::UnsafeConstructable';

	has [map { "val$_" } (1 .. 60)] => (is => 'ro', isa => 'Str', default => 'some rather long string' x 10);

	__PACKAGE__->meta->make_immutable;
}

cmpthese(-5, {
	normal_new => sub { Foo->new(val1 => 'umm', val6 => 'hmm') },
	unsafe_new => sub { Foo->unsafe_new(val1 => 'umm', val6 => 'hmm') },
});

cmpthese(-5, {
	normal_new => sub { Bar->new },
	unsafe_new => sub { Bar->unsafe_new },
});
