package MooseX::Types::StrictScalarTypes;

use strict;
use warnings;

our $VERSION = '1.0.0';

use Scalar::Type qw(bool_supported :is_*);

use MooseX::Types -declare => [qw(StrictInt StrictNumber), (bool_supported() ? 'StrictBool' : ())];
use MooseX::Types::Moose qw(Value);

subtype StrictInt,
    as Value,
    where { is_integer($_) },
    message { "value is not an integer (maybe it's a string that looks like an integer?)" };

subtype StrictNumber,
    as Value,
    where { is_number($_) },
    message { "value is not a number (maybe it's a string that looks like a number?)" };

if(bool_supported) {
    eval '
        subtype StrictBool,
            as Value,
            where { is_bool($_) },
            message { "value is not a Boolean (maybe it\'s a number that you\'re expecting to use as a Boolean?)" };
    ';
}

1;

=head1 NAME

MooseX::Types::StrictScalarTypes - strict Moose type constraints for integers, numbers, and Booleans

=head1 SYNOPSIS

    package Foo;

    use Moose;
    use MooseX::Types::StrictScalarTypes qw(StrictInt StrictNumber StrictBool);

    has integer => ( is => 'ro', isa => StrictInt    );
    has number  => ( is => 'ro', isa => StrictNumber );
    has boolean => ( is => 'ro', isa => StrictBool   );


These will all throw exceptions:

    Foo->new(integer => 3.14);    # because 3.14 is a float, not an int

    Foo->new(number => "3.14");   # that's a string, not a number

    Foo->new(boolean => 1);       # that's an integer, not the result of a comparison

And these will not:

    Foo->new(integer => 3);

    Foo->new(number => 3.14);

    Foo->new(boolean => 0 == 1);

=head1 DESCRIPTION

Perl scalars can be either strings or numbers, and normally you don't really
care which is which as it will do all the necessary type conversions automagically.

But in some rare cases the difference matters. This package provides some
Moose type constraints to let you easily enforce stricter type checking than
what Moose can normally do with its builtin C<Int>, C<Number> and C<Bool> types.

Internally it uses L<Scalar::Type> so see its documentation if you want to know
the gory details.

=head1 LIMITATIONS

The Boolean type is only available in perl 5.36 and higher. Attempting to use it
on an older perl is a fatal error. You can use C<Scalar::Type::bool_supported>
to easily check at run-time whether it will be available or not.

=head1 TYPES

=over

=item StrictInt

A type that only accepts integers. Floating point numbers such as C<3.0> and
strings like C<"3"> are not permitted.

=item StrictNumber

A type that only accepts numbers. Strings like C<"3"> are not permitted.

=item StrictBool

A type that only accepts Booleans, the result of a comparison. Numbers and strings
such as C<1> and C<""> are not permitted, but values like C<1 == 0> are.

=back

=head1 SEE ALSO

L<Test2::Tools::Type> - similarly strict checking for your tests

L<Scalar::Type>

=head1 BUGS

If you find any bugs please report them on Github, preferably with a test case.

=head1 FEEDBACK

I welcome feedback about my code, especially constructive criticism.

=head1 AUTHOR, COPYRIGHT and LICENCE

Copyright 2024 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This software is free-as-in-speech software, and may be used,
distributed, and modified under the terms of either the GNU
General Public Licence version 2 or the Artistic Licence. It's
up to you which one you use. The full text of the licences can
be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason software.
