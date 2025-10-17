#
# This file is part of Perl-Types
#
# This software is Copyright (c) 2025 by Perl Community 501(c)(3) nonprofit organization.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
# ABSTRACT: the Perl data type system
# DEV NOTE, CORRELATION #gt00: copy all project abstract changes between 'README.md' header & "# ABSTRACT" & POD in main module; copy all description changes between 'README.md' header & main module POD

# [[[ HEADER ]]]
package Perl::Types;
use strict;
use warnings;
use Perl::Config;
our $VERSION = 0.009_000;

# [[[ INCLUDES ]]]
# DEV NOTE: "use Perl::Types;" is just an object-oriented wrapper around the "use perltypes;" pragma
use perltypes;

# [[[ EXPORTS ]]]
# export all symbols imported from essential modules; includes (Data::Dumper, English, Carp, and POSIX) via Perl::Config
use Exporter qw(import);
our @EXPORT = (@perltypes::EXPORT);

1;  # end of package

__END__

=head1 NAME

Perl::Types - the Perl data type system

=for comment
# DEV NOTE, CORRELATION #gt00: copy all project abstract changes between 'README.md' header & "# ABSTRACT" & POD in main module; copy all description changes between 'README.md' header & main module POD

=head1 SYNOPSIS

    # the following three styles are functionally equivalent,
    # only choose one:
    use types;        # pragma style, short
    use class;
    # OR
    use perltypes;    # pragma style, medium
    use perlclass;
    # OR
    use Perl::Types;  # OO style, long
    use Perl::Class;

    # declare & define a typed scalar
    my integer $i = 42;

    # declare & define a typed compound reference
    my arrayref::integer $arr = [1, 2, 3];

    # define an OO class
    package Some::Class;
    use types;
    use parent qw(class);
    use class;
    our hashref $properties = { bar => my integer $TYPED_bar = 23 };
    sub multiply_bar {
        { my number $RETURN_TYPE };
        ( my Some::Class $self, my number $multiplier ) = @ARG;
        return ($self->{bar} * $multiplier);
    }
    1;  # end of class

    # declare & instantiate an OO object
    my Some::Class $my_object = Some::Class->new();
    print $my_object->multiply_bar(5.6), "\n";

=head1 DESCRIPTION

Perl::Types defines package namespaces for core Perl data types and nested compound
reference types using the C<::> scope resolution operator.  It enables explicit typing
of scalars, arrays, and hashes in your Perl code.

Note that "use Perl::Types;" and "use perltypes;" and "use types;" all have the exact
same effect; these options are provided to please both OO and pragma style preferences.
Please choose one and use it throughout your entire codebase, to avoid confusion.

Use of the Perl data type system also provides the added benefit of pre-emptively
preparing your Perl source code for future optimization by the Perl compiler.

Perl::Types is currently in a beta release phase, and is considered stable enough for
monitored use in commercial or production code.

=head2 Data Types vs Type Constraints

Do not confuse the Perl data type system with any of Perl's numerous type constraint
libraries.  If you are using any software other than Perl::Types to access or manage
data types, then you are actually using type constraints.

Data type systems access the real underlying data types, which are linked to the actual
computer hardware resources and are not subjective in any way.  On the other hand,
type contraints access the transient data values and attempt to guess what the real
data types might be, which is an entirely subjective process.  While these may seem
similar on the surface, and are often purposefully conflated due to Perl's checkered
history with data type support, they are in fact very different approaches to software
development and should be clearly understood as such.

TL;DR: Type systems should be utilized instead of type contraints.

=head2 Scalar Types

Scalars contain a single piece of data, and are the foundation of all other data types.

The five basic scalar data types are:

=over

=item * boolean

=item * integer

=item * number

=item * character

=item * string

=back

=head2 Compound Reference Types

Compound types are comprised of scalar types contained inside one or more
nested references, such as:

=over

=item * arrayref::integer

=item * arrayref::number

=item * arrayref::string

=item * hashref::integer

=item * hashref::number

=item * hashref::string

=item * arrayref::arrayref::integer

=item * hashref::hashref::arrayref::number

=item * hashref::arrayref::hashref::string

=back

=cut

=head1 EXAMPLES

=head2 Scalar Types

Declaring & defining scalar variables:

    my boolean   $b = 1;
    my integer   $i = -123;
    my number    $n = 3.14;
    my character $c = 'a';
    my string    $s = 'hello';

=head2 One-Dimensional Array References

Declaring & defining array references:

    my arrayref::integer $ai = [1, 2, 3];
    my arrayref::number  $an = [3.14, 2.718];
    my arrayref::string  $as = ['foo', 'bar'];

=head2 Two-Dimensional Array References

