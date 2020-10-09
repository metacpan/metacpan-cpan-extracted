package Regexp::Pattern::Float;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-27'; # DATE
our $DIST = 'Regexp-Pattern-Float'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
#use utf8;

our %RE;

$RE{float_decimal} = {
    summary => 'Floating number (decimal form, e.g. +12, -12.3, .4, -5.)',
    pat => qr/[+-]?(?:[0-9]+(?:\.[0-9]*)?|[0-9]*\.[0-9]+)/,
    examples => [
        {str=>'', anchor=>1, matches=>0},

        {str=>'123', anchor=>1, matches=>1},
        {str=>'+123', anchor=>1, matches=>1},
        {str=>'-123', anchor=>1, matches=>1},

        {str=>'123.', anchor=>1, matches=>1},
        {str=>'+123.', anchor=>1, matches=>1},
        {str=>'-123.', anchor=>1, matches=>1},

        {str=>'123.0', anchor=>1, matches=>1},
        {str=>'+123.0', anchor=>1, matches=>1},
        {str=>'-123.0', anchor=>1, matches=>1},

        {str=>'123.0456', anchor=>1, matches=>1},
        {str=>'+123.0456', anchor=>1, matches=>1},
        {str=>'-123.0456', anchor=>1, matches=>1},

        {str=>'.5', anchor=>1, matches=>1},
        {str=>'+.5', anchor=>1, matches=>1},
        {str=>'-.5', anchor=>1, matches=>1},

        {str=>'.', anchor=>1, matches=>0},
        {str=>'+.', anchor=>1, matches=>0},
        {str=>'-.', anchor=>1, matches=>0},

        {str=>'1e1', anchor=>1, matches=>0, summary=>'Exponent form'},
        {str=>'Inf', anchor=>1, matches=>0, summary=>'infinity'},
        {str=>'NaN', anchor=>1, matches=>0, summary=>'nan'},

        {str=>'abc', anchor=>1, matches=>0},
    ],
};

$RE{ufloat_decimal} = {
    summary => 'Unsigned floating number (decimal form, e.g. 12, +12.3, .4, 5.)',
    pat => qr/[+]?(?:[0-9]+(?:\.[0-9]*)?|[0-9]*\.[0-9]+)/,
    examples => [
        {str=>'', anchor=>1, matches=>0},

        {str=>'123', anchor=>1, matches=>1},
        {str=>'+123', anchor=>1, matches=>1},
        {str=>'-123', anchor=>1, matches=>0},

        {str=>'123.', anchor=>1, matches=>1},
        {str=>'+123.', anchor=>1, matches=>1},
        {str=>'-123.', anchor=>1, matches=>0},

        {str=>'123.0', anchor=>1, matches=>1},
        {str=>'+123.0', anchor=>1, matches=>1},
        {str=>'-123.0', anchor=>1, matches=>0},

        {str=>'123.0456', anchor=>1, matches=>1},
        {str=>'+123.0456', anchor=>1, matches=>1},
        {str=>'-123.0456', anchor=>1, matches=>0},

        {str=>'.5', anchor=>1, matches=>1},
        {str=>'+.5', anchor=>1, matches=>1},
        {str=>'-.5', anchor=>1, matches=>0},

        {str=>'.', anchor=>1, matches=>0},
        {str=>'+.', anchor=>1, matches=>0},
        {str=>'-.', anchor=>1, matches=>0},

        {str=>'1e1', anchor=>1, matches=>0, summary=>'Exponent form'},
        {str=>'Inf', anchor=>1, matches=>0, summary=>'infinity'},
        {str=>'NaN', anchor=>1, matches=>0, summary=>'nan'},
    ],
};

