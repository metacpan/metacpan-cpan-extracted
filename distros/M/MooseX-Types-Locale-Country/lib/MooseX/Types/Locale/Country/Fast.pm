package MooseX::Types::Locale::Country::Fast;


# ****************************************************************
# general dependency(-ies)
# ****************************************************************

use 5.008_001;
# MooseX::Types turns strict/warnings pragmas on,
# however, kwalitee scorer can not detect such mechanism.
# (Perl::Critic can it, with equivalent_modules parameter)
use strict;
use warnings;

use Locale::Country;
use MooseX::Types::Moose qw(
    Str
    Int
);
use MooseX::Types (
    -declare => [qw(
        CountryCode
        Alpha2Country
        Alpha3Country
        NumericCountry
        CountryName
    )],
);


# ****************************************************************
# namespace clearer
# ****************************************************************

use namespace::clean;


# ****************************************************************
# public class variable(s)
# ****************************************************************

our $VERSION = "0.05";


# ****************************************************************
# subtype(s) and coercion(s)
# ****************************************************************

# ----------------------------------------------------------------
# alpha-2 country code as defined in ISO 3166-1
# ----------------------------------------------------------------
foreach my $subtype (CountryCode, Alpha2Country) {
    subtype $subtype,
        as Str,
            where {
                code2country($_, LOCALE_CODE_ALPHA_2);
            },
            message {
                sprintf 'Validation failed for code failed with value (%s) '
                      . 'because specified country code does not exist '
                      . 'in ISO 3166-1 alpha-2',
                    defined $_ ? $_ : q{};
            };
}

# ----------------------------------------------------------------
# alpha-3 country code as defined in ISO 3166-1
# ----------------------------------------------------------------
subtype Alpha3Country,
    as Str,
        where {
            code2country($_, LOCALE_CODE_ALPHA_3);
        },
        message {
            sprintf 'Validation failed for code failed with value (%s) '
                  . 'because specified country code does not exist '
                  . 'in ISO 3166-1 alpha-3',
                defined $_ ? $_ : q{};
        };

# ----------------------------------------------------------------
# numeric country code as defined in ISO 3166-1
# ----------------------------------------------------------------
subtype NumericCountry,
    as Str,
        where {
            code2country($_, LOCALE_CODE_NUMERIC);
        },
        message {
            sprintf 'Validation failed for code failed with value (%s) '
                  . 'because specified country code does not exist '
                  . 'in ISO 3166-1 numeric',
                defined $_ ? $_ : q{};
        };

# ----------------------------------------------------------------
# Country name as defined in ISO 639-1
# ----------------------------------------------------------------
subtype CountryName,
    as Str,
        where {
            country2code($_);
        },
        message {
            sprintf 'Validation failed for name failed with value (%s) '
                  . 'because specified country name does not exist '
                  . 'in ISO 3166-1',
                defined $_ ? $_ : q{};
        };


# ****************************************************************
# optionally add Getopt option type
# ****************************************************************

eval { require MooseX::Getopt; };
if (!$@) {
    MooseX::Getopt::OptionTypeMap->add_option_type_to_map( $_, '=s', )
        for (CountryCode, Alpha2Country, Alpha3Country, CountryName);
    MooseX::Getopt::OptionTypeMap->add_option_type_to_map( $_, '=i', )
        for (NumericCountry);
}


# ****************************************************************
# return true
# ****************************************************************

1;
__END__


# ****************************************************************
# POD
# ****************************************************************

=pod

=head1 NAME

MooseX::Types::Locale::Country::Fast - Locale::Country related constraints for Moose (without coercions)

=head1 VERSION

This document describes
L<MooseX::Types::Locale::Country::Fast|MooseX::Types::Locale::Country::Fast>
version C<0.05>.

