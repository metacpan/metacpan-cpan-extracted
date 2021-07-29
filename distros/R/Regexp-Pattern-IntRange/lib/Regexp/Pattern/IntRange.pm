package Regexp::Pattern::IntRange;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-17'; # DATE
our $DIST = 'Regexp-Pattern-IntRange'; # DIST
our $VERSION = '0.001'; # VERSION

#use 5.010001;
use strict;
use warnings;
#use utf8;

our %RE;

$RE{simple_int_range} = {
    summary => 'Simple integer range, e.g. 1-10 / -2-7',
    description => <<'_',

Currently does not check that start value must not be greater than end value.

_
    pat => qr/(-?[0-9]+)\s*-\s*(-?[0-9]+)/,
    tags => ['capturing'],
    examples => [
        {str=>'', matches=>0, summary=>'Empty string'},
        {str=>'1', anchor=>1, mtaches=>0, summary=>'Not a range but single positive integer'},
        {str=>'-2', anchor=>1, matches=>0, summary=>'Not a range but single negative integer'},

        {str=>'1-1', anchor=>1, matches=>1},
        {str=>'1-2', anchor=>1, matches=>1},
        {str=>'1 - 2', anchor=>1, matches=>1},
        {str=>'0-100', anchor=>1, matches=>1},
        {str=>'-1-2', anchor=>1, matches=>1},
        {str=>'-10--1', anchor=>1, matches=>1},

        {str=>'1-', anchor=>1, matches=>0, summary=>'Missing end value'},
        {str=>'1-1.5', anchor=>1, matches=>0, sumary=>'Float'},
        #{str=>'9-2', anchor=>1, matches=>0, summary=>'start value cannot be larger than end value'},
        {str=>'1-2-3', anchor=>1, matches=>0, summary=>'Invalid syntax'},
        {str=>' 1-2 ', anchor=>1, matches=>0, summary=>'Leading and trailing whitespace is currently not allowed'},
    ],
};

$RE{simple_uint_range} = {
    summary => 'Simple unsigned integer range, e.g. 1-10 / 2-7',
    description => <<'_',

Currently does not check that start value must not be greater than end value.

_
    pat => qr/([0-9]+)\s*-\s*([0-9]+)/,
    tags => ['capturing'],
    examples => [
        {str=>'', matches=>0, summary=>'Empty string'},
        {str=>'1', anchor=>1, mtaches=>0, summary=>'Not a range but single positive integer'},
        {str=>'-2', anchor=>1, matches=>0, summary=>'Not a range but single negative integer'},

        {str=>'1-1', anchor=>1, matches=>1},
        {str=>'1-2', anchor=>1, matches=>1},
        {str=>'1 - 2', anchor=>1, matches=>1},
        {str=>'0-100', anchor=>1, matches=>1},
        {str=>'-1-2', anchor=>1, matches=>0,
         summary=>'Negative'},
        {str=>'-10--1', anchor=>1, matches=>0,
         summary=>'Negative'},

        {str=>'1-', anchor=>1, matches=>0, summary=>'Missing end value'},
        {str=>'1-1.5', anchor=>1, matches=>0, sumary=>'Float'},
        #{str=>'9-2', anchor=>1, matches=>0, summary=>'start value cannot be larger than end value'},
        {str=>'1-2-3', anchor=>1, matches=>0, summary=>'Invalid syntax'},
        {str=>' 1-2 ', anchor=>1, matches=>0, summary=>'Leading and trailing whitespace is currently not allowed'},
    ],
};

$RE{simple_int_seq} = {
    summary => 'Simple integer sequence, e.g. 1,-3,12',
    description => <<'_',

_
    pat => qr/(?:-?[0-9]+)(?:\s*,\s*(?:-?[0-9]+))*/,
    examples => [
        {str=>'', anchor=>1, matches=>0, summary=>'Empty string'},
        {str=>'1-2', anchor=>1, matches=>0, summary=>'A range m-n is not valid in simple integer sequence'},
        {str=>'1,', anchor=>1, matches=>0, summary=>'Dangling comma is currently not allowed'},
        {str=>'1,,2', anchor=>1, matches=>0, summary=>'Multiple commas are currently not allowed'},
        {str=>'1.2', anchor=>1, matches=>0, summary=>'Float'},

        {str=>'1', anchor=>1, matches=>1},
        {str=>'1,2', anchor=>1, matches=>1},
        {str=>'1 , 2', anchor=>1, matches=>1},
        {str=>'1,2,-3,4', anchor=>1, matches=>1},
    ],
};

