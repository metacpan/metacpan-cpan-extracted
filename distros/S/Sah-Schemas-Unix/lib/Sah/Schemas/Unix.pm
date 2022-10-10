package Sah::Schemas::Unix;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-24'; # DATE
our $DIST = 'Sah-Schemas-Unix'; # DIST
our $VERSION = '0.020'; # VERSION

1;
# ABSTRACT: Various Sah schemas for Unix

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::Unix - Various Sah schemas for Unix

=head1 VERSION

This document describes version 0.020 of Sah::Schemas::Unix (from Perl distribution Sah-Schemas-Unix), released on 2022-07-24.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<unix::dirname|Sah::Schema::unix::dirname>

Directory name (with optional path) on a Unix system.

This is just a convenient alias for dirname::unix.


=item * L<unix::filename|Sah::Schema::unix::filename>

File name (with optional path) on a Unix system.

This is just a convenient alias for filename::unix.


=item * L<unix::gid|Sah::Schema::unix::gid>

Group identifier (GID).

Note that this schema does not check whether the GID exists (has record in the
user database e.g. C</etc/group>). To do that, use the C<unix::gid::exists>
schema.


=item * L<unix::gid::exists|Sah::Schema::unix::gid::exists>

Group identifier (GID) that has to exist on the system.

Existing means having a group name associated with this GID, i.e. C<getgrgid>
returns a record.

Support coercion from an existing group name.


=item * L<unix::groupname|Sah::Schema::unix::groupname>

Unix group name.

The checking follows POSIX rules: does not begin with a hyphen and only contains
[A-Za-z0-9._-].

The above rule allows integers like 1234, which can be confused with GID, so
this schema disallows pure integers.

The maximum length is 32 following libc6's limit.

Note that this schema does not check whether the group name exists (has record
in the user database e.g. C</etc/group>). To do that, use the
C<unix::groupname::exists> schema.


=item * L<unix::groupname::exists|Sah::Schema::unix::groupname::exists>

Unix group name that must exist on the system.

Support coercion from GID.


=item * L<unix::pathname|Sah::Schema::unix::pathname>

Path name (filename or dirname) on a Unix system.

This is just a convenient alias for pathname::unix.


=item * L<unix::pid|Sah::Schema::unix::pid>

Process identifier (PID).




=item * L<unix::signal|Sah::Schema::unix::signal>

Unix signal name (e.g. TERM or KILL) or number (9 or 15).

=item * L<unix::uid|Sah::Schema::unix::uid>

User identifier (UID).

Note that this schema does not check whether the UID exists (has record in the
user database e.g. C</etc/passwd>). To do that, use the C<unix::uid::exists>
schema.


=item * L<unix::uid::exists|Sah::Schema::unix::uid::exists>

User identifier (UID) that has to exist (has associated username) on the system.

Existing means having a user name associated with this UID, i.e. C<getpwuid>
returns a record.

Support coercion from an existing user name.


=item * L<unix::username|Sah::Schema::unix::username>

Unix account name.

The checking follows POSIX rules: does not begin with a hyphen and only contains
[A-Za-z0-9._-].

The above rule allows integers like 1234, which can be confused with UID, so
this schema disallows pure integers.

The maximum length is 32 following libc6's limit.

Note that this schema does not check whether the user name exists (has record in
the user database e.g. C</etc/group>). To do that, use the
C<unix::username::exists> schema.


=item * L<unix::username::exists|Sah::Schema::unix::username::exists>

Unix user name that must exist on the system.

Support coercion from UID.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Unix>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Unix>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2020, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Unix>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
