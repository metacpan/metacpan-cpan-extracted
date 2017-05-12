#!/usr/bin/env perl

use strict;
use warnings qw(all);

use FindBin ();
use lib "$FindBin::Bin/../lib";

use Test::Most tests => 17;

use_ok 'MooseX::Role::Defaultable';

{
	package Foo;
	use Moose;
	with 'MooseX::Role::Defaultable';

	has bam => (is => 'rw');
	has bar => (is => 'rw', default => 3573573);
	has bas => (is => 'rw', default => undef);
	has baz => (is => 'rw', default => sub { [qw{mom}] });

	__PACKAGE__->meta->make_immutable;
}

my $foo = Foo->new(bam => 54321);

ok $foo->is_default('non-existent'), 'is_default returns true for non-existent attributes';

ok $foo->is_default('bar'), 'is_default verifies attributes with constant defaults';
ok $foo->is_default('baz'), 'is_default verifies attributes with coderef defaults';
ok $foo->is_default('bas'), 'is_default verifies attributes with an undef default';
ok $foo->is_default('bam'), 'is_default verifies attributes with no defaults';
ok $foo->is_default, 'is_default without arguments verifies all attribute defaults';

$foo->bar(12345);
$foo->baz([]);
$foo->bam(374574);
$foo->bas(33745);
ok ! $foo->is_default, 'is_default without arguments returns false when any attribute is not the default';
ok ! $foo->is_default('bar'), 'is_default returns false when inspecting a modified attribute';
ok ! $foo->is_default('bas'), 'is_default returns false when inspecting a modified attribute with an undef default';
ok $foo->is_default('bam'), 'is_default returns true when inspecting a modified attribute without a default';

$foo->restore_default('bar');
ok $foo->is_default('bar'), 'restore_default with an argument sets the attribute to its default';
ok ! $foo->is_default, 'restore_default with an argument only touches the specified argument';
$foo->restore_default;
ok $foo->is_default, 'restore_default without arguments sets all attributes to their defaults';
is $foo->bam, 374574, 'restore_default does not touch attributes without defaults';

$foo->bar(12345);
ok ! $foo->is_default('baz', 'bar'), 'is_default accepts multiple attribute names';
$foo->restore_default('baz', 'bar');
ok $foo->is_default, 'restore_default accepts multiple attribute names';


