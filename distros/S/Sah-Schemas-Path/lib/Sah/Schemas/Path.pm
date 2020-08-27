package Sah::Schemas::Path;

our $DATE = '2020-08-26'; # DATE
our $VERSION = '0.015'; # VERSION

1;
# ABSTRACT: Schemas related to filesystem path

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::Path - Schemas related to filesystem path

=head1 VERSION

This document describes version 0.015 of Sah::Schemas::Path (from Perl distribution Sah-Schemas-Path), released on 2020-08-26.

=head1 SAH SCHEMAS

=over

=item * L<dirname|Sah::Schema::dirname>

Filesystem directory name.

=item * L<filename|Sah::Schema::filename>

Filesystem file name.

=item * L<pathname|Sah::Schema::pathname>

Filesystem path name.

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

This software is copyright (c) 2020, 2019, 2018, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
