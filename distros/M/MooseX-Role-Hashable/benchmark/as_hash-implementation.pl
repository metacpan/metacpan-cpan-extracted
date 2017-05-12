#!/usr/bin/env perl

use strict;
use warnings qw(all);

use FindBin ();
use lib "$FindBin::Bin/../lib/";

use Benchmark qw{cmpthese};
use Test::Most;

my $_as_hash_copy = sub { +{ %{$_[0]} } };
my $_meta_extract = sub { my $self = shift;  map { ($_->name => $_->get_value($self)) } @_ };

my $_as_hash_diff_v1 = sub {
	my $self = shift;

	my $copy = $_as_hash_copy->($self);
	my @missing_attributes = grep { ! exists $copy->{$_->name} } $self->meta->get_all_attributes;
	@{$copy}{map { $_->name } @missing_attributes} = map { $_->get_value($self) } @missing_attributes;

	return $copy;
};

my $_as_hash_diff_v2 = sub {
	my $self = shift;

	my $copy = $_as_hash_copy->($self);
	my @missing_attributes = grep { ! exists $copy->{$_->name} } $self->meta->get_all_attributes;
	$copy->{$_->name} = $_->get_value($self) for @missing_attributes;

	return $copy;
};

my $_as_hash_diff_v3 = sub {
	my $self = shift;

	my $copy = $_as_hash_copy->($self);
	my @missing_attributes = grep { ! exists $copy->{$_->name} } $self->meta->get_all_attributes;

	return +{ %$copy, $_meta_extract->($self, @missing_attributes) };
};

my $_as_hash_diff_v4 = sub {
	my $self = shift;

	my $copy = $_as_hash_copy->($self);
	my @missing_attributes = grep { ! exists $copy->{$_->name} } @_;
	$copy->{$_->name} = $_->get_value($self) for @missing_attributes;

	return $copy;
};

my $_as_hash_diff_v5 = sub {
	my $self = shift;

	my @missing_attributes = grep { ! exists $self->{$_->name} } @_;

	return +{ %$self, $_meta_extract->($self, @missing_attributes) };
};

my $_as_hash_safe = sub {
	my $self = shift;
	return +{ $_meta_extract->($self, $self->meta->get_all_attributes) };
};


{
	package Foo;
	use Moose;
	with 'MooseX::Role::Hashable';

	has [map { "field$_" } (10 .. 19)] => (is => 'rw', default => undef);
	has [map { "field$_" } (20 .. 29)] => (is => 'rw', default => 1);
	has [map { "field$_" } (30 .. 31)] => (is => 'rw', lazy => 1, builder => '_build_attr');
	has [map { "field$_" } (40 .. 41)] => (is => 'rw', default => 1, lazy => 1);
	sub _build_attr { 1 }

	__PACKAGE__->meta->make_immutable;
}

my @possible_attrs = grep { ! ($_->is_required || ! $_->is_lazy && ($_->has_builder || $_->has_default))  } Foo->meta->get_all_attributes;

is_deeply $_as_hash_diff_v1->(Foo->new), $_as_hash_safe->(Foo->new);
is_deeply $_as_hash_diff_v2->(Foo->new), $_as_hash_safe->(Foo->new);
is_deeply $_as_hash_diff_v3->(Foo->new), $_as_hash_safe->(Foo->new);
is_deeply $_as_hash_diff_v4->(Foo->new, @possible_attrs), $_as_hash_safe->(Foo->new);
is_deeply $_as_hash_diff_v5->(Foo->new, @possible_attrs), $_as_hash_safe->(Foo->new);
is_deeply(Foo->new->as_hash, $_as_hash_safe->(Foo->new));

cmpthese(-5, {
	safe => sub { $_as_hash_safe->(Foo->new) },
	v1 => sub { $_as_hash_diff_v1->(Foo->new) },
	v2 => sub { $_as_hash_diff_v2->(Foo->new) },
	v3 => sub { $_as_hash_diff_v3->(Foo->new) },
	v4 => sub { $_as_hash_diff_v4->(Foo->new, @possible_attrs) },
	v5 => sub { $_as_hash_diff_v5->(Foo->new, @possible_attrs) },
	role => sub { Foo->new->as_hash },
});
