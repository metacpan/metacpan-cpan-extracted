package MooseX::Types::Locale::Language;


# ****************************************************************
# general dependency(-ies)
# ****************************************************************

use 5.008_001;
# MooseX::Types turns strict/warnings pragmas on,
# however, kwalitee scorer can not detect such mechanism.
# (Perl::Critic can it, with equivalent_modules parameter)
use strict;
use warnings;

use Locale::Language;
use MooseX::Types::Moose qw(
    Str
);
use MooseX::Types (
    -declare => [qw(
        LanguageCode
        Alpha2Language
        BibliographicLanguage
        Alpha3Language
        TerminologicLanguage
        LanguageName
    )],
);


# ****************************************************************
# namespace clearer
# ****************************************************************

use namespace::clean;


# ****************************************************************
# public class variable(s)
# ****************************************************************

our $VERSION = "0.07";


# ****************************************************************
# private class variable(s)
# ****************************************************************

# Because language2code($_) cannot coerce 'japanese' to 'Japanese'.
my %alpha2;
@alpha2{ all_language_codes() } = ();

my %bibliographic;
@bibliographic{ all_language_codes(LOCALE_LANG_ALPHA_3) } = ();

my %terminologic;
@terminologic{ all_language_codes(LOCALE_LANG_TERM) } = ();

# Because code2language($_) cannot coerce 'JA' to 'ja'.
my %name;
@name{ all_language_names() } = ();


# ****************************************************************
# subtype(s) and coercion(s)
# ****************************************************************

# ----------------------------------------------------------------
# language code as defined in ISO 639-1 (alpha-2)
# ----------------------------------------------------------------
foreach my $subtype (LanguageCode, Alpha2Language) {
    subtype $subtype,
        as Str,
            where {
                exists $alpha2{$_};
            },
            message {
                sprintf 'Validation failed for code failed with value (%s) '
                       .'because specified language code does not exist '
                       . 'in ISO 639-1',
                    defined $_ ? $_ : q{};
            };

    coerce $subtype,
        from Str,
            via {
                # - Converts 'EN' into 'en'.
                # - ISO 639 recommended lower-case.
                return lc $_;
            };
}

# ----------------------------------------------------------------
# language code as defined in ISO 639-2 (alpha-3 bibliographic)
# ----------------------------------------------------------------
foreach my $subtype (Alpha3Language, BibliographicLanguage) {
    subtype $subtype,
        as Str,
            where {
                exists $bibliographic{$_};
            },
            message {
                sprintf 'Validation failed for code failed with value (%s) '
                      . 'because specified language code does not exist '
                      . 'in ISO 639-2 (bibliographic)',
                    defined $_ ? $_ : q{};
            };

    coerce $subtype,
        from Str,
            via {
                # Converts 'ENG' into 'eng'.
                return lc $_;
            };
}

# ----------------------------------------------------------------
# language code as defined in ISO 639-2 (alpha-3 terminologic)
# ----------------------------------------------------------------
subtype TerminologicLanguage,
    as Str,
        where {
            exists $terminologic{$_};
        },
        message {
            sprintf 'Validation failed for code failed with value (%s) '
                  . 'because specified language code does not exist '
                  . 'in ISO 639-2 (terminologic)',
                defined $_ ? $_ : q{};
        };

coerce TerminologicLanguage,
    from Str,
        via {
            # Converts 'ENG' into 'eng'.
            return lc $_;
        };

# ----------------------------------------------------------------
# language name as defined in ISO 639
# ----------------------------------------------------------------
subtype LanguageName,
    as Str,
        where {
            exists $name{$_};
        },
        message {
            sprintf 'Validation failed for name failed with value (%s) '
                  . 'because specified language name does not exist '
                  . 'in ISO 639',
                defined $_ ? $_ : q{};
        };

coerce LanguageName,
    from Str,
        via {
            # - Converts 'eNgLiSh' into 'English'.
            # - Cannot use 'ucfirst lc', because there is 'Rhaeto-Romance'.
            # - In case of invalid name, returns original $_
            #   to use it in exception message.
            return code2language( language2code($_) ) || $_;
        };


# ****************************************************************
# optionally add Getopt option type
# ****************************************************************

