package Sah::Schemas::Path;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-08'; # DATE
our $DIST = 'Sah-Schemas-Path'; # DIST
our $VERSION = '0.030'; # VERSION

1;
# ABSTRACT: Schemas related to filesystem path

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::Path - Schemas related to filesystem path

=head1 VERSION

This document describes version 0.030 of Sah::Schemas::Path (from Perl distribution Sah-Schemas-Path), released on 2024-01-08.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<dirname|Sah::Schema::dirname>

Filesystem directory name.

This schema is basically string with some checks and prefilters. Why use this
schema instead of plain ol' str? Mainly to give you the ability to change tilde
to user's home directory, e.g. C<~/foo> into C</home/someuser/foo>. Normally this
expansion is done by a Unix shell, but sometimes your program receives an
unexpanded path, e.g. when you get it from some config file.

See also more OS-specific schemas like C<dirname::unix>, which adds some more
checks (e.g. filename cannot contain forward slash and each component cannot be
longer than 255 characters) and preprocessing (e.g. stripping extraneous slashes
like C<foo//bar> into C<foo/bar>.

What's the difference between this schema and C<filename>? The default completion
rule. This schema's completion by default only includes directories.


=item * L<dirname::default_curdir|Sah::Schema::dirname::default_curdir>

Directory name, default to current directory.

Note: be careful when using this schema for actions that are destructive,
because a user can perform those actions without giving an argument (e.g. in a
C<delete-files-in> script). It is safer to use this schema when performing a
non-destructive action (e.g. C<ls>) and/or operate in dry-run mode by default.


=item * L<dirname::default_curdir_abs|Sah::Schema::dirname::default_curdir_abs>

Directory name, default to current directory (absolutified).

Note: be careful when using this schema for actions that are destructive,
because a user can perform those actions without giving an argument (e.g. in a
C<delete-files-in> script). It is safer to use this schema when performing a
non-destructive action (e.g. C<ls>) and/or operate in dry-run mode by default.


=item * L<dirname::default_only_subdir_in_curdir|Sah::Schema::dirname::default_only_subdir_in_curdir>

Directory name, defaults to only subdirectory in current directory (if there is one).

This is like the C<dirname> schema but with a default value of "only subdirectory
in the current directory". That is, if the current directory has a single
subdirectory and nothing else.

Difference with C<dirname::default_only_subdir_not_file_in_subdir> schema: the
other schema ignores plain files. Thus, if a directory only contains C<file1> and
C<subdir1>, then that other schema will return C<subdir1> but this schema will not
return a default value.

Note: be careful when using this schema for actions that are destructive,
because a user can perform those actions without giving an argument (e.g. in a
C<delete-files-in> script). It is safer to use this schema when performing a
non-destructive action (e.g. C<ls>) and/or operate in dry-run mode by default.


=item * L<dirname::default_only_subdir_not_file_in_curdir|Sah::Schema::dirname::default_only_subdir_not_file_in_curdir>

Directory name, defaults to only subdirectory in current directory (if there is one) (files ignored).

This is like the C<dirname> schema but with a default value of "only subdirectory
in the current directory". That is, if the current directory has a single
subdirectory and nothing else (plain files are ignored).

Difference with C<dirname::default_only_subdir_in_subdir> schema: the other
schema does not ignore plain files. Thus, if a directory only contains C<file1>
and C<subdir1>, then that other schema will not return C<subdir1> but this schema
will.

Note: be careful when using this schema for actions that are destructive,
because a user can perform those actions without giving an argument (e.g. in a
C<delete-files-in> script). It is safer to use this schema when performing a
non-destructive action (e.g. C<ls>) and/or operate in dry-run mode by default.


=item * L<dirname::exists|Sah::Schema::dirname::exists>

Directory name, must exist on filesystem.

This is like the C<dirname> schema but with an extra check that the path must
already exist.


=item * L<dirname::exists::default_only_subdir_in_curdir|Sah::Schema::dirname::exists::default_only_subdir_in_curdir>

Directory name, must exist on the filesystem, defaults to only subdirectory in current directory (if there is one).

This is like the C<dirname::exists> schema but with a default value of "only
subdirectory in the current directory". That is, if the current directory has a
single subdirectory and nothing else.

Note: be careful when using this schema for actions that are destructive,
because a user can perform those actions without giving an argument (e.g. in a
C<delete-files-in> script). It is safer to use this schema when performing a
non-destructive action (e.g. C<ls>) and/or operate in dry-run mode by default.


=item * L<dirname::not_exists|Sah::Schema::dirname::not_exists>

Directory name, must not exist on filesystem.

This is like the C<dirname> schema but with an extra check that the path must
not already exist.


=item * L<dirname::unix|Sah::Schema::dirname::unix>

Filesystem directory name on a Unix system.

This is like the C<dirname> schema but with extra checks relevant to the Unix,
(e.g. a path element cannot be longer than 255 characters) and prefilters (e.g.
multipile consecutive slashes C<//> will be normalized into a single one C</>).


=item * L<dirname::unix::basename|Sah::Schema::dirname::unix::basename>

Filesystem base directory name on a Unix system.

This is like the C<dirname::unix> schema but not allowing parent directory parts.
Difference with C<filename::unix::basename> and C<pathname::unix::basename>: the
completion rule.


=item * L<dirname::unix::exists|Sah::Schema::dirname::unix::exists>

Unix directory name, must exist on filesystem.

This is like the C<dirname::unix> schema but with an extra check that the path
must already exist.


=item * L<dirname::unix::not_exists|Sah::Schema::dirname::unix::not_exists>

Unix directory name, must exist on filesystem.

This is like the C<dirname::unix> schema but with an extra check that the path
must not already exist.


=item * L<dirnames::exist|Sah::Schema::dirnames::exist>

List of directory names, all must exist on filesystem.

=item * L<filename|Sah::Schema::filename>

Filesystem file name.

This schema is basically string with some checks and prefilters. Why use this
schema instead of plain ol' str? Mainly to give you the ability to change tilde
to user's home directory, e.g. C<~/foo.txt> into C</home/someuser/foo.txt>.
Normally this expansion is done by a Unix shell, but sometimes your program
receives an unexpanded path, e.g. when you get it from some config file.

See also more OS-specific schemas like C<filename::unix>, which adds some more
checks (e.g. filename cannot contain forward slash and each component cannot be
longer than 255 characters) and preprocessing (e.g. stripping extraneous slashes
like C<foo//bar> into C<foo/bar>.

What's the difference between this schema and C<dirname>? The default completion
rule. C<dirname>'s completion only includes directories and not files.


=item * L<filename::default_newest_file_in_curdir|Sah::Schema::filename::default_newest_file_in_curdir>

File name, defaults to newest file in current directory (if there is one).

This is like the C<filename> schema but with a default value of newest plain file
in the current directory. If current directory does not contain any file, no
default will be given.

Note: be careful when using this schema for actions that are destructive,
because a user can perform those actions without giving an argument (e.g. in a
C<delete-file> script). It is safer to use this schema when performing a
non-destructive action (e.g. C<checksum>) and/or operate in dry-run mode by
default.


=item * L<filename::default_only_file_in_curdir|Sah::Schema::filename::default_only_file_in_curdir>

File name, defaults to only file in current directory (if there is one).

This is like the C<filename> schema but with a default value of "only file in the
current directory". That is, if the current directory has a single plain file
and nothing else.

Difference with C<filename::default_only_file_not_subdir_in_subdir> schema: the
other schema ignores subdirectories. Thus, if a directory only contains C<file1>
and C<subdir1>, then that other schema will return C<file1> but this schema will
not return a default value.

Note: be careful when using this schema for actions that are destructive,
because a user can perform those actions without giving an argument (e.g. in a
C<delete-file> script). It is safer to use this schema when performing a
non-destructive action (e.g. C<checksum>) and/or operate in dry-run mode by
default.


=item * L<filename::default_only_file_not_dir_in_curdir|Sah::Schema::filename::default_only_file_not_dir_in_curdir>

File name, defaults to only file in current directory (if there is one) (subdirectories ignored).

This is like the C<filename> schema but with a default value of "only file in the
current directory". That is, if the current directory has a single plain file
and nothing else (subdirectories are ignored).

Difference with C<filename::default_only_file_in_subdir> schema: the other schema
does not ignore subdirectories. Thus, if a directory only contains C<file1> and
C<subdir1>, then that other schema will not return C<file1> but this schema will.

Note: be careful when using this schema for actions that are destructive,
because a user can perform those actions without giving an argument (e.g. in a
C<delete-file> script). It is safer to use this schema when performing a
non-destructive action (e.g. C<checksum>) and/or operate in dry-run mode by
default.


=item * L<filename::exists|Sah::Schema::filename::exists>

File name, must exist on filesystem.

This is like the C<filename> schema but with an extra check that the path must
already exist.


=item * L<filename::exists::default_only_file_in_curdir|Sah::Schema::filename::exists::default_only_file_in_curdir>

File name, must exist on the filesystem, defaults to only file in current directory (if there is one).

This is like the C<filename::exists> schema but with a default value of "only
file in the current directory". That is, if the current directory has a single
plain file and nothing else.

Note: be careful when using this schema for actions that are destructive,
because a user can perform those actions without giving an argument (e.g. in a
C<delete-file> script). It is safer to use this schema when performing a
non-destructive action (e.g. C<checksum>) and/or operate in dry-run mode by
default.


=item * L<filename::not_exists|Sah::Schema::filename::not_exists>

File name, must not already exist on filesystem.

This is like the C<filename> schema but with an extra check that the path must
not already exist.


=item * L<filename::unix|Sah::Schema::filename::unix>

Filesystem file name on a Unix system.

This is like the C<filename> schema but with extra checks relevant to the Unix,
(e.g. a path element cannot be longer than 255 characters) and prefilters (e.g.
multipile consecutive slashes C<//> will be normalized into a single one C</>).


=item * L<filename::unix::basename|Sah::Schema::filename::unix::basename>

Filesystem base file name on a Unix system.

This is like the C<filename::unix> schema but not allowing directory parts.
Difference with C<dirname::unix::basename> and C<pathname::unix::basename>: the
completion rule.


=item * L<filename::unix::exists|Sah::Schema::filename::unix::exists>

Unix file name, must exist on filesystem.

This is like the C<filename::unix> schema but with an extra check that the path
must already exist.


=item * L<filename::unix::not_exists|Sah::Schema::filename::unix::not_exists>

Unix file name, must not already exist on filesystem.

This is like the C<filename::unix> schema but with an extra check that the path
must not already exist.


=item * L<filenames|Sah::Schema::filenames>

List of filesystem file names.

Coerces from string by expanding the glob pattern in the string.


=item * L<filenames::exist|Sah::Schema::filenames::exist>

List of file names, all must exist on filesystem.

=item * L<pathname|Sah::Schema::pathname>

Filesystem path name.

This schema is basically string with some checks and prefilters. Why use this
schema instead of plain ol' str? Mainly to give you the ability to change tilde
to user's home directory, e.g. C<~/foo> into C</home/someuser/foo>. Normally this
expansion is done by a Unix shell, but sometimes your program receives an
unexpanded path, e.g. when you get it from some config file.

See also more OS-specific schemas like C<pathname::unix>, which adds some more
checks (e.g. pathname cannot contain forward slash and each component cannot be
longer than 255 characters) and preprocessing (e.g. stripping extraneous slashes
like C<foo//bar> into C<foo/bar>.

What's the difference between this schema and C<filename> and C<dirname>? The
default completion rule. This schema's completion by default includes
files as well as directories, while C<dirname>'s only include directories.


=item * L<pathname::exists|Sah::Schema::pathname::exists>

Path name, must exist on filesystem.

This is like the C<pathname> schema but with an extra check that the path must
already exist.


=item * L<pathname::not_exists|Sah::Schema::pathname::not_exists>

Path name, must not already exist on filesystem.

This is like the C<pathname> schema but with an extra check that the path must
not already exist.


=item * L<pathname::unix|Sah::Schema::pathname::unix>

Filesystem path name on a Unix system.

This is like the C<pathname> schema but with extra checks relevant to the Unix,
(e.g. a path element cannot be longer than 255 characters) and prefilters (e.g.
multipile consecutive slashes C<//> will be normalized into a single one C</>).


=item * L<pathname::unix::basename|Sah::Schema::pathname::unix::basename>

Filesystem base path name on a Unix system.

This is like the C<filename::unix> schema but not allowing directory parts.
Difference with C<dirname::unix::basename> and C<filename::unix::basename>: the
completion rule.


=item * L<pathname::unix::exists|Sah::Schema::pathname::unix::exists>

Unix path name, must exist on filesystem.

This is like the C<pathname::unix> schema but with an extra check that the path
must already exist.


=item * L<pathname::unix::not_exists|Sah::Schema::pathname::unix::not_exists>

Unix path name, must not already exist on filesystem.

This is like the C<pathname::unix> schema but with an extra check that the path
must not already exist.


=item * L<pathnames|Sah::Schema::pathnames>

List of filesystem path names.

Coerces from string by expanding the glob pattern in the string.


=item * L<pathnames::exist|Sah::Schema::pathnames::exist>

List of path names, all must exist on filesystem.

=back

=head1 DESCRIPTION

This distribution includes several schemas you can use if you want to accept
filename/dirname/pathname.

Some general guidelines:

C<pathname> should be your first choice. But if you only want to accept
directory name, you can use C<dirname> instead. And if you only want to accept
file name and not directory, you can use C<filename>.

C<filename>, C<dirname>, C<pathname> are basically the same; they differ in the
completion they provide, i.e. C<dirname> offers completion of only directory
names.

Use C<filename::unix>, C<dirname::unix>, C<pathname::unix> only if you want to
accept Unix-style path. These schemas contain additional checks that are
specific to Unix filesystem.

Use C<filename::exists>, C<dirname::exists>, C<pathname::exists> if you want to
accept an existing path. For example in a utility/routine to rename or process
files. On the contrary, there are C<filename::not_exists>,
C<dirhname::not_exists>, and C<pathname::not_exists> if you want to accept
non-existing path, e.g. in a utility/routine to create a new file.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Path>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Path>.

=head1 SEE ALSO

L<Sah> - schema specification

L<Data::Sah> - Perl implementation of Sah

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Gabor Szabo

Gabor Szabo <gabor@szabgab.com>

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

This software is copyright (c) 2024, 2023, 2020, 2019, 2018, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Path>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