$RE{float_exp} = {
    summary => 'Floating number (exponent form, e.g. 1.2e+3, -1.2e-3)',
    pat => qr/[+-]?(?:[0-9]+(?:\.[0-9]*)?|[0-9]*\.[0-9]+)(?:[Ee][+-]?[0-9])/,
    examples => [
        {str=>'', anchor=>1, matches=>0},

        {str=>'123', anchor=>1, matches=>0, summary=>'Decimal form'},
        {str=>'+123', anchor=>1, matches=>0, summary=>'Decimal form'},
        {str=>'-123', anchor=>1, matches=>0, summary=>'Decimal form'},

        {str=>'123e1', anchor=>1, matches=>1},
        {str=>'12.3E2', anchor=>1, matches=>1},
        {str=>'-123.e+3', anchor=>1, matches=>1},
        {str=>'+.5e-3', anchor=>1, matches=>1},

        {str=>'Inf', anchor=>1, matches=>0, summary=>'infinity'},
        {str=>'NaN', anchor=>1, matches=>0, summary=>'nan'},
    ],
};

$RE{float_decimal_or_exp} = {
    summary => 'Floating number (decimal or exponent form)',
    pat => qr/[+-]?(?:[0-9]+(?:\.[0-9]*)?|[0-9]*\.[0-9]+)(?:[Ee][+-]?[0-9])?/,
    examples => [
        {str=>'', anchor=>1, matches=>0},

        {str=>'123', anchor=>1, matches=>1},
        {str=>'+123.', anchor=>1, matches=>1},
        {str=>'+12.3', anchor=>1, matches=>1},
        {str=>'-.123', anchor=>1, matches=>1},

        {str=>'123e1', anchor=>1, matches=>1},
        {str=>'123.e2', anchor=>1, matches=>1},
        {str=>'-1.23E+3', anchor=>1, matches=>1},
        {str=>'+.5e-3', anchor=>1, matches=>1},

        {str=>'Inf', anchor=>1, matches=>0, summary=>'infinity'},
        {str=>'NaN', anchor=>1, matches=>0, summary=>'nan'},
    ],
};

$RE{float_inf} = {
    summary => 'Infinity',
    pat => qr/[+-]?(?:infinity|inf)/i,
    examples => [
        {str=>'', anchor=>1, matches=>0},
        {str=>'123', anchor=>1, matches=>0},
        {str=>'Inf', anchor=>1, matches=>1},
        {str=>'-Inf', anchor=>1, matches=>1},
        {str=>'+infinity', anchor=>1, matches=>1},
        {str=>'infini', anchor=>1, matches=>0},
        {str=>'NaN', anchor=>1, matches=>0, summary=>'nan'},
    ],
};

$RE{float_nan} = {
    summary => 'NaN',
    pat => qr/nan/i,
    examples => [
        {str=>'', anchor=>1, matches=>0},
        {str=>'123', anchor=>1, matches=>0},
        {str=>'Inf', anchor=>1, matches=>0, summary=>'infinity'},
        {str=>'NaN', anchor=>1, matches=>1, summary=>'nan'},
        {str=>'nan', anchor=>1, matches=>1, summary=>'nan'},
        {str=>'+NaN', anchor=>1, matches=>0, summary=>'nan does not recognize sign'},
        {str=>'-NaN', anchor=>1, matches=>0, summary=>'nan does not recognize sign'},
    ],
};

$RE{float} = {
    summary => 'Floating number (decimal or exponent form, or Inf/NaN)',
    pat => qr/(?:[+-]?(?:[0-9]+(?:\.[0-9]*)?|[0-9]*\.[0-9]+)(?:[Ee][+-]?[0-9])?|[+-]?(?:infinity|inf)|nan)/i, # XXX only set inf/nan parts as case-insensitive
    examples => [
        {str=>'', anchor=>1, matches=>0},

        # decimal
        {str=>'123', anchor=>1, matches=>1},
        {str=>'+123.', anchor=>1, matches=>1},
        {str=>'+12.3', anchor=>1, matches=>1},
        {str=>'-.123', anchor=>1, matches=>1},

        # exp
        {str=>'123e1', anchor=>1, matches=>1},
        {str=>'123.e2', anchor=>1, matches=>1},
        {str=>'-1.23E+3', anchor=>1, matches=>1},
        {str=>'+.5e-3', anchor=>1, matches=>1},

        # inf
        {str=>'Inf', anchor=>1, matches=>1},
        {str=>'-Inf', anchor=>1, matches=>1},
        {str=>'+infinity', anchor=>1, matches=>1},
        {str=>'infini', anchor=>1, matches=>0},

        # nan
        {str=>'NaN', anchor=>1, matches=>1, summary=>'nan'},
        {str=>'nan', anchor=>1, matches=>1, summary=>'nan'},
        {str=>'+NaN', anchor=>1, matches=>0, summary=>'nan does not recognize sign'},
        {str=>'-NaN', anchor=>1, matches=>0, summary=>'nan does not recognize sign'},

        {str=>'abc', anchor=>1, matches=>0},
    ],
};