$RE{simple_uint_seq} = {
    summary => 'Simple unsigned integer sequence, e.g. 1,3,12',
    description => <<'_',

_
    pat => qr/(?:[0-9]+)(?:\s*,\s*(?:[0-9]+))*/,
    examples => [
        {str=>'', anchor=>1, matches=>0, summary=>'Empty string'},
        {str=>'1-2', anchor=>1, matches=>0, summary=>'A range m-n is not valid in simple integer sequence'},
        {str=>'1,', anchor=>1, matches=>0, summary=>'Dangling comma is currently not allowed'},
        {str=>'1,,2', anchor=>1, matches=>0, summary=>'Multiple commas are currently not allowed'},
        {str=>'1.2', anchor=>1, matches=>0, summary=>'Float'},

        {str=>'1', anchor=>1, matches=>1},
        {str=>'1,2', anchor=>1, matches=>1},
        {str=>'1 , 2', anchor=>1, matches=>1},
        {str=>'1,2,-3,4', anchor=>1, matches=>0,
         summary=>'Negative'},
    ],
};

$RE{int_range} = {
    summary => 'Integer range (sequence of ints/simple ranges), e.g. 1 / -5-7 / 1,10 / 1,5-7,10',
    description => <<'_',

Currently does not check that start value in a simple range must not be greater
than end value.

_
    pat => qr/
                 (?:(?:-?[0-9]+)(?:\s*-\s*(?:-?[0-9]+))?)
                 (
                     \s*,\s*
                     (?:(?:-?[0-9]+)(?:\s*-\s*(?:-?[0-9]+))?)
                 )*
             /x,
    examples => [
        {str=>'', anchor=>1, matches=>0, summary=>'Empty string'},

        # single int

        {str=>'1', anchor=>1, matches=>1},
        {str=>'-2', anchor=>1, matches=>1},

        {str=>'1.5', anchor=>1, matches=>0, summary=>'Float'},

        # simple int range

        {str=>'1-1', anchor=>1, matches=>1},
        {str=>'1-2', anchor=>1, matches=>1},
        {str=>'1 - 2', anchor=>1, matches=>1},
        {str=>'0-100', anchor=>1, matches=>1},
        {str=>'-1-2', anchor=>1, matches=>1},
        {str=>'-10--1', anchor=>1, matches=>1},

        {str=>'1-', anchor=>1, matches=>0, summary=>'Missing end value'},
        {str=>'1-1.5', anchor=>1, matches=>0, sumary=>'Float'},
        #{str=>'9-2', anchor=>1, matches=>0, summary=>'start value cannot be larger than end value'},
        {str=>'1-2-3', anchor=>1, matches=>0, summary=>'Invalid simple int range syntax'},
        {str=>' 1-2 ', anchor=>1, matches=>0, summary=>'Leading and trailing whitespace is currently not allowed'},

        # simple int seq

        {str=>'1,2', anchor=>1, matches=>1},
        {str=>'1 , 2', anchor=>1, matches=>1},
        {str=>'1,2,-3,4', anchor=>1, matches=>1},

        {str=>'1,2,-3,4.5', anchor=>1, matches=>0, summary=>'Float'},
        {str=>'1,', anchor=>1, matches=>0, summary=>'Dangling comma is currently not allowed'},
        {str=>'1,,2', anchor=>1, matches=>0, summary=>'Multiple commas are currently not allowed'},

        # seq of ints/simple int ranges

        {str=>'1,2-5', anchor=>1, matches=>1},
        {str=>'-1,-2-5,7,9-9', anchor=>1, matches=>1},

        #{str=>'1,9-2', anchor=>1, matches=>0, summary=>'start value cannot be larger than end value'},

    ],
};

