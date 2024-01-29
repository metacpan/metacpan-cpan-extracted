package Sah::Schemas::Business::ID::BCA;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-15'; # DATE
our $DIST = 'Sah-Schemas-Business-ID-BCA'; # DIST
our $VERSION = '0.001'; # VERSION

1;
# ABSTRACT: Sah schemas related to BCA (Bank Central Asia) bank

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::Business::ID::BCA - Sah schemas related to BCA (Bank Central Asia) bank

=head1 VERSION

This document describes version 0.001 of Sah::Schemas::Business::ID::BCA (from Perl distribution Sah-Schemas-Business-ID-BCA), released on 2024-01-15.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<business::id::bca::account_num|Sah::Schema::business::id::bca::account_num>

BCA account number.

Note that this schema only accepts 10-digit regular account number and not virtual account number.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Business-ID-BCA>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Business-ID-BCA>.

=head1 SEE ALSO

L<Business::ID::BCA>

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Business-ID-BCA>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
