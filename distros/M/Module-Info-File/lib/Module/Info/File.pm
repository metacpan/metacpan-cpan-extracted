package Module::Info::File;

use strict;
use warnings;
use base 'Module::Info';
use Carp;
use File::Basename; # fileparse
use vars qw($VERSION);
use Module::Metadata;
use Try::Tiny; # try catch

$VERSION = '1.01';

sub new_from_file {
    my ( $proto, $filepath ) = @_;

    my $info = Module::Metadata->new_from_file($filepath);
    my ($filename, $dir, $suffix) = fileparse($filepath);

    return __PACKAGE__->new_from_data(
        name    => $info->name,
        dir     => $dir,
        file    => $filename,
        version => $info->version,
    );
}

sub new_from_data {
    my ( $class, %params ) = @_;

    my $self = bless {}, $class || ref $class;

    foreach ( keys %params ) {
        $self->{$_} = $params{$_} || undef;
    }

    if ( !$self->{'version'} ) {
        $self->{'version'} = $self->version();
    }

    return $self;
}

sub version {
    my ( $self, $version ) = @_;

    if ($version) {
        $self->{version} = $version;
        return 1;
    }

    if ( $self->{version} ) {
        return $self->{version};
    }
    else {
        try {
            return $self->SUPER::version();

        } catch {
            return undef;
        };
    }
}

1;

__END__

=pod

=begin markdown

[![CPAN version](https://badge.fury.io/pl/Module-Info-File.svg)](http://badge.fury.io/pl/Module-Info-File)
[![Build Status](https://travis-ci.org/jonasbn/Module-Info-File.svg?branch=master)](https://travis-ci.org/jonasbn/Module-Info-File)
[![Coverage Status](https://coveralls.io/repos/jonasbn/Module-Info-File/badge.png)](https://coveralls.io/r/jonasbn/Module-Info-File)

=end markdown

=head1 NAME

Module::Info::File - retrieve module information from a file

=head1 VERSION

This POD describes version 1.00 of Module::Info::File

=head1 SYNOPSIS

	use Module::Info::File;

	my $module = Module::Info::File->new_from_file('path/to/Some/Module.pm');

	$module->name();

	$module->version();

	$module->file();

	$module->inc_dir();

=head1 DESCRIPTION

B<Module::Info> (SEE REFERENCES), are lacking functionality of being able
to extract certain data when parsing a module directly from a file. I
have therefor created Module::Info::File, which inherits from
Module::Info and replaces the B<new_from_file> method so the lacking
data can be accessed (dir and name attributes). Apart from that you can
use all the neat accessors from B<Module::Info>.

Given the following structure in a file:

    package Foo;
    1;
    package Bar;
    1;

B<Module::Info::File> returns: Foo

Given the following structure in a file:

    package Foo;
    $VERSION = '0.01';
    1;

=head1 SUBROUTINES/METHODS

=head2 new_from_file

Given a file, it will interpret this as the module you want information
about. You can also hand it a perl script.

After construction has been completed three attributes have been set in
the object:

=over 4

=item * name

=item * dir

=item * file

=back

So by using the inherited methods from B<Module::Info> you can access
the attributes.

In the F<script> folder in this distribution is a small script called
F<version.pl>, which was the beginning of this module.

=over 4

=item * name, returns the package name of the file.

=item * version, returns the version number of the module/file in question
($VERSION).

=item * inc_dir, returns the dir attribute

=item * file, returns the file attribute

=back

=head2 new_from_data

A helper method to streamline the result set

In general please refer to the documentation on B<Module::Info> for more
details.

In list context the module returns and array of Module::Info::File objects, with
which you can use the above accessors. The information in the objects might not
be complete though (SEE: CAVEATS).

In the t/ directory of this distribution there is a test (Info.t), it
includes some tests. These tests will test your installation of
Module::Info (required by Module::Info::File), if the tests fail,
Module::Info::File will be obsolete and can be discontinued.

=head1 SEE ALSO

=over 4

=item * L<Module::Info>, by Mattia Barbon

=item * F<script/version.pl>

=back

=head1 BUGS AND LIMITATIONS

The module can somewhat handle several package definitions in one file, but
the information is not complete yet, such as version information etc.

The method currently only support the following version number lines:

	$VERSION = '0.01';

	$VERSION = 0.01;

=head1 INCOMPATIBILITIES

Eric D. Paterson scanned his complete CPAN installation and got and came across
a few problems:

=over

=item L<DBD::Oracle>, the package was defined in a closure, this is handled from
Module::Info::File 0.09.

=item L<Archive::Zip::Tree>, which is installed, however deprecated and does NOT
contain a package defition.

=item L<CGI::Apache>, where the installed version was located in CGI/apache.pm
so the casing was not uniform with the package definition, I have asked Eric
for further information on this issue, regarding his version and installation.

=back

=head1 DIAGNOSTICS

=over

=item * C<< Unable to open file: <filename> - <operating system error> >>

If the constructor B<new_from_file> is given a filename parameter, which does
not meet the following prerequisites:

=over

=item * it must be a file and it must exist

=item * the file must be readable by the user

=back

=back

=head1 CONFIGURATION AND ENVIRONMENT

There is a such no configuration necessary and Module::Info::File is expected
to work on the same environments as perl itself.

=head1 DEPENDENCIES

This module is a sub-class of L<Module::Info>, so the following direct
dependencies have to be met:

=over

=item L<Module::Info> 0.20

=item L<File::Spec>, to work on non-unix operating systems

=item Perl 5.6.0 and above

Compability for older perls is no longer required, if somebody would
require this I would be willing to invest the time and effort.

=back

=head1 ACKNOWLEDGEMENTS

In no particular order

=over 4

=item *

Mohammad S Anwar, for PRs #6

=item *

Dai Okabayashi (bayashi), for PRs #2 and #3

=item *

Jeffrey Ryan Thalhammer, for L<Perl::Critic>

=item *

chromatic, for L<Test::Kwalitee>

=item *

Eric D. Peterson, for reporting bugs resulting in an improvement

=item *

Lars Thegler. tagg (LTHEGLER), for not letting me go easily, a patch and
suggesting the list context variation.

=item *

Thomas Eibner (THOMAS), for reviewing the POD

=item *

Mattia Barbon (MBARBON), for writing Module::Info

=item *

bigj at Perlmonks who mentioned Module::Info

=item *

All the CPAN testers, who help you to have your stuff tested on platforms not
necessarily available to a module author.

=back

=head1 AUTHOR

jonasbn E<lt>jonasbn@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Module::Info::File and related modules are free software and is
released under the Artistic License 2.0.

Module::Info::File is (C) 2003-2017 Jonas B. Nielsen (jonasbn)
E<lt>jonasbn@cpan.orgE<gt>

=cut