$RE{ufloat} = {
    summary => 'Unsigned floating number (decimal or exponent form, or Inf/NaN)',
    pat => qr/(?:[+]?(?:[0-9]+(?:\.[0-9]*)?|[0-9]*\.[0-9]+)(?:[Ee][+-]?[0-9])?|[+]?(?:infinity|inf)|nan)/i, # XXX only set inf/nan parts as case-insensitive
    examples => [
        {str=>'', anchor=>1, matches=>0},

        # decimal
        {str=>'123', anchor=>1, matches=>1},
        {str=>'+123.', anchor=>1, matches=>1},
        {str=>'+12.3', anchor=>1, matches=>1},
        {str=>'-.123', anchor=>1, matches=>0},

        # exp
        {str=>'123e1', anchor=>1, matches=>1},
        {str=>'123.e2', anchor=>1, matches=>1},
        {str=>'-1.23E+3', anchor=>1, matches=>0},
        {str=>'+.5e-3', anchor=>1, matches=>1},

        # inf
        {str=>'Inf', anchor=>1, matches=>1},
        {str=>'-Inf', anchor=>1, matches=>0},
        {str=>'+infinity', anchor=>1, matches=>1},
        {str=>'infini', anchor=>1, matches=>0},

        # nan
        {str=>'NaN', anchor=>1, matches=>1, summary=>'nan'},
        {str=>'nan', anchor=>1, matches=>1, summary=>'nan'},
        {str=>'+NaN', anchor=>1, matches=>0, summary=>'nan does not recognize sign'},
        {str=>'-NaN', anchor=>1, matches=>0, summary=>'nan does not recognize sign'},

        {str=>'abc', anchor=>1, matches=>0},
    ],
};

1;
# ABSTRACT: Regexp patterns related to floating (decimal) numbers

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::Float - Regexp patterns related to floating (decimal) numbers

=head1 VERSION

This document describes version 0.001 of Regexp::Pattern::Float (from Perl distribution Regexp-Pattern-Float), released on 2020-05-27.

=head1 SYNOPSIS

 use Regexp::Pattern; # exports re()
 my $re = re("Float::float");

=head1 DESCRIPTION

L<Regexp::Pattern> is a convention for organizing reusable regex patterns.

=head1 PATTERNS

=over

=item * float

Floating number (decimal or exponent form, or InfE<sol>NaN).

Examples:

 "" =~ re("Float::float");  # DOESN'T MATCH

 123 =~ re("Float::float");  # matches

 "+123." =~ re("Float::float");  # matches

 "+12.3" =~ re("Float::float");  # matches

 "-.123" =~ re("Float::float");  # matches

 "123e1" =~ re("Float::float");  # matches

 "123.e2" =~ re("Float::float");  # matches

 "-1.23E+3" =~ re("Float::float");  # matches

 "+.5e-3" =~ re("Float::float");  # matches

 "Inf" =~ re("Float::float");  # matches

 "-Inf" =~ re("Float::float");  # matches

 "+infinity" =~ re("Float::float");  # matches

 "infini" =~ re("Float::float");  # DOESN'T MATCH

nan.

 "NaN" =~ re("Float::float");  # matches

nan.

 "nan" =~ re("Float::float");  # matches

nan does not recognize sign.

 "+NaN" =~ re("Float::float");  # DOESN'T MATCH

nan does not recognize sign.

 "-NaN" =~ re("Float::float");  # DOESN'T MATCH

 "abc" =~ re("Float::float");  # DOESN'T MATCH

=item * float_decimal

Floating number (decimal form, e.g. +12, -12.3, .4, -5.).

