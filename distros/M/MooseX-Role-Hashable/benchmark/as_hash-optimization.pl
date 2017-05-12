#!/usr/bin/env perl

use strict;
use warnings qw(all);

use FindBin ();
use lib "$FindBin::Bin/../lib/";

use Benchmark qw{cmpthese};
use Test::Most;

{
	package Augmented;
	use Moose;
	with 'MooseX::Role::Hashable';

	has $_ => (is => 'rw', default => undef) for map { "field$_" } (10 .. 19);
	has $_ => (is => 'rw', default => 1) for map { "field$_" } (20 .. 29);
	has $_ => (is => 'rw', lazy => 1, builder => '_build_attr') for map { "field$_" } (30 .. 31);
	has $_ => (is => 'rw', default => 1, lazy => 1) for map { "field$_" } (40 .. 41);
	has "_$_" => (is => 'rw') for map { "field$_" } (50 .. 51);
	sub _build_attr { 1 }

	around as_hash => sub {
		my ($orig, $self) = @_;
		my $hash = $self->$orig;
		delete @{$hash}{map { "field$_" } (30 .. 31, 40 .. 41)};
		@{$hash}{map { "field$_" } (50 .. 51)} = delete @{$hash}{map { "_field$_" } (50 .. 51)};

		return $hash;
	};

	__PACKAGE__->meta->make_immutable;
}
{
	package UndefInit;
	use Moose;
	with 'MooseX::Role::Hashable';

	has $_ => (is => 'rw', default => undef) for map { "field$_" } (10 .. 19);
	has $_ => (is => 'rw', default => 1) for map { "field$_" } (20 .. 29);
	has $_ => (is => 'rw', lazy => 1, builder => '_build_attr', init_arg => undef) for map { "field$_" } (30 .. 31);
	has $_ => (is => 'rw', default => 1, lazy => 1, init_arg => undef) for map { "field$_" } (40 .. 41);
	has "_$_" => (is => 'rw', init_arg => $_) for map { "field$_" } (50 .. 51);
	sub _build_attr { 1 }

	__PACKAGE__->meta->make_immutable;
}
{
	package Unoptimized;
	use Moose;
	with 'MooseX::Role::Hashable';

	has $_ => (is => 'rw', default => undef) for map { "field$_" } (10 .. 19);
	has $_ => (is => 'rw', default => 1) for map { "field$_" } (20 .. 29);
	has $_ => (is => 'rw', lazy => 1, builder => '_build_attr', init_arg => undef) for map { "field$_" } (30 .. 31);
	has $_ => (is => 'rw', default => 1, lazy => 1, init_arg => undef) for map { "field$_" } (40 .. 41);
	has "_$_" => (is => 'rw', init_arg => $_) for map { "field$_" } (50 .. 51);
	sub _build_attr { 1 }
}

is_deeply(Augmented->new->as_hash, Unoptimized->new->as_hash);
is_deeply(UndefInit->new->as_hash, Unoptimized->new->as_hash);

cmpthese(-5, {
	augmented => sub { Augmented->new->as_hash },
	undef_init => sub { UndefInit->new->as_hash },
	unoptimized => sub { Unoptimized->new->as_hash },
});