eval { require MooseX::Getopt; };
if (!$@) {
    MooseX::Getopt::OptionTypeMap->add_option_type_to_map( $_, '=s', )
        for (LanguageCode, Alpha2Language, LanguageName);
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

MooseX::Types::Locale::Language - Locale::Language related constraints and coercions for Moose

=head1 VERSION

This document describes
L<MooseX::Types::Locale::Language|MooseX::Types::Locale::Language>
version C<0.07>.

=head1 SYNOPSIS

    {
        package Foo;

        use Moose;
        use MooseX::Types::Locale::Language qw(
            LanguageCode
            LanguageName
        );

        has 'code'
            => ( isa => LanguageCode, is => 'rw', coerce => 1 );
        has 'name'
            => ( isa => LanguageName, is => 'rw', coerce => 1 );

        __PACKAGE__->meta->make_immutable;
    }

    my $foo = Foo->new(
        code => 'JA',
        name => 'JAPANESE',
    );
    print $foo->code;   # 'ja'
    print $foo->name;   # 'Japanese'

=head1 DESCRIPTION

This module packages several
L<Moose::Util::TypeConstraints|Moose::Util::TypeConstraints> with coercions,
designed to work with the values of L<Locale::Language|Locale::Language>.

=head1 CONSTRAINTS AND COERCIONS

=over 4

=item C<Alpha2Language>

A subtype of C<Str>, which should be defined in language code of ISO 639-1
alpha-2.
If you turned C<coerce> on, C<Str> will be lower-case.
For example, C<'JA'> will convert to C<'ja'>.

=item C<LanguageCode>

Alias of C<Alpha2Language>.

=item C<BibliographicLanguage>

A subtype of C<Str>, which should be defined in language code of ISO 639-2/B
alpha-3.
If you turned C<coerce> on, C<Str> will be lower-case.
For example, C<'CHI'> will convert to C<'chi'>.

=item C<Alpha3Language>

Alias of C<BibliographicLanguage>.

=item C<TerminologicLanguage>

A subtype of C<Str>, which should be defined in language code of ISO 639-2/T
alpha-3.
If you turned C<coerce> on, C<Str> will be lower-case.
For example, C<'ZHO'> will convert to C<'zho'>.

=item C<LanguageName>

A subtype of C<Str>, which should be defined in ISO 639-1 language name.
If you turned C<coerce> on, C<Str> will be same case as canonical name.
For example, C<'JAPANESE'> will convert to C<'Japanese'>.

=back

=head1 NOTE

=head2 Code conversion is not supported

These coercions is not support code conversion.
For example, from C<Alpha2Language> to C<LanguageName>.

    has language
        => ( is => 'rw', isa => LanguageName, coerce => 1 );

    ...

    $foo->language('en');   # does not convert to 'English'

If you want conversion, could you implement an individual language class
with several attributes?

See C</examples/complex.pl> in the distribution for more details.

=head2 The type mapping of L<MooseX::Getopt|MooseX::Getopt>

This module provides you the optional type mapping of
L<MooseX::Getopt|MooseX::Getopt>
when L<MooseX::Getopt|MooseX::Getopt> was installed.

C<LanguageCode>, C<Alpha2Language> and C<LanguageName> are
C<String> (C<"=s">) type.

=head1 SEE ALSO

=over 4

=item * L<Locale::Language|Locale::Language>

=item * L<MooseX::Types::Locale::Language::Fast|MooseX::Types::Locale::Language::Fast>

=item * L<MooseX::Types::Locale::Country|MooseX::Types::Locale::Country>

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 TO DO

=over 4

=item * I may add grammatical aliases of constraints/coercions.
        For example, C<LanguageAsAlpha2> as existent C<Alpha2Language>.

=item * I may add namespased types.
        For example, C<'Locale::Language::Alpha2'> as export type
        C<Alpha2Language>.

=back

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head2 Making suggestions and reporting bugs

Please report any found bugs, feature requests, and ideas for improvements
to C<bug-moosex-types-locale-language at rt.cpan.org>,
or through the web interface
at L<http://rt.cpan.org/Public/Bug/Report.html?Queue=MooseX-Types-Locale-Language>.
I will be notified, and then you'll automatically be notified of progress
on your bugs/requests as I make changes.

When reporting bugs, if possible,
please add as small a sample as you can make of the code
that produces the bug.
And of course, suggestions and patches are welcome.

=head1 SUPPORT

You can find documentation for this module with the C<perldoc> command.

    perldoc MooseX::Types::Locale::Language

You can also look for information at:

=over 4

=item RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Types-Locale-Language>

=item AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-Types-Locale-Language>

=item Search CPAN

L<http://search.cpan.org/dist/MooseX-Types-Locale-Language>

=item CPAN Ratings

L<http://cpanratings.perl.org/dist/MooseX-Types-Locale-Language>

=back

=head1 VERSION CONTROL

This module is maintained using I<git>.
You can get the latest version from
L<git://github.com/gardejo/p5-moosex-types-locale-language.git>.

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
