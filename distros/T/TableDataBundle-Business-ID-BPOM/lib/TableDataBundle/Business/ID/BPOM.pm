# no code
## no critic: TestingAndDebugging::RequireUseStrict
package TableDataBundle::Business::ID::BPOM;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-04-10'; # DATE
our $DIST = 'TableDataBundle-Business-ID-BPOM'; # DIST
our $VERSION = '20230207.0.1'; # VERSION

1;
# ABSTRACT: Collection of TableData:: modules related to Indonesia's BPOM (Badan Pengawas Obat dan Makanan, or the National Agency or Drug and Food Control)

__END__

=pod

=encoding UTF-8

=head1 NAME

TableDataBundle::Business::ID::BPOM - Collection of TableData:: modules related to Indonesia's BPOM (Badan Pengawas Obat dan Makanan, or the National Agency or Drug and Food Control)

=head1 VERSION

This document describes version 20230207.0.1 of TableDataBundle::Business::ID::BPOM (from Perl distribution TableDataBundle-Business-ID-BPOM), released on 2024-04-10.

=head1 DESCRIPTION

This distribution contains the following L<TableData>:: modules:

=over

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableDataBundle-Business-ID-BPOM>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableDataBundle-Business-ID-BPOM>.

=head1 SEE ALSO

L<TableData>

L<https://pom.go.id>

Due to some modules being renamed and the source changed to CSV, this
distribution will be split to individual TableData modules, e.g.
L<TableData::Business::ID::BPOM::FoodIngredientRBA>,
L<TableData::Business::ID::BPOM::FoodAdditive>.

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

This software is copyright (c) 2024, 2023, 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableDataBundle-Business-ID-BPOM>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
