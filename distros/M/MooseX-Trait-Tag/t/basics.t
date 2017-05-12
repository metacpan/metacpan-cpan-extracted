#!/usr/bin/env perl

use strict;
use warnings qw(all);

use FindBin;
use lib "$FindBin::Bin/../lib/";

use Set::Functional;
use Test::Most tests => 15;

use_ok 'MooseX::Trait::Tag';

{
	package Foo;
	use Moose;

	use MooseX::Trait::Tag qw{metadata tag};

	has arr => (
		traits => [qw/metadata/],
		is => 'rw',
		isa => 'ArrayRef',
		default => sub { [qw{hello bob}] },
		auto_deref => 1,
	);
	has bar => (
		traits => [qw/metadata/],
		is => 'rw',
		default => 3573573,
	);
	has baz => (
		traits => [qw/metadata tag/],
		is => 'ro',
		default => 94796,
	);
	has bam => (
		is => 'rw',
		default => 94745,
	);
	__PACKAGE__->meta->make_immutable;
}
{
	package Bare;
	use Moose;

	use MooseX::Trait::Tag qw{nothing};

	has bar => (
		is => 'rw',
		default => 3573573,
	);

	__PACKAGE__->meta->make_immutable;
}

my $foo = Foo->new();
my $bare = Bare->new();

cmp_set [$foo->all_metadata_attributes], [qw{arr bar baz}], 'all_<tag>_attributes find all tagged attributes';
cmp_set [Set::Functional::intersection [$foo->all_metadata_attributes], [$foo->all_tag_attributes]], [qw{baz}], 'Multiple tags on an attribute are orthogonal to eachother';
ok $foo->is_metadata_attribute('bar'), 'is_<tag>_attribute identifies tagged attribute as tagged';
ok ! $foo->is_metadata_attribute('bam'), 'is_<tag>_attribute identifies untagged attribute as not tagged';
ok ! $foo->is_metadata_attribute('none'), 'is_<tag>_attribute identifies non-existent attribute as not tagged';
dies_ok { $foo->is_metadata_attribute() } 'is_<tag>_attribute fails when not given an attribute';
is_deeply {$foo->get_metadata}, {arr => [qw{hello bob}], bar => 3573573, baz => 94796}, 'get_<tag> returns they key-value pairs of the tagged attributes';
lives_ok { $foo->set_metadata(arr => [qw{goodbye fred}], bar => 235, baz => 789, bam => 'wont update', none => 'also wont update') } 'set_<tag> handles all input';
is_deeply scalar($foo->arr), [qw{goodbye fred}], 'set_<tag> modifies autoderef attributes';
is $foo->bar, 235, 'set_<tag> modifies writable tagged attributes';
is $foo->baz, 94796, 'set_<tag> does not modify read-only tagged attributes';
is $foo->bam, 94745, 'set_<tag> does not modify untagged attributes';
throws_ok { $bare->all_metadata_attributes } qr/Can't locate object method/, 'Injecting a tag does not pollute other classes';

lives_ok {
	$bare->all_nothing_attributes;
	$bare->is_nothing_attribute('nothing');
	$bare->get_nothing;
	$bare->set_nothing
} 'Injecting a tag adds all appropriate methods to the importing class, regardless of the attributes';
