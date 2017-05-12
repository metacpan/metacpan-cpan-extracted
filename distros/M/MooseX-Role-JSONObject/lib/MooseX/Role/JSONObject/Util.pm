#!/usr/bin/perl

package MooseX::Role::JSONObject::Util;

use v5.012;
use strict;
use warnings;

use version; our $VERSION = version->declare("v0.1.0");

use List::Util qw/pairfirst/;
use Method::Signatures;

func identify_type(Any $val, Moose::Meta::Attribute $attr)
{
	if (!$attr->has_type_constraint) {
		if (!defined $val) {
			die "MooseX::Role::JSONObject::SKIP\n";
		} elsif (ref $val eq 'ARRAY') {
			return ('array', '*');
		} elsif (ref $val eq 'HASH') {
			return ('hash', '*');
		}
		return ['*'];
	}

	if (!defined $val && !$attr->is_required) {
		die "MooseX::Role::JSONObject::SKIP\n";
	}
	my $type = $attr->type_constraint;
	my @res;
again:
	my @handlers = (
		'Object' => ['obj', $type->name],
		'Num' => ['num'],
		'Str' => ['str'],
		'Bool' => ['bool'],
		'Maybe' => ['maybe', '#PARAM'],
		'ArrayRef' => ['array', '#PARAM'],
		'HashRef' => ['hash', '#PARAM'],
	);
	my (undef, $list) = pairfirst { $type->is_a_type_of($a) } @handlers;
	if (!defined $list) {
		die "FIXME: handle the type constraint for ".$attr->name;
	}
	push @res, @{$list};

	if ($res[$#res] eq '#PARAM') {
		pop @res;
		$type = $type->{type_parameter};
		goto again;
	}

	# Apparently we're done looping over parameterized type constraints
	return @res;
}

func get_value(Any $val, Moose::Meta::Attribute $attr, CodeRef $objfunc)
{
	my @type = identify_type($val, $attr);
	return get_type_value($val, \@type, $objfunc);
}

func get_type_value(Any $val, ArrayRef[Str] $type, CodeRef $objfunc)
{
	my %handlers;
	%handlers = (
		'obj' => sub {
			my ($t, $v) = @_;

			my $tname = shift @{$t};
			if (@{$t}) {
				die "Internal error: ".
				    "identify_type() returned ".
				    "extra data after 'obj': @{$t}\n";
			}
			return $objfunc->($v,
			    Class::MOP::Class->initialize($tname));
		},
		'num' => sub {
			return $val + 0;
		},
		'str' => sub {
			return $val."";
		},
		'bool' => sub {
			return !!$val;
		},
		'maybe' => sub {
			my ($t, $v) = @_;

			return undef unless defined $val;
			my $f = shift @{$t};
			return $handlers{$f}->($t, $v, $a);
		},
		'array' => sub {
			my ($t, $v) = @_;

			return [ map {
			    get_type_value($_, [@{$t}], $objfunc)
			} @{$v} ];
		},
		'hash' => sub {
			my ($t, $v) = @_;

			return { map {
			    ($_, get_type_value($v->{$_}, [@{$t}], $objfunc))
			} keys %{$v} };
		},
	);

	my $type_first = shift @{$type};
	return $handlers{$type_first}->($type, $val);
}

func meta_to_json(Object $obj, Moose::Meta::Class $meta)
{
	my @attrs = $meta->get_all_attributes;
	my $res = {};
	for my $attr (@attrs) {
		my $name = $attr->name;
		my $hname = $name;
		if ($attr->has_applied_traits &&
		    grep $_ eq 'MooseX::Role::JSONObject::Meta::Trait', @{$attr->applied_traits}) {
			$hname = $attr->json_attr;
		}
		my $v = $obj->{$name};

		my $ok;
		eval {
			$res->{$hname} = get_value($v, $attr, \&meta_to_json);
			$ok = 1;
		};
		my $msg = $@;
		if (!$ok && $msg ne "MooseX::Role::JSONObject::SKIP\n") {
			die "$msg";
		}
	}
	return $res;
}

func meta_from_json(HashRef $data, Moose::Meta::Class $meta)
{
	my @attrs = $meta->get_all_attributes;
	my %res;
	for my $attr (@attrs) {
		my $name = $attr->name;
		my $hname = $name;
		if ($attr->has_applied_traits &&
		    grep $_ eq 'MooseX::Role::JSONObject::Meta::Trait', @{$attr->applied_traits}) {
			$hname = $attr->json_attr;
		}
		my $v = $data->{$hname};

		my $ok;
		eval {
			$res{$name} = get_value($v, $attr, \&meta_from_json);
			$ok = 1;
		};
		my $msg = $@;
		if (!$ok && $msg ne "MooseX::Role::JSONObject::SKIP\n") {
			die "$msg";
		}
	}
	return $meta->new_object(%res);
}

1;
__END__

=encoding utf-8

=head1 NAME

MooseX::Role::JSONObject::Util - helper functions for MooseX::Role::JSONObject

=head1 DESCRIPTION

The C<MooseX::Role::JSONObject::Util> module provides several utility
functions for the C<MooseX::Role::JSONObject> role.

Please note that these functions are only meant for internal use by
C<MooseX::Role::JSONObject> and, as such, any and all of them may
change without prior notice.

=over 4

=item * identify_type()

Examine a C<Moose::Meta::Attribute> object and return a list of
strings describing recursively the attribute's type, e.g.
C<['maybe', 'hash', 'num']> for a C<Maybe[HashRef[Int]]> attribute or
C<['hash', 'array', 'obj', 'Some::Class']> for a
C<HashRef[ArrayRef[Some::Class]]> attribute.

Note that all types descending from C<Num> are represented as C<'num'>.

=item * get_value()

Given an attribute and a function to recurse into objects, parse
the attribute's type using C<identify_type()> and process the given
type's value appropriately.  This function is used by both the
C<meta_to_json()> and C<meta_from_json()> functions (see below)
with different functions passed as C<$objfunc>.

=item * get_value_type()

Do the actual work of C<get_value()> after the attribute's type has
been examined by C<identify_type()>.

=item * meta_to_json()

Build a Perl hash suitable for a JSON representation of an object
(or a value) of the given C<Moose::Meta::Class> type.
Uses C<get_value()>, passing a reference to itself as the function to
process complex objects.

=item * meta_from_json()

Build a Moose object (or a simple type's value) of the given
C<Moose::Meta::Class> type, initializing it and its attributes
recursively with the values supplied in the given Perl hash.
Uses C<get_value()>, passing a reference to itself as the function to
process complex objects.

=back

=head1 LICENSE

Copyright (C) 2015  Peter Pentchev E<lt>roam@ringlet.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Peter Pentchev E<lt>roam@ringlet.netE<gt>

=cut

