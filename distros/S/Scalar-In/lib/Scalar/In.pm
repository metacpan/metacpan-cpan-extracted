package Scalar::In; ## no critic (TidyCode)

use strict;
use warnings;
use Sub::Exporter -setup => {
    exports => [ qw( string_in numeric_in ) ],
    groups  => {
        default => [ qw( string_in ) ],
    },
};

our $VERSION = '0.002';

# using dualvars
my $true  = ! 0;
my $false = ! 1;

sub string_in (++) { ## no critic (SubroutinePrototypes)
    my ( $any1, $any2 ) = @_;

    my $ref_any1 = ref $any1;
    my @any1
        = $ref_any1 eq 'ARRAY'
        ? @{$any1}
        : $ref_any1 eq 'HASH'
        ? keys %{$any1}
        : $any1;
    for my $string ( @any1 ) {
        if ( defined $string ) {
            $string .= q{}; # stingify object
        }
        my $ref_any2 = ref $any2;
        my @any2
            = $ref_any2 eq 'ARRAY'
            ? @{$any2}
            : $ref_any2 eq 'HASH'
            ? keys %{$any2}
            : $any2;
        ITEM:
        for my $item ( @any2 ) {
            if ( ! defined $string || ! defined $item ) {
                return ! ( defined $string xor defined $item );
            }
            if ( ref $item eq 'Regexp' ) {
                $string =~ $item
                    and return $true;
                next ITEM;
            }
            ref $item eq 'CODE'
                and return $item->($string);
            $string eq q{} . $item # stingify object
                and return $true;
        }
    }

    return $false;
}

sub numeric_in (++) { ## no critic (SubroutinePrototypes)
    my ( $any1, $any2 ) = @_;

    my $ref_any1 = ref $any1;
    my @any1
        = $ref_any1 eq 'ARRAY'
        ? @{$any1}
        : $ref_any1 eq 'HASH'
        ? keys %{$any1}
        : $any1;
    for my $numeric ( @any1 ) {
        if ( defined $numeric ) {
            $numeric += 0; # numify object
        }
        my $ref_any2 = ref $any2;
        my @any2
            = $ref_any2 eq 'ARRAY'
            ? @{$any2}
            : $ref_any2 eq 'HASH'
            ? keys %{$any2}
            : $any2;
        ITEM:
        for my $item ( @any2 ) {
            if ( ! defined $numeric || ! defined $item ) {
                return ! ( defined $numeric xor defined $item );
            }
            if ( ref $item eq 'Regexp' ) {
                $numeric =~ $item
                    and return $true;
                next ITEM;
            }
            ref $item eq 'CODE'
                and return $item->($numeric);
            $numeric == ( 0 + $item ) # numify object
                and return $true;
        }
    }

    return $false;
}

# $Id$

1;

__END__

=head1 NAME

Scalar::In - replacement for smartmatch

=head1 VERSION

0.002

=head1 SYNOPSIS

    use Scalar::In;                                   # imports string_in
    use Scalar::In 'numeric_in';                      # imports numeric_in
    use Scalar::In string_in  => { -as => 'in' };     # imports in
    use Scalar::In numeric_in => { -as => 'num_in' }; # imports num_in

=head1 EXAMPLE

Inside of this Distribution is a directory named example.
Run this *.pl files.

=head1 DESCRIPTION

This module was written because the smartmatch operator C<~~>
was deprecated as experimental.

That module implements some "in" subroutines
with smartmatch similar behaviour.

First I tried to delete the obsolete looking C<numeric_in>.
In tests I realized
that objects with overloaded C<+> working there
but C<string_in> expects objects with overloaded C<"">.
So there are some special cases for C<numeric_in>.
Because of such minimal cases C<numeric_in> is not exported as default.

=head1 SUBROUTINES/METHODS

=head2 subroutine string_in

"any1" or "any2" can contain 0 or more values.
The first string match of "any1" and "any2" will return true.
Also the frist match of undef in "any1" and "any2" will return true.
All other will return false.
In case of a hash or hash reference the keys are used.

    $boolean = string_in( [$@%]any1, [$@%]any2 );

Allowed values for $any1:

    undef, $string, $numeric, $object, $array_ref, $hash_ref

Allowed values for @any1 or if $any1 is an array reference:

    $string, $numeric, $object

Allowed values for $any2:

    undef, $string, $numeric, $object, $array_ref, $hash_ref, $regex, $code_ref

Allowed values for @any2 or if $any2 is an array reference:

    $string, $numeric, $object, $regex, $code_ref

All given values will be used as string if they are defined.

=head3 some examples

true if $string is undef

    $boolean = string_in( $string, undef );

true if $string is eq 'string'

    $boolean = string_in( $string, 'string' );

true if $string contains abc or def

    $boolean = string_in( $string, qr{ abc | def }xms );

true if $string begins with abc

    $boolean = string_in(
        $string,
        sub {
            my $str = shift;
            return 0 == index $str, 'abc';
        },
    );

true if $object overloads C<""> and that is C<eq> 'string'.
Objects in the 2nd parameter should also overload C<"">.

    $boolean = string_in( $object, 'string' );

true if any key in the hash or hash reference will match

    $boolean = string_in( $string, $hash_ref );
    $boolean = string_in( $string, %hash );

=head2 subroutine numeric_in

A given value will be used as numeric if it is defined.
Maybe that thows a numeric warning if a string looks not like numeric.
The difference to subroutine string_in is,
that here is operator C<==> used instead of operator C<eq>.

    $boolean = numeric_in( $numeric, undef );
    $boolean = numeric_in( $numeric, 123 );
    $boolean = numeric_in( $numeric, qr{ 123 | 456 }xms );
    $boolean = numeric_in( $numeric, $array_ref );
    $boolean = numeric_in( $numeric, @array );
    $boolean = numeric_in( $numeric, $hash_ref );
    $boolean = numeric_in( $numeric, %hash );

true if $numeric > 1

    $boolean = numeric_in(
        $numeric,
        sub {
            my $num = shift;
            return $num > 1;
        },
    );

true if $object overloads C<+> and that is C<==> 123.

    $boolean = numeric_in( $object, 123 );

Objects that overload C<+> also allowed as 2nd parameter
or in a array or array reference.

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

nothing

=head1 DEPENDENCIES

L<Sub::Exporter|Sub::Exporter>

=head1 INCOMPATIBILITIES

nothing

=head1 BUGS AND LIMITATIONS

nothing

=head1 SEE ALSO

smartmatch operator ~~

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
