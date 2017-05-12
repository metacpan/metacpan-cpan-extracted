package Sah::Schemas;

our $DATE = '2016-05-08'; # DATE
our $VERSION = '0.1.0'; # VERSION

1;
# ABSTRACT: Convention for Sah-Schemas-* distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas - Convention for Sah-Schemas-* distribution

=head1 VERSION

This document describes version 0.1.0 of Sah::Schemas (from Perl distribution Sah-Schemas), released on 2016-05-08.

=head1 DESCRIPTION

A C<Sah-Schemas-*> distribution contains one or more related L<Sah> schemas.

=over

=item * Put each individual schema in C<< Sah::Schema::<NAME> >> package

The schema is put in the C<$schema> package variable inside the package.

This enables quick lookup/retrieval of a certain schema.

=item * Schema must be normalized

This relieves users from having to normalize it themselves.

=back

=head1 SPECIFICATION VERSION

0.1.0

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

C<Sah::Schemas::*>

L<Sah> and L<Data::Sah>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