$RE{uint_range} = {
    summary => 'Unsigned integer range (sequence of uints/simple ranges), e.g. 1 / 5-7 / 1,10 / 1,5-7,10',
    description => <<'_',

Currently does not check that start value in a simple range must not be greater
than end value.

_
    pat => qr/
                 (?:(?:[0-9]+)(?:\s*-\s*(?:[0-9]+))?)
                 (
                     \s*,\s*
                     (?:(?:[0-9]+)(?:\s*-\s*(?:[0-9]+))?)
                 )*
             /x,
    examples => [
        {str=>'', anchor=>1, matches=>0, summary=>'Empty string'},

        # single int

        {str=>'1', anchor=>1, matches=>1},
        {str=>'-2', anchor=>1, matches=>0,
         summary=>'Negative'},

        {str=>'1.5', anchor=>1, matches=>0, summary=>'Float'},

        # simple int range

        {str=>'1-1', anchor=>1, matches=>1},
        {str=>'1-2', anchor=>1, matches=>1},
        {str=>'1 - 2', anchor=>1, matches=>1},
        {str=>'0-100', anchor=>1, matches=>1},
        {str=>'-1-2', anchor=>1, matches=>0,
         summary=>'Negative'},
        {str=>'-10--1', anchor=>1, matches=>0,
         summary=>'Negative'},

        {str=>'1-', anchor=>1, matches=>0, summary=>'Missing end value'},
        {str=>'1-1.5', anchor=>1, matches=>0, sumary=>'Float'},
        #{str=>'9-2', anchor=>1, matches=>0, summary=>'start value cannot be larger than end value'},
        {str=>'1-2-3', anchor=>1, matches=>0, summary=>'Invalid simple int range syntax'},
        {str=>' 1-2 ', anchor=>1, matches=>0, summary=>'Leading and trailing whitespace is currently not allowed'},

        # simple int seq

        {str=>'1,2', anchor=>1, matches=>1},
        {str=>'1 , 2', anchor=>1, matches=>1},
        {str=>'1,2,-3,4', anchor=>1, matches=>0,
         summary=>'Negative'},

        {str=>'1,2,-3,4.5', anchor=>1, matches=>0, summary=>'Float'},
        {str=>'1,', anchor=>1, matches=>0, summary=>'Dangling comma is currently not allowed'},
        {str=>'1,,2', anchor=>1, matches=>0, summary=>'Multiple commas are currently not allowed'},

        # seq of ints/simple int ranges

        {str=>'1,2-5', anchor=>1, matches=>1},
        {str=>'-1,-2-5,7,9-9', anchor=>1, matches=>0,
         summary=>'Negative'},

        #{str=>'1,9-2', anchor=>1, matches=>0, summary=>'start value cannot be larger than end value'},

    ],
};

1;
# ABSTRACT: Regexp patterns related to integer ranges

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::IntRange - Regexp patterns related to integer ranges

=head1 VERSION

This document describes version 0.001 of Regexp::Pattern::IntRange (from Perl distribution Regexp-Pattern-IntRange), released on 2021-07-17.

=head1 SYNOPSIS

 use Regexp::Pattern; # exports re()
 my $re = re("IntRange::int_range");

=head1 DESCRIPTION

L<Regexp::Pattern> is a convention for organizing reusable regex patterns.

=head1 REGEXP PATTERNS

=over

=item * int_range

Integer range (sequence of intsE<sol>simple ranges), e.g. 1 E<sol> -5-7 E<sol> 1,10 E<sol> 1,5-7,10.

Currently does not check that start value in a simple range must not be greater
than end value.


Examples:

Empty string.

 "" =~ re("IntRange::int_range");  # DOESN'T MATCH

Example #2.

 1 =~ re("IntRange::int_range");  # matches

Example #3.

 -2 =~ re("IntRange::int_range");  # matches

Float.

 1.5 =~ re("IntRange::int_range");  # DOESN'T MATCH

Example #5.

 "1-1" =~ re("IntRange::int_range");  # matches

Example #6.

 "1-2" =~ re("IntRange::int_range");  # matches

Example #7.

 "1 - 2" =~ re("IntRange::int_range");  # matches

Example #8.

 "0-100" =~ re("IntRange::int_range");  # matches

Example #9.

 "-1-2" =~ re("IntRange::int_range");  # matches

Example #10.

 "-10--1" =~ re("IntRange::int_range");  # matches

Missing end value.

 "1-" =~ re("IntRange::int_range");  # DOESN'T MATCH

Example #12.

 "1-1.5" =~ re("IntRange::int_range");  # DOESN'T MATCH

Invalid simple int range syntax.

 "1-2-3" =~ re("IntRange::int_range");  # DOESN'T MATCH

Leading and trailing whitespace is currently not allowed.

 " 1-2 " =~ re("IntRange::int_range");  # DOESN'T MATCH

