#!/usr/bin/perl

package SmartMatch::Sugar;

use strict;
use warnings;

use Scalar::Util qw(blessed looks_like_number);
use Carp qw(croak);
use Class::Inspector ();

our $VERSION = "0.04";

use Sub::Exporter -setup => {
	exports => [qw(
		any none

		object class inv_isa inv_can inv_does

		overloaded stringifies

		array array_length_is non_empty_array even_sized_array

		hash hash_size_is non_empty_hash

		non_ref string_length_is non_empty_string

		match
	)],
	groups => {
		default  => [ -all ],
		base     => [ qw/any none/ ],
		object   => [ qw/object class inv_isa inv_can inv_does/ ],
		overload => [ qw/overloaded stringifies/ ],
		array    => [ qw/array array_length_is non_empty_array even_sized_array/ ],
		hash     => [ qw/hash hash_size_is non_empty_hash/ ],
		string   => [ qw/non_ref string_length_is non_empty_string/ ],
		match    => [ qw/match/ ],
	},
};

use 5.010;

{
	package SmartMatch::Sugar::Overloaded;
	use overload '~~' => sub { $_[0]->(@_) };
}

sub match (&) { bless $_[0], "SmartMatch::Sugar::Overloaded" }

use constant any => match { not(not(1)) };
use constant none => match { not(not(0)) };

use constant non_empty_string => match {
	defined($_[1])
		and
	not ref($_[1])
		and
	length($_[1])
};

sub string_length_is ($) {
	my $length = _length(shift);

	return match {
		defined($_[1])
			and
		not ref($_[1])
			and
		length($_[1]) == $length
	}
}

use constant non_ref => match {
	defined($_[1])
		and
	not ref($_[1])
};

use overload ();
use constant overloaded => match {
	blessed($_[1])
		and	
	overload::Overloaded($_[1]);
};

use constant stringifies => match {
	blessed($_[1])
		and	
	overload::OverloadedStringify($_[1]);
};

use constant object => match { blessed($_[1]) };

use constant class => match {
	not ref($_[1])
		and
	Class::Inspector->loaded($_[1])
};

sub inv_does ($) {
	my $role = shift;

	return match {
		blessed($_[1]) || ( defined($_[1]) && not(ref($_[1])) )
			and
		$_[1]->DOES($role);
	}
}

sub inv_isa ($) {
	my $class = shift;
	return match {
		blessed($_[1]) || ( defined($_[1]) && not(ref($_[1])) )
			and
		$_[1]->isa($class);
	}
}

sub inv_can ($) {
	my $method = shift;
	return match {
		blessed($_[1]) || ( defined($_[1]) && not(ref($_[1])) )
			and
		$_[1]->can($method);
	}
}
use constant array => match {
	ref($_[1])
		and
	ref($_[1]) eq 'ARRAY'
};

use constant hash => match {
	ref($_[1])
		and
	ref($_[1]) eq 'HASH'
};

use constant non_empty_array => match {
	ref($_[1])
		and
	ref($_[1]) eq 'ARRAY'
		and
	scalar(@{ $_[1] })
};

use constant non_empty_hash => match {
	ref($_[1])
		and
	ref($_[1]) eq 'HASH'
		and
	scalar(keys %{ $_[1] });
};

use constant even_sized_array => match { 
	ref($_[1])
		and
	ref($_[1]) eq 'ARRAY'
		and
	scalar(@{$_[1]}) % 2 == 0
};

sub array_length_is ($) {
	my $length = _length(shift);

	return match {
		ref($_[1])
			and
		ref($_[1]) eq 'ARRAY'
			and
		scalar(@{$_[1]}) == $length
	};
}

sub hash_size_is ($) {
	my $length = _length(shift);

	return match {
		ref($_[1])
			and
		ref($_[1]) eq 'HASH'
			and
		scalar(keys %{$_[1]}) == $length
	};
}

sub _length ($) {
	my $length = shift;

	unless ( looks_like_number($length) and $length >= 0 and int($length) == $length ) {
		croak "Length is not a positive integer";
	}

	return int $length;
}

__PACKAGE__

__END__

=pod

=head1 NAME

SmartMatch::Sugar - Smart match friendly tests.

=head1 SYNOPSIS

	use SmartMatch::Sugar;

	if ( $data ~~ non_empty_array ) {
		@$data;
	}

	if ( $object ~~ inv_isa("Class") {

	}	

=head1 DESCRIPTION

This module provides simple sugary tests that work on the right hand side of a
smart match.

=head1 EXPORTS

All exports are managed by L<Sub::Exporter> so they can be renamed, aliased,
etc.

I suggest using C<namespace::clean> to remove these subroutines from your
namespace.

=over 4

=item any

Returns true for any value except code references (this doesn't work because
smart match will check for reference equality instead of evaluating).

=item none

Returns false for any value 

=item overloaded

Returns true if the value is an object with overloads. Doesn't return true for
class names which have overloads.

Note that putting an overloaded object in a smart match will cause an error
unless C<fallback> is true or the object overloads C<~~>, in which case the
matcher sub will not get a chance to work anyway.

=item stringifies

Returns true if the value is an object with string overloading..

=item object

Returns true if the value is blessed.

=item class

Returns true if L<Class::Inspector> thinks the value is a loaded class.

=item inv_isa $class

Returns true if C<< $object->isa($class) >>. Also works on classes.

The reason this check is not called just C<isa> is because if you import that
into an OO class then your object's C<isa> method is now bogus.

C<inv> stands for invocant, it's the least sucky name I could muster.

=item inv_can $method

Returns true if C<< $object->can($method) >>.

Like C<inv_isa>, also returns true for classes that can C<$method>.

=item inv_does $role

Returns true if C<< $object->DOES($role) >>. Also works for classes.

=item non_ref

Returns true if the item is not a ref, but is defined. Similar to
C<non_empty_string> but doesn't involve checking the length, or truth.

=item non_empty_string

Checks that a value is defined, not a reference, and has a non zero string length.

=item string_length_is $length

Check that the string's length is equal to $length.

=item array

Check that the value is a non blessed array.

=item non_empty_array

Check that the value is an array with at least one element.

Will not accept objects.

=item array_length_is $length

Check that the value is an array and that C<< scalar(@$array) == $length >>.

Will not accept objects.

=item even_sized_array

Check that the array is even sized (can be assigned to a hash).

Will not accept objects.

=item hash

Check that the value is a non blessed hash.

=item non_empty_hash

Check that the value is a hash with some entries.

Will not accept objects.

=item hash_size_is $size

Check that the value is a hash with C<$size> entries in it.

Will not accept objects.

=item match &block

Will match the value against the block. Unlike a raw subroutine, this will not
distribute over arrays and hashes.

=back

=head1 VERSION CONTROL

This module is maintained using Darcs. You can get the latest version from
L<http://nothingmuch.woobling.org/code>, and use C<darcs send> to commit
changes.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

	Copyright (c) 2008 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
