package Sah::SchemaBundle::Collection;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-06-13'; # DATE
our $DIST = 'Sah-SchemaBundle-Collection'; # DIST
our $VERSION = '0.009'; # VERSION

1;
# ABSTRACT: Various Sah collection (array/hash) schemas

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::SchemaBundle::Collection - Various Sah collection (array/hash) schemas

=head1 VERSION

This document describes version 0.009 of Sah::SchemaBundle::Collection (from Perl distribution Sah-SchemaBundle-Collection), released on 2024-06-13.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<aoaoms|Sah::Schema::aoaoms>

Array of (defined-)array-of-maybe-strings.




=item * L<aoaos|Sah::Schema::aoaos>

Array of (defined-)array-of-(defined-)strings.




=item * L<aohoms|Sah::Schema::aohoms>

Array of (defined-)hash-of-maybe-strings.




=item * L<aohos|Sah::Schema::aohos>

Array of (defined-)hash-of-(defined-)strings.




=item * L<aoms|Sah::Schema::aoms>

Array of maybe-strings.




=item * L<aos|Sah::Schema::aos>

Array of (defined) strings.

The elements (strings) of the array must be defined.


=item * L<hoaoms|Sah::Schema::hoaoms>

Hash of (defined-)array-of-(maybe-)strings.




=item * L<hoaos|Sah::Schema::hoaos>

Hash of (defined-)array-of-(defined-)strings.




=item * L<hohoms|Sah::Schema::hohoms>

Hash of (defined-)hash-of-maybe-strings.




=item * L<hohos|Sah::Schema::hohos>

Hash of (defined-)hash-of-(defined-)strings.




=item * L<homs|Sah::Schema::homs>

Hash of maybe-strings.




=item * L<hos|Sah::Schema::hos>

Hash of (defined) strings.




=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-Collection>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-Collection>.

=head1 SEE ALSO

L<Sah> - schema specification

L<Data::Sah> - Perl implementation of Sah

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

This software is copyright (c) 2024, 2020, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-Collection>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