Example #15.

 "1,2" =~ re("IntRange::int_range");  # matches

Example #16.

 "1 , 2" =~ re("IntRange::int_range");  # matches

Example #17.

 "1,2,-3,4" =~ re("IntRange::int_range");  # matches

Float.

 "1,2,-3,4.5" =~ re("IntRange::int_range");  # DOESN'T MATCH

Dangling comma is currently not allowed.

 "1," =~ re("IntRange::int_range");  # DOESN'T MATCH

Multiple commas are currently not allowed.

 "1,,2" =~ re("IntRange::int_range");  # DOESN'T MATCH

Example #21.

 "1,2-5" =~ re("IntRange::int_range");  # matches

Example #22.

 "-1,-2-5,7,9-9" =~ re("IntRange::int_range");  # matches

=item * simple_int_range

Simple integer range, e.g. 1-10 E<sol> -2-7.

Currently does not check that start value must not be greater than end value.


Examples:

Empty string.

 "" =~ re("IntRange::simple_int_range");  # DOESN'T MATCH

Not a range but single positive integer.

 1 =~ re("IntRange::simple_int_range");  # DOESN'T MATCH

Not a range but single negative integer.

 -2 =~ re("IntRange::simple_int_range");  # DOESN'T MATCH

Example #4.

 "1-1" =~ re("IntRange::simple_int_range");  # matches

Example #5.

 "1-2" =~ re("IntRange::simple_int_range");  # matches

Example #6.

 "1 - 2" =~ re("IntRange::simple_int_range");  # matches

Example #7.

 "0-100" =~ re("IntRange::simple_int_range");  # matches

Example #8.

 "-1-2" =~ re("IntRange::simple_int_range");  # matches

Example #9.

 "-10--1" =~ re("IntRange::simple_int_range");  # matches

Missing end value.

 "1-" =~ re("IntRange::simple_int_range");  # DOESN'T MATCH

Example #11.

 "1-1.5" =~ re("IntRange::simple_int_range");  # DOESN'T MATCH

Invalid syntax.

 "1-2-3" =~ re("IntRange::simple_int_range");  # DOESN'T MATCH

Leading and trailing whitespace is currently not allowed.

 " 1-2 " =~ re("IntRange::simple_int_range");  # DOESN'T MATCH

=item * simple_int_seq

Simple integer sequence, e.g. 1,-3,12.




Examples:

Empty string.

 "" =~ re("IntRange::simple_int_seq");  # DOESN'T MATCH

A range m-n is not valid in simple integer sequence.

 "1-2" =~ re("IntRange::simple_int_seq");  # DOESN'T MATCH

Dangling comma is currently not allowed.

 "1," =~ re("IntRange::simple_int_seq");  # DOESN'T MATCH

Multiple commas are currently not allowed.

 "1,,2" =~ re("IntRange::simple_int_seq");  # DOESN'T MATCH

Float.

 1.2 =~ re("IntRange::simple_int_seq");  # DOESN'T MATCH

Example #6.

 1 =~ re("IntRange::simple_int_seq");  # matches

Example #7.

 "1,2" =~ re("IntRange::simple_int_seq");  # matches

Example #8.

 "1 , 2" =~ re("IntRange::simple_int_seq");  # matches

Example #9.

 "1,2,-3,4" =~ re("IntRange::simple_int_seq");  # matches

=item * simple_uint_range

Simple unsigned integer range, e.g. 1-10 E<sol> 2-7.

Currently does not check that start value must not be greater than end value.


Examples:

Empty string.

 "" =~ re("IntRange::simple_uint_range");  # DOESN'T MATCH

Not a range but single positive integer.

 1 =~ re("IntRange::simple_uint_range");  # DOESN'T MATCH

Not a range but single negative integer.

 -2 =~ re("IntRange::simple_uint_range");  # DOESN'T MATCH

Example #4.

 "1-1" =~ re("IntRange::simple_uint_range");  # matches

Example #5.

 "1-2" =~ re("IntRange::simple_uint_range");  # matches

Example #6.

 "1 - 2" =~ re("IntRange::simple_uint_range");  # matches

Example #7.

 "0-100" =~ re("IntRange::simple_uint_range");  # matches

Negative.

 "-1-2" =~ re("IntRange::simple_uint_range");  # DOESN'T MATCH

Negative.

 "-10--1" =~ re("IntRange::simple_uint_range");  # DOESN'T MATCH

