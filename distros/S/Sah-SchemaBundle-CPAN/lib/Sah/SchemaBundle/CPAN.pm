## no critic: TestingAndDebugging::RequireUseStrict
package Sah::SchemaBundle::CPAN;

# during build by perl >= 5.014, Sah::SchemaR::cpan::pause_id will contain sequence (?^...) which is not supported by perl <= 5.012
use 5.014;
use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-06-13'; # DATE
our $DIST = 'Sah-SchemaBundle-CPAN'; # DIST
our $VERSION = '0.016'; # VERSION

1;
# ABSTRACT: Sah schemas related to CPAN

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::SchemaBundle::CPAN - Sah schemas related to CPAN

=head1 VERSION

This document describes version 0.016 of Sah::SchemaBundle::CPAN (from Perl distribution Sah-SchemaBundle-CPAN), released on 2024-06-13.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<cpan::distname|Sah::Schema::cpan::distname>

A distribution name on CPAN, e.g. "Module-Installed-Tiny".

This schema can be used to validate a CPAN distribution name. It's like the
C<perl::distname> schema, but with completion from distribution names on CPAN
(using L<lcpan>). It does not check whether a CPAN distribution exists or
not (indexed on PAUSE); use the C<cpan::distname::exists> or
C<cpan::distname::not_exists> schemas for that purpose.


=item * L<cpan::modname|Sah::Schema::cpan::modname>

A module name on CPAN, e.g. 'Module::Installed::Tiny'.

This schema can be used to validate a CPAN module name. It's like the
C<perl::modname> schema, but with completion from module names on CPAN (using
L<lcpan>). It does not check whether a CPAN module exists or not (indexed on
PAUSE); use the C<cpan::modname::exists> or C<cpan::modname::not_exists> schemas
for that purpose.


=item * L<cpan::pause_id|Sah::Schema::cpan::pause_id>

PAUSE author ID, e.g. 'PERLANCAR'.

This schema can be used to validate a PAUSE ID. It's basically just C<str> with
checks for valid characters and accepted length (2-9 characters). Whether the
PAUSE ID exists is not checked by this schema; see the C<cpan::pause_id::exists>
and C<cpan::pause_id::not_exists> for that purpose.


=back

=head1 SYNOPSIS

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-CPAN>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-CPAN>.

=head1 SEE ALSO

L<Sah::SchemaBundle::CPANMeta>

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

This software is copyright (c) 2024, 2022, 2021, 2020, 2019, 2018, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-CPAN>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
