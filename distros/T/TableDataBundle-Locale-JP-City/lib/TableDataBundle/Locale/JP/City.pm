package TableDataBundle::Locale::JP::City;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-07'; # DATE
our $DIST = 'TableDataBundle-Locale-JP-City'; # DIST
our $VERSION = '0.002'; # VERSION

1;
# ABSTRACT: Collection of TableData:: modules that contain list of cities in Japan

__END__

=pod

=encoding UTF-8

=head1 NAME

TableDataBundle::Locale::JP::City - Collection of TableData:: modules that contain list of cities in Japan

=head1 VERSION

This document describes version 0.002 of TableDataBundle::Locale::JP::City (from Perl distribution TableDataBundle-Locale-JP-City), released on 2023-02-07.

=head1 DESCRIPTION

This distribution contains the following L<TableData>:: modules:

=over

=item * L<TableData::Locale::JP::City::MIC>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableDataBundle-Locale-JP-City>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableDataBundle-Locale-JP-City>.

=head1 SEE ALSO

L<TableData>

Other C<TableDataBundle::Locale::*::City> or
C<TableDataBundle::Locale::*::Locality> distributions.

L<https://en.wikipedia.org/wiki/List_of_cities_in_Japan> which contains about
800 cities, plus some cities that have been dissolved. Each record has romanized
name, Japanese name, prefecture name, population, area, founding date, as well
as link to official website.

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

This software is copyright (c) 2023, 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableDataBundle-Locale-JP-City>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
