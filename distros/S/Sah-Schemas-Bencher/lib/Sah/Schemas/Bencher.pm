package Sah::Schemas::Bencher;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-23'; # DATE
our $DIST = 'Sah-Schemas-Bencher'; # DIST
our $VERSION = '1.054.1'; # VERSION

1;
# ABSTRACT: Sah schemas for Bencher

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::Bencher - Sah schemas for Bencher

=head1 VERSION

This document describes version 1.054.1 of Sah::Schemas::Bencher (from Perl distribution Sah-Schemas-Bencher), released on 2021-07-23.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<bencher::dataset|Sah::Schema::bencher::dataset>

A benchmark dataset.

=item * L<bencher::env_hash|Sah::Schema::bencher::env_hash>

A hash of environment variable and their value.

=item * L<bencher::participant|Sah::Schema::bencher::participant>

A benchmark participant.

=item * L<bencher::scenario|Sah::Schema::bencher::scenario>

Bencher scenario structure.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Bencher>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Bencher>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Bencher>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Bencher>

L<Sah> - schema specification

L<Data::Sah> - Perl implementation of Sah

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
