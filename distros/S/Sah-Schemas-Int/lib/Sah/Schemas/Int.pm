package Sah::Schemas::Int;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-10-19'; # DATE
our $DIST = 'Sah-Schemas-Int'; # DIST
our $VERSION = '0.077'; # VERSION

1;
# ABSTRACT: Sah schemas for various integers

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::Int - Sah schemas for various integers

=head1 VERSION

This document describes version 0.077 of Sah::Schemas::Int (from Perl distribution Sah-Schemas-Int), released on 2022-10-19.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<byte|Sah::Schema::byte>

Same as uint8.

=item * L<even|Sah::Schema::even>

Even number.

=item * L<int128|Sah::Schema::int128>

128-bit signed integer.

=item * L<int16|Sah::Schema::int16>

16-bit signed integer.

=item * L<int32|Sah::Schema::int32>

32-bit signed integer.

=item * L<int64|Sah::Schema::int64>

64-bit signed integer.

=item * L<int8|Sah::Schema::int8>

8-bit signed integer.

=item * L<natnum|Sah::Schema::natnum>

Same as posint.

Natural numbers are those used for counting and ordering. Some definitions, like
ISO 80000-2 begin the natural numbers with 0. But in this definition, natural
numbers start with 1. For integers that start at 0, see C<uint>.


=item * L<negeven|Sah::Schema::negeven>

Negative even number.

=item * L<negint|Sah::Schema::negint>

Negative integer (-1, -2, ...).

=item * L<negodd|Sah::Schema::negodd>

Negative odd number.

=item * L<nonnegint|Sah::Schema::nonnegint>

Non-negative integer (0, 1, 2, ...), same as uint.

=item * L<nonposint|Sah::Schema::nonposint>

Non-positive integer (0, -1, -2, ...).

=item * L<odd|Sah::Schema::odd>

Odd number.

=item * L<poseven|Sah::Schema::poseven>

Positive even number.

=item * L<posint|Sah::Schema::posint>

Positive integer (1, 2, ...).

Zero is not included in this schema because zero is neither positive nor
negative. See also C<uint> for integers that start from 0.


=item * L<posodd|Sah::Schema::posodd>

Positive odd number.

=item * L<uint|Sah::Schema::uint>

Non-negative integer (0, 1, 2, ...).

See also C<posint> for integers that start from 1.


=item * L<uint128|Sah::Schema::uint128>

128-bit unsigned integer.

=item * L<uint16|Sah::Schema::uint16>

16-bit unsigned integer.

=item * L<uint32|Sah::Schema::uint32>

32-bit unsigned integer.

=item * L<uint64|Sah::Schema::uint64>

64-bit unsigned integer.

=item * L<uint8|Sah::Schema::uint8>

8-bit unsigned integer.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Int>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Int>.

=head1 SEE ALSO

L<Sah::Schemas::IntRange>

L<Sah::PSchemas::IntRange>

L<Sah> - schema specification

L<Data::Sah> - Perl implementation of Sah

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021, 2020, 2018, 2017, 2016, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Int>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
