package Sah::Schemas::Unix;

our $DATE = '2021-07-22'; # DATE
our $VERSION = '0.017'; # VERSION

1;
# ABSTRACT: Various Sah schemas for Unix

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::Unix - Various Sah schemas for Unix

=head1 VERSION

This document describes version 0.017 of Sah::Schemas::Unix (from Perl distribution Sah-Schemas-Unix), released on 2021-07-22.

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




=item * L<unix::groupname|Sah::Schema::unix::groupname>

Unix group name.

The checking follows POSIX rules: does not begin with a hyphen and only contains
[A-Za-z0-9._-].

The above rule allows integers like 1234, which can be confused with GID, so
this schema disallows pure integers.

The maximum length is 32 following libc6's limit.


=item * L<unix::local_gid|Sah::Schema::unix::local_gid>

Group identifier (GID) that has to exist on the system.

Existing means having a group name associated with this GID, i.e. C<getgrgid>
returns a record.

Support coercion from an existing group name.


=item * L<unix::local_groupname|Sah::Schema::unix::local_groupname>

Unix group name that must exist on the system.

Support coercion from GID.


=item * L<unix::local_uid|Sah::Schema::unix::local_uid>

User identifier (UID) that has to exist (has associated username) on the system.

Existing means having a user name associated with this UID, i.e. C<getpwuid>
returns a record.

Support coercion from an existing user name.


=item * L<unix::local_username|Sah::Schema::unix::local_username>

Unix user name that must exist on the system.

Support coercion from UID.


=item * L<unix::pathname|Sah::Schema::unix::pathname>

Path name (filename or dirname) on a Unix system.

This is just a convenient alias for pathname::unix.


=item * L<unix::pid|Sah::Schema::unix::pid>

Process identifier (PID).




=item * L<unix::signal|Sah::Schema::unix::signal>

Unix signal name (e.g. TERM or KILL) or number (9 or 15).

=item * L<unix::uid|Sah::Schema::unix::uid>

User identifier (UID).




=item * L<unix::username|Sah::Schema::unix::username>

Unix account name.

The checking follows POSIX rules: does not begin with a hyphen and only contains
[A-Za-z0-9._-].

The above rule allows integers like 1234, which can be confused with UID, so
this schema disallows pure integers.

The maximum length is 32 following libc6's limit.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Unix>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Unix>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Unix>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah> - specification

L<Data::Sah>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
