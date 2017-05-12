package Sah::Schemas::Int;

our $DATE = '2016-07-22'; # DATE
our $VERSION = '0.06'; # VERSION

1;
# ABSTRACT: Sah schemas for various integers

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::Int - Sah schemas for various integers

=head1 VERSION

This document describes version 0.06 of Sah::Schemas::Int (from Perl distribution Sah-Schemas-Int), released on 2016-07-22.

=head1 SAH SCHEMAS

=over

=item * L<byte|Sah::Schema::byte>

Same as uint8.

=item * L<even|Sah::Schema::even>

Even number.

=item * L<int128|Sah::Schema::int128>

32-bit signed integer.

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

=item * L<negeven|Sah::Schema::negeven>

Negative even number.

=item * L<negint|Sah::Schema::negint>

Negative integer (-1, -2, ...).

=item * L<negodd|Sah::Schema::negodd>

Negative odd number.

=item * L<odd|Sah::Schema::odd>

Odd number.

=item * L<poseven|Sah::Schema::poseven>

Positive even number.

=item * L<posint|Sah::Schema::posint>

Positive integer (1, 2, ...).

=item * L<posodd|Sah::Schema::posodd>

Positive odd number.

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

Source repository is at L<https://github.com/sharyanto/perl-Sah-Schema-Int>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Int>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah> - specification

L<Data::Sah>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
