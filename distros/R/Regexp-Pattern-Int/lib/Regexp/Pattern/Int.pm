package Regexp::Pattern::Int;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-27'; # DATE
our $DIST = 'Regexp-Pattern-Int'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
#use utf8;

our %RE;

$RE{int} = {
    summary => 'Integer number',
    pat => qr/[+-]?[0-9]+/,
    examples => [
        {str=>'', anchor=>1, matches=>0},
        {str=>'123', anchor=>1, matches=>1},
        {str=>'+123', anchor=>1, matches=>1},
        {str=>'-123', anchor=>1, matches=>1},
        {str=>'123.1', anchor=>1, matches=>0},
        {str=>'1e2', anchor=>1, matches=>0},
    ],
};

$RE{uint} = {
    summary => 'Non-negative integer number',
    pat => qr/[+]?[0-9]+/,
    examples => [
        {str=>'', anchor=>1, matches=>0},
        {str=>'0', anchor=>1, matches=>1},
        {str=>'+0', anchor=>1, matches=>1},
        {str=>'-0', anchor=>1, matches=>0},
        {str=>'123', anchor=>1, matches=>1},
        {str=>'+123', anchor=>1, matches=>1},
        {str=>'-123', anchor=>1, matches=>0},
        {str=>'123.1', anchor=>1, matches=>0},
        {str=>'1e2', anchor=>1, matches=>0},
    ],
};

$RE{negint} = {
    summary => 'Negative integer number',
    pat => qr/-[1-9][0-9]*/,
    examples => [
        {str=>'', anchor=>1, matches=>0},
        {str=>'0', anchor=>1, matches=>0},
        {str=>'+0', anchor=>1, matches=>0},
        {str=>'-0', anchor=>1, matches=>0},

        {str=>'123', anchor=>1, matches=>0},
        {str=>'+123', anchor=>1, matches=>0},
        {str=>'-1', anchor=>1, matches=>1},
        #{str=>'-001', anchor=>1, matches=>0}, # currently we forbid zero prefix
        {str=>'-123', anchor=>1, matches=>1},
        {str=>'-123.1', anchor=>1, matches=>0},
        {str=>'-1e2', anchor=>1, matches=>0},
    ],
};

$RE{posint} = {
    summary => 'Positive integer number',
    pat => qr/[+]?[1-9][0-9]*/,
    examples => [
        {str=>'', anchor=>1, matches=>0},
        {str=>'0', anchor=>1, matches=>0},
        {str=>'+0', anchor=>1, matches=>0},
        {str=>'-0', anchor=>1, matches=>0},

        {str=>'1', anchor=>1, matches=>1},
        {str=>'123', anchor=>1, matches=>1},
        {str=>'+123', anchor=>1, matches=>1},
        {str=>'-1', anchor=>1, matches=>0},
        #{str=>'+001', anchor=>1, matches=>0}, # currently we forbid zero prefix
        {str=>'-123', anchor=>1, matches=>0},
        {str=>'123.1', anchor=>1, matches=>0},
        {str=>'1e2', anchor=>1, matches=>0},
    ],
};

1;
# ABSTRACT: Regexp patterns related to integers

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::Int - Regexp patterns related to integers

=head1 VERSION

This document describes version 0.001 of Regexp::Pattern::Int (from Perl distribution Regexp-Pattern-Int), released on 2020-05-27.

=head1 SYNOPSIS

 use Regexp::Pattern; # exports re()
 my $re = re("Int::int");

=head1 DESCRIPTION

L<Regexp::Pattern> is a convention for organizing reusable regex patterns.

=head1 PATTERNS

=over

=item * int

Integer number.

Examples:

 "" =~ re("Int::int");  # DOESN'T MATCH

 123 =~ re("Int::int");  # matches

 "+123" =~ re("Int::int");  # matches

 -123 =~ re("Int::int");  # matches

 123.1 =~ re("Int::int");  # DOESN'T MATCH

 "1e2" =~ re("Int::int");  # DOESN'T MATCH

=item * negint

Negative integer number.

Examples:

 "" =~ re("Int::negint");  # DOESN'T MATCH

 0 =~ re("Int::negint");  # DOESN'T MATCH

 "+0" =~ re("Int::negint");  # DOESN'T MATCH

 "-0" =~ re("Int::negint");  # DOESN'T MATCH

 123 =~ re("Int::negint");  # DOESN'T MATCH

 "+123" =~ re("Int::negint");  # DOESN'T MATCH

 -1 =~ re("Int::negint");  # matches

 -123 =~ re("Int::negint");  # matches

 -123.1 =~ re("Int::negint");  # DOESN'T MATCH

 "-1e2" =~ re("Int::negint");  # DOESN'T MATCH

=item * posint

Positive integer number.

Examples:

 "" =~ re("Int::posint");  # DOESN'T MATCH

 0 =~ re("Int::posint");  # DOESN'T MATCH

 "+0" =~ re("Int::posint");  # DOESN'T MATCH

 "-0" =~ re("Int::posint");  # DOESN'T MATCH

 1 =~ re("Int::posint");  # matches

 123 =~ re("Int::posint");  # matches

 "+123" =~ re("Int::posint");  # matches

 -1 =~ re("Int::posint");  # DOESN'T MATCH

 -123 =~ re("Int::posint");  # DOESN'T MATCH

 123.1 =~ re("Int::posint");  # DOESN'T MATCH

 "1e2" =~ re("Int::posint");  # DOESN'T MATCH

=item * uint

Non-negative integer number.

Examples:

 "" =~ re("Int::uint");  # DOESN'T MATCH

 0 =~ re("Int::uint");  # matches

 "+0" =~ re("Int::uint");  # matches

 "-0" =~ re("Int::uint");  # DOESN'T MATCH

 123 =~ re("Int::uint");  # matches

 "+123" =~ re("Int::uint");  # matches

 -123 =~ re("Int::uint");  # DOESN'T MATCH

 123.1 =~ re("Int::uint");  # DOESN'T MATCH

 "1e2" =~ re("Int::uint");  # DOESN'T MATCH

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern-Int>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern-Int>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern-Int>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Regexp::Pattern::Float>

L<Sah::Schema::uint>, L<Sah::Schema::negint>, L<Sah::Schema::negint>,

L<Regexp::Pattern>

Some utilities related to Regexp::Pattern: L<App::RegexpPatternUtils>, L<rpgrep> from L<App::rpgrep>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
