package PRANG::Coerce;
$PRANG::Coerce::VERSION = '0.18';
use Moose;
use Moose::Util::TypeConstraints;

# This is what this method is doing:
#
#coerce 'ArrayRef[`K]'
#    => from 'K'
#    => via { [ $_ ] };
#
sub coerce_arrayref_of {
	my $what = shift;

	my $typeName = lc $what;
	$typeName =~ s{^(\w)}{uc($1||"")}eg;
	$typeName =~ s{::(\w?)}{uc($1||"")}eg;

	my $subtype = __PACKAGE__ . '::ArrayRefOf' . $typeName . 's';
	my $as = 'ArrayRef[' . $typeName . ']';

	subtype $subtype
		=> as $as;
	coerce $subtype
		=> from $what
		=> via { [$_] };
}

# Make these coercions from standard types
coerce_arrayref_of('Str');
coerce_arrayref_of('Int');

1;

=head1 NAME

PRANG::Coerce - Easily create subtypes and coercions for any type

=head1 SYNOPSIS

    use PRANG::Coerce;

    has_element 'an_array_of_strs' =>
        is => 'rw',
        isa => 'PRANG::Coerce::ArrayRefOfStrs',
        coerce => 1,
        ;

    # or

    use PRANG::Coerce;

    PRANG::Coerce::coerce_arrayref_of('Type');

    has_element 'an_array_of_types' =>
        is => 'rw',
        isa => 'PRANG::Coerce::ArrayRefOfTypes',
        coerce => 1,
        ;

=head1 DESCRIPTION

When defining a type which is an C<ArrayRef[Type]>, sometimes it's nice to be
able to just pass in a C<Type>. By using this module, that C<Type> can be
coerced into the 'ArrayRef[Type]' by using C<ArrayRefOfTypes>.

=head1 PRE-DEFINED TYPES

PRANG::Coerce already defines two array types. These are for C<Str> and C<Int>
and are defined as C<ArrayOfStrs> and C<ArrayOfInts> respectively.

=head1 AUTHOR AND LICENCE

Development commissioned by NZ Registry Services, and carried out by
Catalyst IT - L<http://www.catalyst.net.nz/>

Copyright 2009, 2010, NZ Registry Services.  This module is licensed
under the Artistic License v2.0, which permits relicensing under other
Free Software licenses.

=cut