Declaring & defining nested array references:

    my arrayref::arrayref::integer $a2i = [[1, 2], [3, 4]];
    my arrayref::arrayref::string  $a2s = [['a', 'b'], ['c', 'd']];

=head2 One-Dimensional Hash References

Declaring & defining hash references:

    my hashref::integer $hi = { a => 1, b => 2 };
    my hashref::number  $hn = { pi => 3.14 };
    my hashref::string  $hs = { foo => 'bar' };

=head2 Two-Dimensional Hash References

Declaring & defining nested hash references:

    my hashref::hashref::string $hhs = {
        out1 => { in1a => 'howdy', in1b => 'pardner' },
        out2 => { in2a => 'adios', in2b => 'amigo' }
    };

=head2 Nested Hash/Array Structures

Declaring & defining mixed nested structures:

    my hashref::arrayref::integer $hai = {
        arr1 => [1, 2, 3],
        arr2 => [4, 5, 6]
    };

    my arrayref::hashref::string $ahs = [
        { in1a => 'howdy', in1b => 'pardner' },
        { in2a => 'adios', in2b => 'amigo'   }
    ];

=head2 Constants

Declaring & defining scalar constants:

    use constant P   => my integer $TYPED_P   = 23;
    use constant PI  => my number  $TYPED_PI  = 3.141_59;
    use constant PIE => my string  $TYPED_PIE = 'pecan';

=head2 Subroutines

Declaring subroutine input parameters & output return values:

    sub pies_are_round {
        { my void $RETURN_TYPE };
        print 'in pies_are_round(), having PIE() = ', PIE(), "\n";
        return;
    }

    sub pi_r_squared {
        { my number $RETURN_TYPE };
        ( my number $r ) = @ARG;
        my number $area = PI() * $r ** 2;
        print 'in pi_r_squared(), have $area = PI() * $r ** 2 = ', $area, "\n";
        return $area;
    }

    sub p_is_pentagonal {
        { my string $RETURN_TYPE };
        ( my string $base_text, my integer $repeat_count ) = @ARG;
        my string $repeated_text = $base_text x $repeat_count;
        print 'in p_is_pentagonal(), have $repeated_text = \'', $repeated_text, '\'', "\n";
        return $repeated_text;
    }

=head2 Object-Orientation

Defining OO classes:

    # [[[ HEADER ]]]
    package Some::Class;
    use strict;
    use warnings;
    use types;
    our $VERSION = 0.001_000;

    # [[[ OO INHERITANCE ]]]
    use parent qw(class);
    use class;

    # [[[ OO PROPERTIES ]]]
    our hashref $properties = { bar => my integer $TYPED_bar = 23 };

    # [[[ SUBROUTINES & OO METHODS ]]]
    sub multiply_bar {
        { my number $RETURN_TYPE };
        ( my Some::Class $self, my number $multiplier ) = @ARG;
        return ($self->{bar} * $multiplier);
    }

    1;  # end of class

Declaring & instantiating OO objects:

    my Some::Class $my_object = Some::Class->new();
    print $my_object->multiply_bar(5.6), "\n";

=head2 Filehandles

Declaring & defining filehandles by reference:

    # variables with data type "filehandleref" must be undefined,
    # thereby making the filehandle into "a reference to a newly allocated anonymous filehandle"

    use strict;
    use warnings;
    use types;
    open(my filehandleref $FH, '>&STDOUT') or die $OS_ERROR;
    print $FH 'HOWDY', "\n";

Declaring & defining filehandles by value (not suggested, incompatible with "use strict"):

    # variables with data type "filehandle" must be defined and set to a string value,
    # thereby making the filehandle into "an expression" and requiring "use strict" to NOT be in effect

    # use strict;  # disable to avoid the error... Can't use string ("MYFH") as a symbol ref while "strict refs" in use
    use warnings;
    use types;
    open(my filehandle $FH = 'MYFH', '>&STDOUT') or die $OS_ERROR;
    print $FH  'HOWDY', "\n";
    print MYFH 'DOODY', "\n";

L<Perldoc open() For More Info|https://perldoc.perl.org/functions/open#Direct-versus-by-reference-assignment-of-filehandles>

=head1 COMING SOON

Documentation:

=over

=item * More details & examples

=item * Type-checking instructions

=item * Arrays & hashes by value

=item * Arrays & hashes of objects

=back

The following data types are partially implemented and planned for future releases:

=over

=item * nonsigned_integer

=item * gmp_integer

=item * void

=item * unknown

=item * scalartype

=back

=head1 SEE ALSO

L<The Perl Compiler|RPerl>

L<The Perl::Types Committee|https://perlcommunity.org/types>

=head1 AUTHOR

B<William N. Braswell, Jr.>

L<mailto:wbraswell@NOSPAM.cpan.org>

=cut