=head1 SYNOPSIS

    {
        package Foo;

        use Moose;
        use MooseX::Types::Locale::Country qw(
            CountryCode
            Alpha2Country
            Alpha3Country
            NumericCountry
            CountryName
        );

        has 'code'
            => ( isa => CountryCode,    is => 'rw' );
        has 'alpha2'
            => ( isa => Alpha2Country,  is => 'rw' );
        has 'alpha3'
            => ( isa => Alpha3Country,  is => 'rw' );
        has 'numeric'
            => ( isa => NumericCountry, is => 'rw' );
        has 'name'
            => ( isa => CountryName,    is => 'rw' );

        __PACKAGE__->meta->make_immutable;
    }

    my $foo = Foo->new(
        code    => 'jp',
        alpha2  => 'jp',
        alpha3  => 'jpn',
        numeric => 392,
        name    => 'JAPAN',
    );
    print $foo->code;       # 'jp' (not 'JP')
    print $foo->alpha2;     # 'jp' (not 'JP')
    print $foo->alpha3;     # 'jpn' (not 'JPN')
    print $foo->numeric;    # 392
    print $foo->name;       # 'JAPAN' (not 'Japan')

=head1 DESCRIPTION

This module packages several
L<Moose::Util::TypeConstraints|Moose::Util::TypeConstraints>,
designed to work with the values of L<Locale::Country|Locale::Country>.

This module does not provide you coercions.
Therefore, it works faster than
L<MooseX::Types::Locale::Country|MooseX::Types::Locale::Country>.

=head1 CONSTRAINTS

=over 4

=item C<Alpha2Country>

A subtype of C<Str>, which should be defined in country code of ISO 639-1
alpha-2.

=item C<CountryCode>

Alias of C<Alpha2Country>.

=item C<Alpha3Country>

A subtype of C<Str>, which should be defined in country code of ISO 3166-1
alpha-3.

=item C<NumericCountry>

A subtype of C<Int>, which should be defined in country code of ISO 3166-1
numeric.

=item C<CountryName>

A subtype of C<Str>, which should be defined in ISO 3166-1 country name.

=back

=head1 NOTE

=head2 The type mapping of L<MooseX::Getopt|MooseX::Getopt>

This module provides the optional type mapping of
L<MooseX::Getopt|MooseX::Getopt>
when L<MooseX::Getopt|MooseX::Getopt> was installed.

C<CountryCode>, C<Alpha2Country>, C<Alpha3Country> and C<CountryName> are
C<String> (C<"=s">) type.

C<NumericCountry> is C<Int> (C<"=i">) type.

=head1 SEE ALSO

=over 4

=item * L<Locale::Country|Locale::Country>

=item * L<MooseX::Types::Locale::Country|MooseX::Types::Locale::Country>

=item * L<MooseX::Types::Locale::Language::Fast|MooseX::Types::Locale::Language::Fast>

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head2 Making suggestions and reporting bugs

Please report any found bugs, feature requests, and ideas for improvements
to C<bug-moosex-types-locale-Country at rt.cpan.org>,
or through the web interface
at L<http://rt.cpan.org/Public/Bug/Report.html?Queue=MooseX-Types-Locale-Country>.
I will be notified, and then you'll automatically be notified of progress
on your bugs/requests as I make changes.

When reporting bugs, if possible,
please add as small a sample as you can make of the code
that produces the bug.
And of course, suggestions and patches are welcome.

=head1 SUPPORT

You can find documentation for this module with the C<perldoc> command.

    perldoc MooseX::Types::Locale::Country::Fast

You can also look for information at:

=over 4

=item RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Types-Locale-Country>

=item AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-Types-Locale-Country>

=item Search CPAN

L<http://search.cpan.org/dist/MooseX-Types-Locale-Country>

=item CPAN Ratings

L<http://cpanratings.perl.org/dist/MooseX-Types-Locale-Country>

=back

=head1 VERSION CONTROL

This module is maintained using I<git>.
You can get the latest version from
L<git://github.com/gardejo/p5-moosex-types-locale-Country.git>.

=head1 AUTHOR

=over 4

=item MORIYA Masaki, alias Gardejo

C<< <moriya at cpan dot org> >>,
L<http://gardejo.org/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009-2010 MORIYA Masaki, alias Gardejo

This library is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
See L<perlgpl|perlgpl> and L<perlartistic|perlartistic>.

The full text of the license can be found in the F<LICENSE> file
included with this distribution.

=cut