Missing end value.

 "1-" =~ re("IntRange::simple_uint_range");  # DOESN'T MATCH

Example #11.

 "1-1.5" =~ re("IntRange::simple_uint_range");  # DOESN'T MATCH

Invalid syntax.

 "1-2-3" =~ re("IntRange::simple_uint_range");  # DOESN'T MATCH

Leading and trailing whitespace is currently not allowed.

 " 1-2 " =~ re("IntRange::simple_uint_range");  # DOESN'T MATCH

=item * simple_uint_seq

Simple unsigned integer sequence, e.g. 1,3,12.




Examples:

Empty string.

 "" =~ re("IntRange::simple_uint_seq");  # DOESN'T MATCH

A range m-n is not valid in simple integer sequence.

 "1-2" =~ re("IntRange::simple_uint_seq");  # DOESN'T MATCH

Dangling comma is currently not allowed.

 "1," =~ re("IntRange::simple_uint_seq");  # DOESN'T MATCH

Multiple commas are currently not allowed.

 "1,,2" =~ re("IntRange::simple_uint_seq");  # DOESN'T MATCH

Float.

 1.2 =~ re("IntRange::simple_uint_seq");  # DOESN'T MATCH

Example #6.

 1 =~ re("IntRange::simple_uint_seq");  # matches

Example #7.

 "1,2" =~ re("IntRange::simple_uint_seq");  # matches

Example #8.

 "1 , 2" =~ re("IntRange::simple_uint_seq");  # matches

Negative.

 "1,2,-3,4" =~ re("IntRange::simple_uint_seq");  # DOESN'T MATCH

=item * uint_range

Unsigned integer range (sequence of uintsE<sol>simple ranges), e.g. 1 E<sol> 5-7 E<sol> 1,10 E<sol> 1,5-7,10.

Currently does not check that start value in a simple range must not be greater
than end value.


Examples:

Empty string.

 "" =~ re("IntRange::uint_range");  # DOESN'T MATCH

Example #2.

 1 =~ re("IntRange::uint_range");  # matches

Negative.

 -2 =~ re("IntRange::uint_range");  # DOESN'T MATCH

Float.

 1.5 =~ re("IntRange::uint_range");  # DOESN'T MATCH

Example #5.

 "1-1" =~ re("IntRange::uint_range");  # matches

Example #6.

 "1-2" =~ re("IntRange::uint_range");  # matches

Example #7.

 "1 - 2" =~ re("IntRange::uint_range");  # matches

Example #8.

 "0-100" =~ re("IntRange::uint_range");  # matches

Negative.

 "-1-2" =~ re("IntRange::uint_range");  # DOESN'T MATCH

Negative.

 "-10--1" =~ re("IntRange::uint_range");  # DOESN'T MATCH

Missing end value.

 "1-" =~ re("IntRange::uint_range");  # DOESN'T MATCH

Example #12.

 "1-1.5" =~ re("IntRange::uint_range");  # DOESN'T MATCH

Invalid simple int range syntax.

 "1-2-3" =~ re("IntRange::uint_range");  # DOESN'T MATCH

Leading and trailing whitespace is currently not allowed.

 " 1-2 " =~ re("IntRange::uint_range");  # DOESN'T MATCH

Example #15.

 "1,2" =~ re("IntRange::uint_range");  # matches

Example #16.

 "1 , 2" =~ re("IntRange::uint_range");  # matches

Negative.

 "1,2,-3,4" =~ re("IntRange::uint_range");  # DOESN'T MATCH

Float.

 "1,2,-3,4.5" =~ re("IntRange::uint_range");  # DOESN'T MATCH

Dangling comma is currently not allowed.

 "1," =~ re("IntRange::uint_range");  # DOESN'T MATCH

Multiple commas are currently not allowed.

 "1,,2" =~ re("IntRange::uint_range");  # DOESN'T MATCH

Example #21.

 "1,2-5" =~ re("IntRange::uint_range");  # matches

Negative.

 "-1,-2-5,7,9-9" =~ re("IntRange::uint_range");  # DOESN'T MATCH

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern-IntRange>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern-IntRange>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern-IntRange>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah::Schemas::IntRange>

L<Regexp::Pattern::Int>

L<Regexp::Pattern>

Some utilities related to Regexp::Pattern: L<App::RegexpPatternUtils>, L<rpgrep> from L<App::rpgrep>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
