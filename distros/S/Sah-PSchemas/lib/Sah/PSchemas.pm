package Sah::PSchemas;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-06'; # DATE
our $DIST = 'Sah-PSchemas'; # DIST
our $VERSION = '0.1.0'; # VERSION

1;
# ABSTRACT: Convention for Sah-PSchemas-* distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::PSchemas - Convention for Sah-PSchemas-* distribution

=head1 SPECIFICATION VERSION

0.1.0

=head1 VERSION

This document describes version 0.1.0 of Sah::PSchemas (from Perl distribution Sah-PSchemas), released on 2020-06-06.

=head1 DESCRIPTION

A C<Sah-PSchemas-*> distribution contains one or more related L<Sah>
parameterized schemas.

=over

=item * Put each individual schema in C<< Sah::PSchema::<NAME> >> package

Metadata must be returned by the C<meta> method.

Schema must be returned by the C<get_schema> method, which accepts:

 ($self, \%args [ , \%merge ])

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-PSchemas>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-PSchemas>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-PSchemas>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah::PSchema>, a convenient module to retrieve parameterized Sah schemas.

C<Sah::PSchemas::*>, distributions containing parameterized schemas.

L<Sah::Schemas> and C<Sah::PSchemas::*>, for regular, non-parameterized schemas.

L<Sah> and L<Data::Sah>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
