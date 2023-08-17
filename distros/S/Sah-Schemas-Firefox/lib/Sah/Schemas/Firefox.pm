package Sah::Schemas::Firefox;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-06-14'; # DATE
our $DIST = 'Sah-Schemas-Firefox'; # DIST
our $VERSION = '0.008'; # VERSION

1;
# ABSTRACT: Various Sah schemas related to Firefox

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::Firefox - Various Sah schemas related to Firefox

=head1 VERSION

This document describes version 0.008 of Sah::Schemas::Firefox (from Perl distribution Sah-Schemas-Firefox), released on 2023-06-14.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<firefox::local_profile_name|Sah::Schema::firefox::local_profile_name>

Firefox profile name, must exist in local Firefox installation.

This is like the C<firefox::profile_name> schema, but adds a check (in
C<prefilter> clause) that the profile must exist in local Firefox installation.


=item * L<firefox::local_profile_name::default_first|Sah::Schema::firefox::local_profile_name::default_first>

Firefox profile name, must exist in local Firefox installation, default to first.

This is like C<firefox::local_profile_name> schema, but adds a default value rule
to pick the first profile in the local Firefox installation.


=item * L<firefox::profile_name|Sah::Schema::firefox::profile_name>

Firefox profile name.

This is currently just C<str> with a minimum length of 1, but adds a completion
rule to complete from list of profiles from local Firefox installation.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Firefox>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Firefox>.

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

This software is copyright (c) 2023, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Firefox>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
