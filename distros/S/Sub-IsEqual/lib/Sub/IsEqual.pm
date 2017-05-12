package Sub::IsEqual;

=head1 NAME

Sub::IsEqual - determine if two arguments are equal

=cut

use strict;
use warnings;

use Exporter qw{import};
use List::Util qw{first};
use Scalar::Util qw{refaddr};
use Set::Functional qw{symmetric_difference};

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

This module provides a function called is_equal to determine if any two
arbitrary arguments are the same.  Equality is determined by definedness,
structure, and string equality, so 1 and 1.0 will be considered inequal.
For data structures, circular references will be detected.

=cut

=head1 METHODS

=cut

our @EXPORT_OK = qw{is_equal};

=head2 is_equal

Given 2 arguments, determine if they are equivalent using string equality
and deep comparison.  For large data structures, is_equal will attempt to
walk the structure, comparing all key-value paris for hashes, checking the
order in arrays, and following all references while checking for loops.
Blessed objects must be the same value in memory, by default, but may define
their own equivalence by overloading the eq operator. The only exception
to all of this is undef, which is only equivalent to itself.

Examples:

	is_equal(undef, undef); # => true
	is_equal(undef, ''); # => false
	is_equal(1, 1.0); # => false
	is_equal("mom", "mom"); # => true
	is_equal([qw{hello world}], [qw{hello world}]); # => true
	is_equal({hello => 1}, {hello => 1}); # => true

=cut

sub is_equal {
	my ($left, $right, $recursion_check) = @_;

	#Check that both values are in the same state of definedness
	return 0 if defined($left) ^ defined($right);
	#Check that both values are defined
	return 1 if ! defined($left);
	#Check that both values are string equivalent
	return 1 if $left eq $right;

	my ($left_ref, $right_ref) = (ref($left), ref($right));

	#Check that both values refer to the same type of thing
	return 0 if $left_ref ne $right_ref;
	#Check that both values are references
	return 0 if $left_ref eq '';

	$recursion_check ||= {};
	my ($left_refaddr, $right_refaddr) = (refaddr($left), refaddr($right));

	#Check that both references are in the same visit state
	return 0 if exists $recursion_check->{$left_refaddr} ^ exists $recursion_check->{$right_refaddr};
	#Check that both references have already been visited
	return 1 if exists $recursion_check->{$left_refaddr};

	undef $recursion_check->{$left_refaddr};
	undef $recursion_check->{$right_refaddr};

	#Check that scalar references point to the same values
	if ($left_ref eq 'SCALAR' || $left_ref eq 'REF') {
		return is_equal($$left, $$right, $recursion_check);

	#Check that arrays have the same values in the same order
	} elsif ($left_ref eq 'ARRAY') {
		return
			@$left == @$right
			&& ! defined(first { ! is_equal($left->[$_], $right->[$_], $recursion_check) } (0 .. $#$left));

	#Check that hashes contain the same keys pointing to the same values
	} elsif ($left_ref eq 'HASH') {
		return
			! symmetric_difference([keys %$left], [keys %$right])
			&& ! defined(first { ! is_equal($left->{$_}, $right->{$_}, $recursion_check) } keys %$left);

	#Give up
	} else {
		die "Must define string equality for type [$left_ref]";
	}
}

=head1 AUTHOR

Aaron Cohen, C<< <aarondcohen at gmail.com> >>

=head1 ACKNOWLEDGEMENTS

This module was made possible by L<Shutterstock|http://www.shutterstock.com/>
(L<@ShutterTech|https://twitter.com/ShutterTech>).  Additional open source
projects from Shutterstock can be found at
L<code.shutterstock.com|http://code.shutterstock.com/>.

=head1 BUGS

Please report any bugs or feature requests to C<bug-sub-isequal at rt.cpan.org>, or through
the web interface at L<https://github.com/aarondcohen/perl-sub-isequal/issues>.  I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sub::IsEqual

You can also look for information at:

=over 4

=item * Official GitHub Repo

L<https://github.com/aarondcohen/perl-sub-isequal>

=item * GitHub's Issue Tracker (report bugs here)

L<https://github.com/aarondcohen/perl-sub-isequal/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Sub-IsEqual>

=item * Official CPAN Page

L<http://search.cpan.org/dist/Sub-IsEqual/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Aaron Cohen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut


1;
