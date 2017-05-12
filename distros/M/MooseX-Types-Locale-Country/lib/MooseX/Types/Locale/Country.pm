package MooseX::Types::Locale::Country;


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
# private class variable(s)
# ****************************************************************

# Because code2country($_) cannot coerce 'JP' to 'jp'.
my %alpha2;
@alpha2{ map { uc } all_country_codes(LOCALE_CODE_ALPHA_2) } = ();

my %alpha3;
@alpha3{ map { uc } all_country_codes(LOCALE_CODE_ALPHA_3) } = ();

# Because country2code($_) cannot coerce 'japanese' to 'Japanese'.
my %name;
@name{ all_country_names() } = ();


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
                exists $alpha2{$_};
            },
            message {
                sprintf 'Validation failed for code failed with value (%s) '
                      . 'because specified country code does not exist '
                      . 'in ISO 3166-1 alpha-2',
                    defined $_ ? $_ : q{};
            };

    coerce $subtype,
        from Str,
            via {
                # - Converts 'us' into 'US'.
                # - ISO 3166 recommended upper-case.
                return uc $_;
            };
}

# ----------------------------------------------------------------
# alpha-3 country code as defined in ISO 3166-1
# ----------------------------------------------------------------
subtype Alpha3Country,
    as Str,
        where {
            exists $alpha3{$_};
        },
        message {
            sprintf 'Validation failed for code failed with value (%s) '
                  . 'because specified country code does not exist '
                  . 'in ISO 3166-1 alpha-3',
                defined $_ ? $_ : q{};
        };

coerce Alpha3Country,
    from Str,
        via {
            # - Converts 'us' into 'US'.
            # - ISO 3166 recommended upper-case.
            return uc $_;
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
# country name as defined in ISO 3166-1
# ----------------------------------------------------------------
subtype CountryName,
    as Str,
        where {
            exists $name{$_};
        },
        message {
            sprintf 'Validation failed for name failed with value (%s) '
                  . 'because specified country name does not exist '
                  . 'in ISO 3166-1',
                defined $_ ? $_ : q{};
        };

coerce CountryName,
    from Str,
        via {
            # - Converts 'eNgLiSh' into 'English'.
            # - Cannot use 'ucfirst lc', because there is 'Rhaeto-Romance'.
            # - In case of invalid name, returns original $_
            #   to use it in exception message.
            return code2country( country2code($_) ) || $_;
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

MooseX::Types::Locale::Country - Locale::Country related constraints and coercions for Moose

=head1 VERSION

This document describes
L<MooseX::Types::Locale::Country|MooseX::Types::Locale::Country>
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
            => ( isa => CountryCode,    is => 'rw', coerce => 1 );
        has 'alpha2'
            => ( isa => Alpha2Country,  is => 'rw', coerce => 1 );
        has 'alpha3'
            => ( isa => Alpha3Country,  is => 'rw', coerce => 1 );
        has 'numeric'
            => ( isa => NumericCountry, is => 'rw' ); # you can't coerce
        has 'name'
            => ( isa => CountryName,    is => 'rw', coerce => 1 );

        __PACKAGE__->meta->make_immutable;
    }

    my $foo = Foo->new(
        code    => 'jp',
        alpha2  => 'jp',
        alpha3  => 'jpn',
        numeric => 392,
        name    => 'JAPAN',
    );
    print $foo->code;       # 'JP'
    print $foo->alpha2;     # 'JP'
    print $foo->alpha3;     # 'JPN'
    print $foo->numeric;    # 392
    print $foo->name;       # 'Japan'

=head1 DESCRIPTION

This module packages several
L<Moose::Util::TypeConstraints|Moose::Util::TypeConstraints> with coercions,
designed to work with the values of L<Locale::Country|Locale::Country>.

=head1 CONSTRAINTS AND COERCIONS

=over 4

=item C<Alpha2Country>

A subtype of C<Str>, which should be defined in country code of ISO 3166-1
alpha-2.
If you turned C<coerce> on, C<Str> will be upper-case.
For example, C<'jp'> will convert to C<'JP'>.

=item C<CountryCode>

Alias of C<Alpha2Country>.

=item C<Alpha3Country>

A subtype of C<Str>, which should be defined in country code of ISO 3166-1
alpha-3.
If you turned C<coerce> on, C<Str> will be upper-case.
For example, C<'jpn'> will convert to C<'JPN'>.

=item C<NumericCountry>

A subtype of C<Int>, which should be defined in country code of ISO 3166-1
numeric.

=item C<CountryName>

A subtype of C<Str>, which should be defined in ISO 3166-1 country name.
If you turned C<coerce> on, C<Str> will be same case as canonical name.
For example, C<'JAPAN'> will convert to C<'Japan'>.

=back

=head1 NOTE

=head2 Code conversion is not supported

These coercions is not support code conversion.
For example, from C<Alpha2Country> to C<Alpha3Country>.

    has country
        => ( is => 'rw', isa => Alpha2Country, coerce => 1 );

    ...

    $foo->country('US');    # does not convert to 'USA'

If you want conversion, could you implement an individual country class
with several attributes?

See C</examples/complex.pl> in the distribution for more details.

=head2 The type mapping of L<MooseX::Getopt|MooseX::Getopt>

This module provides you the optional type mapping of
L<MooseX::Getopt|MooseX::Getopt>
when L<MooseX::Getopt|MooseX::Getopt> was installed.

C<CountryCode>, C<Alpha2Country>, C<Alpha3Country> and C<CountryName> are
C<String> (C<"=s">) type.

C<NumericCountry> is C<Int> (C<"=i">) type.

=head1 SEE ALSO

=over 4

=item * L<Locale::Country|Locale::Country>

=item * L<MooseX::Types::Locale::Country::Fast|MooseX::Types::Locale::Country::Fast>

=item * L<MooseX::Types::Locale::Language|MooseX::Types::Locale::Language>

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 TO DO

=over 4

=item * I may add grammatical aliases of constraints/coercions.
        For example, C<CountryAsAlpha2> as existent C<Alpha2Country>.

=item * I may add namespased types.
        For example, C<'Locale::Country::Alpha2'> as export type
        C<Alpha2Country>.

=back

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head2 Making suggestions and reporting bugs

Please report any found bugs, feature requests, and ideas for improvements
to C<bug-moosex-types-locale-country at rt.cpan.org>,
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

    perldoc MooseX::Types::Locale::Country

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
L<git://github.com/gardejo/p5-moosex-types-locale-country.git>.

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
