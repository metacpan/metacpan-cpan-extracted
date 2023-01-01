## no critic: TestingAndDebugging::RequireUseStrict
package Sah::Schemas::CPAN;

# during build by perl >= 5.014, Sah::SchemaR::cpan::pause_id will contain sequence (?^...) which is not supported by perl <= 5.012
use 5.014;
use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-09-25'; # DATE
our $DIST = 'Sah-Schemas-CPAN'; # DIST
our $VERSION = '0.014'; # VERSION

1;
# ABSTRACT: Sah schemas related to CPAN

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::CPAN - Sah schemas related to CPAN

=head1 VERSION

This document describes version 0.014 of Sah::Schemas::CPAN (from Perl distribution Sah-Schemas-CPAN), released on 2022-09-25.

=head1 SYNOPSIS

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<cpan::distname|Sah::Schema::cpan::distname>

A distribution name on CPAN, e.g. "Module-Installed-Tiny".

Like perl::distname, but with completion from distribution names on CPAN (using
lcpan).


=item * L<cpan::modname|Sah::Schema::cpan::modname>

A module name on CPAN, e.g. 'Module::Installed::Tiny'.

Like perl::modname, but with completion from module names on CPAN (using lcpan).


=item * L<cpan::pause_id|Sah::Schema::cpan::pause_id>

PAUSE author ID, e.g. 'PERLANCAR'.

Note that whether the PAUSE ID exists is not checked by this schema.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-CPAN>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-CPAN>.

=head1 SEE ALSO

L<Sah::Schemas::CPANMeta>

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

This software is copyright (c) 2022, 2021, 2020, 2019, 2018, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-CPAN>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
