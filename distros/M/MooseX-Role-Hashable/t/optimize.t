#!/usr/bin/env perl

use strict;
use warnings qw(all);

use FindBin ();
use lib "$FindBin::Bin/../lib/";

use Test::Most tests => 7;

{
	package Foo::Modified;
	use Moose;
	with 'MooseX::Role::Hashable';
	has bar1 => (is => 'rw', default => 23);
	has bar2 => (is => 'rw', lazy => 1, builder => '_build_bar2');
	has bar5 => (is => 'rw');
	sub _build_bar2 { 46 }
}
{
	package Foo::Modified::Child;
	use Moose;
	extends 'Foo::Modified';
	has bar4 => (is => 'rw', default => 92);
	has '+bar5' => (default => 118);
}
{
	package Foo::Modified::OptimizedChild;
	use Moose;
	extends 'Foo::Modified';
	has bar4 => (is => 'rw', default => 92);
	has '+bar5' => (default => 118);
	__PACKAGE__->meta->make_immutable;
}
{
	package Foo::Modified;
	has bar3 => (is => 'rw', lazy => 1, default => 69);
	__PACKAGE__->meta->make_immutable;
}

{
	package Foo::Normal;
	use Moose;
	with 'MooseX::Role::Hashable';
	has bar1 => (is => 'rw', default => 23);
	has bar2 => (is => 'rw', lazy => 1, builder => '_build_bar2');
	has bar3 => (is => 'rw', lazy => 1, default => 69);
	has bar5 => (is => 'rw');
	sub _build_bar2 { 46 }
}
{
	package Foo::Normal::Child;
	use Moose;
	extends 'Foo::Normal';
	has bar4 => (is => 'rw', default => 92);
	has '+bar5' => (default => 118);
}
{
	package Foo::Normal::OptimizedChild;
	use Moose;
	extends 'Foo::Normal';
	has bar4 => (is => 'rw', default => 92);
	has '+bar5' => (default => 118);
	__PACKAGE__->meta->make_immutable;
}

{
	package Foo::Optimized;
	use Moose;
	with 'MooseX::Role::Hashable';
	has bar1 => (is => 'rw', default => 23);
	has bar2 => (is => 'rw', lazy => 1, builder => '_build_bar2');
	has bar3 => (is => 'rw', lazy => 1, default => 69);
	has bar5 => (is => 'rw');
	sub _build_bar2 { 46 }

	__PACKAGE__->meta->make_immutable;
}
{
	package Foo::Optimized::Child;
	use Moose;
	extends 'Foo::Optimized';
	has bar4 => (is => 'rw', default => 92);
	has '+bar5' => (default => 118);
	__PACKAGE__->meta->make_immutable;
}
{
	package Foo::Optimized::NormalChild;
	use Moose;
	extends 'Foo::Optimized';
	has bar4 => (is => 'rw', default => 92);
	has '+bar5' => (default => 118);
}

my $foo_modified = Foo::Modified->new;
my $foo_modified_child = Foo::Modified::Child->new;
my $foo_modified_optimized_child = Foo::Modified::OptimizedChild->new;
my $foo_normal = Foo::Normal->new;
my $foo_normal_child = Foo::Normal::Child->new;
my $foo_normal_optimized_child = Foo::Normal::OptimizedChild->new;
my $foo_optimized = Foo::Optimized->new;
my $foo_optimized_child = Foo::Optimized::Child->new;
my $foo_optimized_normal_child = Foo::Optimized::NormalChild->new;

is_deeply $foo_modified->as_hash, $foo_normal->as_hash;
is_deeply $foo_optimized->as_hash, $foo_normal->as_hash;

is_deeply $foo_modified_child->as_hash, $foo_normal_child->as_hash;
is_deeply $foo_modified_optimized_child->as_hash, $foo_normal_child->as_hash;
is_deeply $foo_normal_optimized_child->as_hash, $foo_normal_child->as_hash;
is_deeply $foo_optimized_child->as_hash, $foo_normal_child->as_hash;
is_deeply $foo_optimized_normal_child->as_hash, $foo_normal_child->as_hash;
