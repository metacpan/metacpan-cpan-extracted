package Sah::Schemas::Language;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-08-07'; # DATE
our $DIST = 'Sah-Schemas-Language'; # DIST
our $VERSION = '0.005'; # VERSION

1;
# ABSTRACT: Various Sah schemas related to language codes/names

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::Language - Various Sah schemas related to language codes/names

=head1 VERSION

This document describes version 0.005 of Sah::Schemas::Language (from Perl distribution Sah-Schemas-Language), released on 2023-08-07.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<language::code|Sah::Schema::language::code>

Language code (alpha-2 or alpha-3).

Accept only current (not retired) codes. Alpha-2 or alpha-3 codes are accepted.


=item * L<language::code::alpha2|Sah::Schema::language::code::alpha2>

Language code (alpha-2).

Accept only current (not retired) codes. Only alpha-2 codes are accepted.


=item * L<language::code::alpha3|Sah::Schema::language::code::alpha3>

Language code (alpha-3).

Accept only current (not retired) codes. Only alpha-3 codes are accepted.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Language>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Language>.

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

This software is copyright (c) 2023, 2020, 2019, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Language>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
