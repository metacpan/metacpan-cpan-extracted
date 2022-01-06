package OPM::Maker;
$OPM::Maker::VERSION = '1.12';
use strict;
use warnings;

use App::Cmd::Setup -app;

# ABSTRACT: Module/App to build and test OPM packages for Znuny, OTOBO, ((OTRS)) Community edition.


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OPM::Maker - Module/App to build and test OPM packages for Znuny, OTOBO, ((OTRS)) Community edition.

=head1 VERSION

version 1.12

=head1 DESCRIPTION

If you do customizing for ticketing systems like L<Znuny|https://znuny.org>, L<OTOBO|https://otobo.de> or ((OTRS)) Community Edition, you need to be able to check your package: Are all files of the package included in the file list in the sopm file? Is the sopm file valid? And you need to create the OPM file. There is xxxx.Console.pl (where xxxx is either I<otobo> or I<otrs>) included in stanrdard installations, but sometimes you might not have a ticket system installed on the machine where you want to build the package (e.g. when you build the package in a CI/CD job).

C<OPM::Maker> provides C<opmbuild> that is a small tool for several tasks. At the moment it supports:

=over 4

=item * filetest

Check if all files in the filelist exist on your disk and if all files on the disk are listed in the filelist

=item * somptest

Checks if your .sopm file is valid

=item * dependencies

List all CPAN- and ticket system - dependencies of your package

=item * build

Create the OPM file

=item * index

build an index file for an OPM repository.

=back

Currently under development:

=over 4

=item * dbtest

Check if the C<DatabaseInstall> and C<DatabaseUninstall> sections in your .sopm files are valid. And it checks for SQL keywords.

=back

=head1 PARSING HUGE FILES

The commands C<index> and C<dependencies> parse ticketsystem addons. And those addons can become quite huge (the Znuny ITSM bundle
is about 27M big). Usually the parser rejects such huge files, but that behaviour was changed as of version 1.10.

Parsing XML files can lead to security issues (loading external entities, application runs out of memory, ...), so those commands
work as follows:

=over 4

=item * Huge files (up to 30M) are parsed

=item * If an environment variable OPM_MAX_SIZE is set, that is the max size for opm files

If C<OPM_MAX_SIZE> is set to I<15M>, opm files bigger than 15 MBytes are rejected, if
the variable is set to I<15000> opm files bigger than 15000 Bytes are rejected.

=item * Loading external entities/DTD is disabled

=item * Entities are not expanded

=item * OPM_UNSECURE reverts the last two settings

=back

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
