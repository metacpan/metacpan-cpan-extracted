package Sah::SchemaBundle::KDEActivity;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-04-09'; # DATE
our $DIST = 'Sah-SchemaBundle-KDEActivity'; # DIST
our $VERSION = '0.002'; # VERSION

1;
# ABSTRACT: Sah schemas related to KDE activities

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::SchemaBundle::KDEActivity - Sah schemas related to KDE activities

=head1 VERSION

This document describes version 0.002 of Sah::SchemaBundle::KDEActivity (from Perl distribution Sah-SchemaBundle-KDEActivity), released on 2026-04-09.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<kdeactivity::guid|Sah::Schema::kdeactivity::guid>

KDE activity GUID.

=item * L<kdeactivity::name|Sah::Schema::kdeactivity::name>

KDE activity name.

=back

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-KDEActivity>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-KDEActivity>.

=head1 SEE ALSO

L<Desktop::KDEActivity::Util>

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

This software is copyright (c) 2026 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-KDEActivity>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