Examples:

 "" =~ re("Float::float_decimal");  # DOESN'T MATCH

 123 =~ re("Float::float_decimal");  # matches

 "+123" =~ re("Float::float_decimal");  # matches

 -123 =~ re("Float::float_decimal");  # matches

 "123." =~ re("Float::float_decimal");  # matches

 "+123." =~ re("Float::float_decimal");  # matches

 "-123." =~ re("Float::float_decimal");  # matches

 "123.0" =~ re("Float::float_decimal");  # matches

 "+123.0" =~ re("Float::float_decimal");  # matches

 "-123.0" =~ re("Float::float_decimal");  # matches

 123.0456 =~ re("Float::float_decimal");  # matches

 "+123.0456" =~ re("Float::float_decimal");  # matches

 -123.0456 =~ re("Float::float_decimal");  # matches

 ".5" =~ re("Float::float_decimal");  # matches

 "+.5" =~ re("Float::float_decimal");  # matches

 "-.5" =~ re("Float::float_decimal");  # matches

 "." =~ re("Float::float_decimal");  # DOESN'T MATCH

 "+." =~ re("Float::float_decimal");  # DOESN'T MATCH

 "-." =~ re("Float::float_decimal");  # DOESN'T MATCH

Exponent form.

 "1e1" =~ re("Float::float_decimal");  # DOESN'T MATCH

infinity.

 "Inf" =~ re("Float::float_decimal");  # DOESN'T MATCH

nan.

 "NaN" =~ re("Float::float_decimal");  # DOESN'T MATCH

 "abc" =~ re("Float::float_decimal");  # DOESN'T MATCH

=item * float_decimal_or_exp

Floating number (decimal or exponent form).

Examples:

 "" =~ re("Float::float_decimal_or_exp");  # DOESN'T MATCH

 123 =~ re("Float::float_decimal_or_exp");  # matches

 "+123." =~ re("Float::float_decimal_or_exp");  # matches

 "+12.3" =~ re("Float::float_decimal_or_exp");  # matches

 "-.123" =~ re("Float::float_decimal_or_exp");  # matches

 "123e1" =~ re("Float::float_decimal_or_exp");  # matches

 "123.e2" =~ re("Float::float_decimal_or_exp");  # matches

 "-1.23E+3" =~ re("Float::float_decimal_or_exp");  # matches

 "+.5e-3" =~ re("Float::float_decimal_or_exp");  # matches

infinity.

 "Inf" =~ re("Float::float_decimal_or_exp");  # DOESN'T MATCH

nan.

 "NaN" =~ re("Float::float_decimal_or_exp");  # DOESN'T MATCH

=item * float_exp

Floating number (exponent form, e.g. 1.2e+3, -1.2e-3).

Examples:

 "" =~ re("Float::float_exp");  # DOESN'T MATCH

Decimal form.

 123 =~ re("Float::float_exp");  # DOESN'T MATCH

Decimal form.

 "+123" =~ re("Float::float_exp");  # DOESN'T MATCH

Decimal form.

 -123 =~ re("Float::float_exp");  # DOESN'T MATCH

 "123e1" =~ re("Float::float_exp");  # matches

 "12.3E2" =~ re("Float::float_exp");  # matches

 "-123.e+3" =~ re("Float::float_exp");  # matches

 "+.5e-3" =~ re("Float::float_exp");  # matches

infinity.

 "Inf" =~ re("Float::float_exp");  # DOESN'T MATCH

nan.

 "NaN" =~ re("Float::float_exp");  # DOESN'T MATCH

=item * float_inf

Infinity.

Examples:

 "" =~ re("Float::float_inf");  # DOESN'T MATCH

 123 =~ re("Float::float_inf");  # DOESN'T MATCH

 "Inf" =~ re("Float::float_inf");  # matches

 "-Inf" =~ re("Float::float_inf");  # matches

 "+infinity" =~ re("Float::float_inf");  # matches

 "infini" =~ re("Float::float_inf");  # DOESN'T MATCH

nan.

 "NaN" =~ re("Float::float_inf");  # DOESN'T MATCH

=item * float_nan

NaN.

Examples:

 "" =~ re("Float::float_nan");  # DOESN'T MATCH

 123 =~ re("Float::float_nan");  # DOESN'T MATCH

