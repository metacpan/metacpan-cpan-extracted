#!/usr/bin/env perl

use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/../lib";

use Test::Most tests => 15;

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
	sub val6 { $_[0]->_val6 }

	__PACKAGE__->meta->make_immutable;
}

my $class = 'Foo';

is $class->unsafe_new->val1, undef;
is $class->unsafe_new->val2, 'mom';
is $class->unsafe_new->val3, 'dad';
is $class->unsafe_new->val4, 'bro';
is $class->unsafe_new->val5, undef;
is $class->unsafe_new->_val6, undef;

for my $attr (qw{val1 val2 val3 val4 val5 val6}) {
	is $class->unsafe_new($attr => 'bonkers')->$attr, 'bonkers';
}

dies_ok { $class->new(val1 => [qw{invalid array}]) };
lives_ok { $class->unsafe_new(val1 => [qw{invalid array}]) };
is_deeply
	$class->unsafe_new(val1 => [qw{type unsafe array}])->val1,
	[qw{type unsafe array}];

