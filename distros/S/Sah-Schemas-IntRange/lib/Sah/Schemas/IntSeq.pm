package Sah::Schemas::IntSeq;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-17'; # DATE
our $DIST = 'Sah-Schemas-IntRange'; # DIST
our $VERSION = '0.004'; # VERSION

1;
# ABSTRACT: Sah schemas for various integer sequences

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::IntSeq - Sah schemas for various integer sequences

=head1 VERSION

This document describes version 0.004 of Sah::Schemas::IntSeq (from Perl distribution Sah-Schemas-IntRange), released on 2021-07-17.

=head1 SAH SCHEMAS

=over

=item * L<int_range|Sah::Schema::int_range>

Integer range (sequence of intsE<sol>simple ranges), e.g. 1 E<sol> -5-7 E<sol> 1,10 E<sol> 1,5-7,10.

=item * L<simple_int_range|Sah::Schema::simple_int_range>

Simple integer range, e.g. 1-10 E<sol> -2-7.

=item * L<simple_int_seq|Sah::Schema::simple_int_seq>

Simple integer sequence, e.g. 1,-3,12.

=item * L<simple_uint_range|Sah::Schema::simple_uint_range>

Simple unsigned integer range, e.g. 1-10.

=item * L<simple_uint_seq|Sah::Schema::simple_uint_seq>

Simple unsigned integer sequence, e.g. 1,3,12.

=item * L<uint_range|Sah::Schema::uint_range>

Unsigned integer range (sequence of uintsE<sol>simple ranges), e.g. 1 E<sol> 5-7 E<sol> 1,10 E<sol> 1,5-7,10.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-IntRange>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-IntRange>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-IntRange>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah::PSchema::IntSeq> which allows you to specify delimiter as well as C<min>
and C<max> values for the whole range/sequence.

L<Sah::Schemas::Int>

L<Sah::Schemas::NumSeq>

L<Sah> - specification

L<Data::Sah>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