infinity.

 "Inf" =~ re("Float::float_nan");  # DOESN'T MATCH

nan.

 "NaN" =~ re("Float::float_nan");  # matches

nan.

 "nan" =~ re("Float::float_nan");  # matches

nan does not recognize sign.

 "+NaN" =~ re("Float::float_nan");  # DOESN'T MATCH

nan does not recognize sign.

 "-NaN" =~ re("Float::float_nan");  # DOESN'T MATCH

=item * ufloat

Unsigned floating number (decimal or exponent form, or InfE<sol>NaN).

Examples:

 "" =~ re("Float::ufloat");  # DOESN'T MATCH

 123 =~ re("Float::ufloat");  # matches

 "+123." =~ re("Float::ufloat");  # matches

 "+12.3" =~ re("Float::ufloat");  # matches

 "-.123" =~ re("Float::ufloat");  # DOESN'T MATCH

 "123e1" =~ re("Float::ufloat");  # matches

 "123.e2" =~ re("Float::ufloat");  # matches

 "-1.23E+3" =~ re("Float::ufloat");  # DOESN'T MATCH

 "+.5e-3" =~ re("Float::ufloat");  # matches

 "Inf" =~ re("Float::ufloat");  # matches

 "-Inf" =~ re("Float::ufloat");  # DOESN'T MATCH

 "+infinity" =~ re("Float::ufloat");  # matches

 "infini" =~ re("Float::ufloat");  # DOESN'T MATCH

nan.

 "NaN" =~ re("Float::ufloat");  # matches

nan.

 "nan" =~ re("Float::ufloat");  # matches

nan does not recognize sign.

 "+NaN" =~ re("Float::ufloat");  # DOESN'T MATCH

nan does not recognize sign.

 "-NaN" =~ re("Float::ufloat");  # DOESN'T MATCH

 "abc" =~ re("Float::ufloat");  # DOESN'T MATCH

=item * ufloat_decimal

Unsigned floating number (decimal form, e.g. 12, +12.3, .4, 5.).

Examples:

 "" =~ re("Float::ufloat_decimal");  # DOESN'T MATCH

 123 =~ re("Float::ufloat_decimal");  # matches

 "+123" =~ re("Float::ufloat_decimal");  # matches

 -123 =~ re("Float::ufloat_decimal");  # DOESN'T MATCH

 "123." =~ re("Float::ufloat_decimal");  # matches

 "+123." =~ re("Float::ufloat_decimal");  # matches

 "-123." =~ re("Float::ufloat_decimal");  # DOESN'T MATCH

 "123.0" =~ re("Float::ufloat_decimal");  # matches

 "+123.0" =~ re("Float::ufloat_decimal");  # matches

 "-123.0" =~ re("Float::ufloat_decimal");  # DOESN'T MATCH

 123.0456 =~ re("Float::ufloat_decimal");  # matches

 "+123.0456" =~ re("Float::ufloat_decimal");  # matches

 -123.0456 =~ re("Float::ufloat_decimal");  # DOESN'T MATCH

 ".5" =~ re("Float::ufloat_decimal");  # matches

 "+.5" =~ re("Float::ufloat_decimal");  # matches

 "-.5" =~ re("Float::ufloat_decimal");  # DOESN'T MATCH

 "." =~ re("Float::ufloat_decimal");  # DOESN'T MATCH

 "+." =~ re("Float::ufloat_decimal");  # DOESN'T MATCH

 "-." =~ re("Float::ufloat_decimal");  # DOESN'T MATCH

Exponent form.

 "1e1" =~ re("Float::ufloat_decimal");  # DOESN'T MATCH

infinity.

 "Inf" =~ re("Float::ufloat_decimal");  # DOESN'T MATCH

nan.

 "NaN" =~ re("Float::ufloat_decimal");  # DOESN'T MATCH

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern-Float>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern-Float>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern-Float>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Regexp::Pattern::Int>

L<Sah> schemas in L<Sah::Schemas::Float>, e.g. L<Sah::Schema::ufloat>

L<Regexp::Pattern>

Some utilities related to Regexp::Pattern: L<App::RegexpPatternUtils>, L<rpgrep> from L<App::rpgrep>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
