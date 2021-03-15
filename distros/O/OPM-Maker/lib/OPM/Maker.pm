package OPM::Maker;
$OPM::Maker::VERSION = '1.00';
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

version 1.00

=head1 DESCRIPTION

If you do customizing for ticketing systems like L<Znuny|https://znuny.org>, L<OTOBO|https://otobo.de> or ((OTRS)) Community Edition, you need to be able to check your package: Are all files of the package included in the file list in the sopm file? Is the sopm file valid? And you need to create the OPM file. There is otrs.PackageManager.pl included in OTRS installations, but sometimes you might not have an OTRS installation on the machine where you want to build the package (e.g. when you build the package in a L<Jenkins|http://jenkins-ci.org> job).

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

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
