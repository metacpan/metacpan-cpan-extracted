package Sah::Schemas::Path;

our $DATE = '2021-07-17'; # DATE
our $VERSION = '0.016'; # VERSION

1;
# ABSTRACT: Schemas related to filesystem path

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::Path - Schemas related to filesystem path

=head1 VERSION

This document describes version 0.016 of Sah::Schemas::Path (from Perl distribution Sah-Schemas-Path), released on 2021-07-17.

=head1 SAH SCHEMAS

=over

=item * L<dirname|Sah::Schema::dirname>

Filesystem directory name.

This schema is basically string with some checks and prefilters. Why use this
schema instead of plain ol' str? Mainly to give you the ability to change tilde
to user's home directory, e.g. C<~/foo> into C</home/someuser/foo>. Normally this
expansion is done by a Unix shell, but sometimes your program receives an
unexpanded path, e.g. when you get it from some config file.

See also more OS-specific schemas like C<dirname::unix>, which adds some more
checks (e.g. filename cannot contain forward slash and each component cannot be
longer than 255 characters) and preprocessing (e.g. stripping extraneous slashes
like C<foo//bar> into C<foo/bar>.

What's the difference between this schema and C<filename>? The default completion
rule. This schema's completion by default only includes directories.


=item * L<filename|Sah::Schema::filename>

Filesystem file name.

This schema is basically string with some checks and prefilters. Why use this
schema instead of plain ol' str? Mainly to give you the ability to change tilde
to user's home directory, e.g. C<~/foo.txt> into C</home/someuser/foo.txt>.
Normally this expansion is done by a Unix shell, but sometimes your program
receives an unexpanded path, e.g. when you get it from some config file.

See also more OS-specific schemas like C<filename::unix>, which adds some more
checks (e.g. filename cannot contain forward slash and each component cannot be
longer than 255 characters) and preprocessing (e.g. stripping extraneous slashes
like C<foo//bar> into C<foo/bar>.

What's the difference between this schema and C<dirname>? The default completion
rule. This schema's completion by default only includes files and not
directories.


=item * L<pathname|Sah::Schema::pathname>

Filesystem path name.

This schema is basically string with some checks and prefilters. Why use this
schema instead of plain ol' str? Mainly to give you the ability to change tilde
to user's home directory, e.g. C<~/foo> into C</home/someuser/foo>. Normally this
expansion is done by a Unix shell, but sometimes your program receives an
unexpanded path, e.g. when you get it from some config file.

See also more OS-specific schemas like C<pathname::unix>, which adds some more
checks (e.g. pathname cannot contain forward slash and each component cannot be
longer than 255 characters) and preprocessing (e.g. stripping extraneous slashes
like C<foo//bar> into C<foo/bar>.

What's the difference between this schema and C<filename> and C<dirname>? The
default completion rule. This schema's completion by default includes
files as well as directories.


=item * L<pathnames|Sah::Schema::pathnames>

List of filesystem path names.

Coerces from string by expanding the glob pattern in the string.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Path>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Path>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Path>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah> - specification

L<Data::Sah>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
