## no critic: TestingAndDebugging::RequireUseStrict
package Sah::SchemaBundle;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-02-13'; # DATE
our $DIST = 'Sah-SchemaBundle'; # DIST
our $VERSION = '0.1.1'; # VERSION

1;
# ABSTRACT: Convention for Sah-SchemaBundle-* distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::SchemaBundle - Convention for Sah-SchemaBundle-* distribution

=head1 SPECIFICATION VERSION

0.1.0

=head1 VERSION

This document describes version 0.1.1 of Sah::SchemaBundle (from Perl distribution Sah-SchemaBundle), released on 2024-02-13.

=head1 DESCRIPTION

A C<Sah-SchemaBundle-*> distribution contains one or more related L<Sah>
schemas.

=over

=item * Put each individual schema in C<< Sah::Schema::<NAME> >> package

The schema is put in the C<$schema> package variable inside the package.

This enables quick lookup/retrieval of a certain schema.

=item * Schema must be normalized

This relieves users from having to normalize it themselves.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle>.

=head1 SEE ALSO

C<Sah::SchemaBundle::*>

L<Sah> and L<Data::Sah>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

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

This software is copyright (c) 2024, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
