package OpenInteract::PackageRepository;

# $Id: PackageRepository.pm,v 1.8 2003/03/26 02:27:17 lachoy Exp $

use strict;
use base qw( Exporter SPOPS::HashFile );
use vars qw( $PKG_DB_FILE );
use File::Copy    qw( copy move );
use File::Spec;
use Data::Dumper  qw( Dumper );
use OpenInteract::Package;
use SPOPS::Utility;

$OpenInteract::PackageRepository::VERSION   = sprintf("%d.%02d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/);
@OpenInteract::PackageRepository::EXPORT_OK = qw( $PKG_DB_FILE );

# Define our SPOPS configuration information. Very simple.

$OpenInteract::PackageRepository::C        = {
   class        => 'OpenInteract::PackageRepository',
   name         => sub { return join( '-', $_[0]->{name}, $_[0]->{version} ) },
};

$OpenInteract::PackageRepository::RULESET  = {};

$PKG_DB_FILE = 'conf/package_repository.perl';
sub package_filename { return File::Spec->catfile( $_[1], $PKG_DB_FILE ) }

sub CONFIG  { return $OpenInteract::PackageRepository::C };
sub RULESET { return $OpenInteract::PackageRepository::RULESET };

use constant DEBUG    => 0;
use constant META_KEY => 'META_INF';

# Normal SPOPS initialization. Called by SPOPS.pm when you do:
#
#  OpenInteract::PackageRepository->class_initialize;

sub _class_initialize {
    my ( $class, $CONFIG ) = @_;
    my $count = 1;
    my $C = $class->CONFIG;
    $C->{field} = {};
    foreach my $field ( @{ $C->{field_list} } ) {
        $C->{field}{ $field } = $count;
        $count++;
    }
}


# Similar to fetch() below -- allow the user to just specify the base
# installation or website directory and add the default filename to it
# to pass to SPOPS::HashFile.

sub new {
    my ( $class, $p ) = @_;
    if ( ! $p->{filename} and $p->{directory} ) {
        $p->{filename} = File::Spec->catfile( $p->{directory}, $PKG_DB_FILE );
    }
    $p->{perm} ||= 'new';
    return $class->SUPER::new( $p );
}


sub initialize {
    my ( $self, $p ) = @_;
    $self->{ META_KEY() } = { base_dir => $p->{directory} };
}


# Backup the repository

sub backup {
    my ( $self, $p ) = @_;
    return unless ( -f $p->{filename} );
    my $backup_name = $self->_backup_filename( $p );
    eval { copy( $p->{filename}, $backup_name ) || die $! };
    if ( $@ ) {
        _w( 0, "Cannot backup repository: $@" );
    }
}

sub restore_backup {
    my ( $self, $p ) = @_;
    return unless ( -f $p->{filename} );
    my $backup_name = $self->_backup_filename( $p );
    my $corrupt_name = join( '', $p->{filename}, 'maybebad' );
    if ( -f $corrupt_name ) {
        unlink( $corrupt_name );
    }
    eval { move( $p->{filename}, $corrupt_name ) };
    if ( $@ ) {
        _w( 0, "Failed to move repository to restore backup: $@" );
    }
    eval { move( $backup_name, $p->{filename} ) };
    if ( $@ ) {
        _w( 0, "Failed to restore backup for repository: $@" );
    }
    _w( 1, "Backup file restored ok" );

    my $class = ref( $self );
    my $backup_object = $class->SUPER::fetch( $p->{filename}, $p );
    while ( my ( $key, $value ) = each %{ $backup_object } ) {
        $self->{ $key } = $value;
    }
 }

sub remove_backup {
    my ( $self, $p ) = @_;
    return unless ( -f $p->{filename} );
    my $backup_name = $self->_backup_filename( $p );
    return unless ( -f $backup_name );
    eval { unlink( $backup_name ) || die $! };
    if ( $@ ) {
        _w( 0, "Cannot remove backup file: $@" );
    }
}

sub _backup_filename {
    my ( $self, $p ) = @_;
    my $extension = $p->{extension} || 'backup';
    $extension = ".$extension" unless ( $extension =~ /^\./ );
    return join( '', $p->{filename}, $extension );
}

# Ensure that the base_dir, name and version properties are defined
# for every package in the repository. Also remove each package's
# reference to the repository object before we serialize.

sub pre_save_action {
    my ( $self, $p ) = @_;
    foreach my $pkg_key ( keys %{ $self } ) {
        next if ( $pkg_key eq META_KEY );
        unless ( -d $self->{ $pkg_key }{base_dir} ) {
            warn( "Cannot save package repository: the OpenInteract base installation ",
                  "directory for package ($pkg_key) is not specified or does not exist!" );
            return undef;
        }
        unless ( $self->{ $pkg_key }{name} and $self->{ $pkg_key }{version} ) {
            warn( "Cannot save package repository: both the package 'name' and 'version' ",
                  "must be specified for package ($pkg_key) before saving.\n" );
            return undef;
        }
        delete $self->{ $pkg_key }{repository};
    }
    return 1;
}


# Restore all the repository references

sub post_save_action {
    my ( $self, $p ) = @_;
    $self->_set_repository;
    return 1;
}


# Save a reference to the repository in each package info

sub post_fetch_action {
    my ( $self, $filename, $p ) = @_;
    $self->_set_repository;
    return 1;
}


# Set the {repository} key to the repository for all the package info
# hashrefs.

sub _set_repository {
    my ( $self ) = @_;
    foreach my $pkg_key ( keys %{ $self } ) {
        next if ( $pkg_key eq META_KEY );
        DEBUG && _w( 1, "Setting repository in package key $pkg_key" );
        $self->{ $pkg_key }{repository} = $self;
    }
}


# Allow people to just specify a directory, then pass the constructed
# filename to the SPOPS::HashFile->fetch() method

sub fetch {
    my ( $class, $filename, $p ) = @_;
    $filename ||= '';
    $p        ||= {};
    DEBUG && _w( 1, "Trying to fetch file [$filename]  with info ", Dumper( $p ) );
    $p->{perm} ||= 'write';
    return $class->SUPER::fetch( $filename, $p ) if ( $filename );
    unless ( $p->{directory} ) {
        die "Cannot open package repository without a filename or directory.\n";
    }
    unless ( -d $p->{directory} ) {
        die "Cannot open package repository in directory",
           "[$p->{directory}]: the directory does not exist.\n";
    }
    $filename = $class->package_filename( $p->{directory} );
    my $object = $class->SUPER::fetch( $filename, $p );
    $object->{ META_KEY() } ||= { base_dir => $p->{directory} };
    return $object;
}


# Either saves/updates package info in the repository

sub save_package {
    my ( $self, $info ) = @_;
    my $pkg_key = $self->_make_package_key( $info );
    delete $info->{repository};
    $self->{ $pkg_key } = $info;
    $info->{repository} = $self;
    return $info;
}

sub _make_package_key {
    my ( $self, $info ) = @_;
    return join( '-', $info->{name}, $info->{version} );
}


sub remove_package {
    my ( $self, $info ) = @_;
    my $pkg_key = $self->_make_package_key( $info );
    return delete $self->{ $pkg_key };
}

# Retrieves the newest package given only a name; so if there are
# three packages installed:
#
#   FirstPackage-1.14
#   FirstPackage-1.16
#   FirstPackage-1.80
#
# This method will return the last, since it's the latest (higher
# version) You can, however, pass in a version; if it matches a
# package version exactly, that gets returned; otherwise it's still
# the highest

sub fetch_package_by_name {
    my ( $self, $p ) = @_;
    my $name = lc $p->{name};
    DEBUG && _w( 1, "Trying to retrieve package $name" );
    my @match = ();
    foreach my $pkg_key ( keys %{ $self } ) {
        next unless ( ref $self->{ $pkg_key } eq 'HASH' );
        if ( $self->{ $pkg_key }{name} eq $name ) {
            push @match, $self->{ $pkg_key };
            DEBUG && _w( 1, "Found package $pkg_key; try to match up with package $name" );
        }
    }
    my $final = undef;
    my $ver   = 0;
    foreach my $info ( @match ) {
        if ( $info->{version} > $ver ) {
            $final = $info;
            $ver   = $info->{version};
        }
        DEBUG && _w( 1, "Current version for matching $info->{name}: $ver" );
        return $info   if ( $p->{version} and $info->{version} == $p->{version} );
    }

    # If we wanted an exact match and didn't find it, return nothing,
    # otherwise return the latest version

    return undef  if ( $p->{version} );
    return $final;
}


# Retrieve all packages in a repository

sub fetch_all_packages {
    my ( $self ) = @_;
    my @package_list = ();
    foreach my $pkg_key ( sort keys %{ $self } ) {
        push @package_list, $self->{ $pkg_key }   unless ( $pkg_key eq META_KEY );
    }
    return \@package_list;
}


# Find a file in a particular package -- basically just pass the
# request on to OpenInteract::Package

sub find_file {
    my ( $self, $pkg_info, @files ) = @_;
    my $info = $pkg_info;
    unless ( ref $info eq 'HASH' ) {
        $info = $self->fetch_package_by_name({ name => $pkg_info });
    }
    return undef unless ( scalar keys %{ $info } );
    return OpenInteract::Package->find_file( $info, @files );
}


# Ensure that a list of packages actually exists in whichever context
# is specified.

sub verify_package {
    my ( $self, @package_names ) = @_;
    my $num_names = scalar @package_names;
    my @pkg_exist = ();
    foreach my $pkg_name ( @package_names ) {
        my $info = $self->fetch_package_by_name({ name => $pkg_name });
        DEBUG && _w( 1, sprintf( "Verify package status %-20s: %s",
                        $pkg_name,  ( $info ) ? "exists (Version $info->{version})" : 'does not exist' ) );
        push @pkg_exist, $info  if ( scalar keys %{ $info } );
    }
    return $pkg_exist[0] if ( $num_names == 1 );
    return \@pkg_exist;
}


sub _w {
    my $lev = shift;
    return unless ( DEBUG >= $lev );
    my ( $pkg, $file, $line ) = caller;
    my @ci = caller(1);
    warn "$ci[3] ($line) >> ", join( ' ', @_ ), "\n";
}


# Delegate to SPOPS::Utility

sub now {
    shift;
    return SPOPS::Utility->now( @_ );
}


1;

__END__

=pod

=head1 NAME

OpenInteract::PackageRepository - Operations to represent, install, remove and otherwise manipulate package repositories.

=head1 SYNOPSIS

  # Get a reference to a repository

  my $repository = OpenInteract::PackageRepository->fetch(
                                     undef,
                                     { directory => '/opt/OpenInteract' } );

 # Create a new package, set some properties and save to the repository

  my $pkg_info = {
      name        => 'MyPackage',
      version     => 3.13,
      author      => 'Arthur Dent <arthurd@earth.org>',
      base_dir    => '/path/to/installed/OpenInteract',
      package_dir => 'pkg/mypackage-3.13',
 };
 $repository->save_package_info( $info );

 # Retrieve the latest version of a package

 my $info = eval { $repository->fetch_package_by_name({
                                        name => 'MyPackage' }) };
 unless ( $info ) {
   die "No package found with that name!";
 }

 # Retrieve a specific version

 my $info = eval { $repository->fetch_package_by_name({
                                        name    => 'MyPackage',
                                        version => 3.12 }) };
 unless ( $info ) {
   die "No package found with that name and version!";
 }

 # Install a package

 my $info = eval { $repository->install_package({
                       package_file => $OPT_package_file }) };
 if ( $@ ) {
   print "Could not install package! Error: $@";
 }
 else {
   print "Package $info->{name}-$info->{version} installed ok!";
 }

 # Install to website (apply package)

 my $info = eval { $repository->fetch_package_by_name({
                                        name    => 'MyPackage',
                                        version => 3.12 }) };
 my $site_repository = OpenInteract::Package->fetch(
                                      undef,
                                      { directory => "/home/MyWebsiteDir" } );
 $info->{website_name} = "MyApp";
 $info->{installed_on}  = $repository->now;
 $site_repository->save_package_info( $info );

 # Create a package skeleton (for when you are developing a new
 # package)

 $repository->create_package_skeleton( $package_name );

 # Export a package into a tar.gz distribution file

 chdir( '/home/MyWebsiteDir' );
 my $status = OpenInteract::Package->export_package();
 print "Package: $status->{name}-$status->{version} ",
       "saved in $status->{file}";

 # Find a file in a package

 $repository->find_file({ package => 'MyPackage',
                          file    => 'template/mytemplate.tmpl' });
 open( TMPL, $filename ) || die "Cannot open $filename: $!";
 while ( <TMPL> ) { ... }

=head1 DESCRIPTION

This is a different type of module than many others in the
C<OpenInteract::> hierarchy. Instead of being created from scratch,
the configuration information is in the class rather than in a
configuration file. It does not use a SQL database for a back end. It
does not relate to any other objects.

Instead, all we do is represent a package repository. An OpenInteract
package repository is a collection of metadata about files installed
to a particular location, known as a package. The OpenInteract package
is a means of distributing Perl object and handler code,
configuration, SQL structures and data, templates and anything else
necessary to implement a discrete set of functionality.

A package can exist in two places: in the base installation and in one
or more websites. (You can tell the difference when you are going
through a package information hashref because website packages have
the property 'website_dir' defined.)

The package in the base installation is the master package and should
never be changed. Since you never use it directly, you should never
B<need> to change it, either. Every time you create a website the
website gets a customized copy of the master package. The website
author can then change the website package as much as desired without
affecting the base installation master package.

=head1 METHODS

B<_class_initialize( $CONFIG )>

When we initialize the class we want to use the OpenInteract
installation directory for the default package database location.

B<pre_save_action>

Ensure that before we add a package to a database it has the
'base_dir' property.

B<fetch_package_by_name( \%params )>

Retrieve a package by name and/or version. If you ask for a specific
version and that version does not exist, you will get nothing back. If
you do not ask for a version, you will get the latest one available.

Parameters:

=over 4

=item *

name ($)

Package name to retrieve

=item *

version ($) (optional)

Version of package to retrieve; if you specify a version then *only*
that version can be returned.

=back

Example:

 my $pkg = $pkg_class->fetch_by_name( { name => 'zigzag' } );
 if ( $pkg ) {
   print "Latest installed version of zigzag: $pkg->{version}\n";
 }

B<fetch_all_packages()>

Returns: Arrayref of all package information hashrefs in a particular
repository.

B<verify_package( @package_names )>

Verify that each of the packages listed in @package_names exists for
this repository.

Returns: For each package verified a hashref of the package
information. If you pass only one name, you get a single result
back; multiple names get returned in an arrayref.

B<verify_package_list( @package_names )>

The same as C<verify_package()> except we return a list reference of
package instead of a single

B<find_file( [ $package_name | \%package_info ], @file_list )>

Pass in one or more possible variations on a filename that you wish to
find within a package. If you pass multiple files, each will be
checked in order. Note that the name must include any directory prefix
as well. For instance:

   $repos->find_file( 'mypackage',
                      'template/mytemplate', 'template/mytemplate.tmpl' );

Returns a full filename of an existing file, undef if no existing file
found matching any of the filenames passed in.

B<include_package_dir>

Put both the base package dir and the website package_dir into
@INC. Both directories are put onto the front of @INC, the website
directory first and then the base directory. (This enables packages
found in the app to override the base.) Both directories are first
tested to ensure they actually exist.

Returns: directories that were C<unshift>ed onto @INC, in the same
order.

=head1 TO DO

Nothing known.

=head1 BUGS

None known.

=head1 SEE ALSO

L<OpenInteract::Package>, OpenInteract documentation: I<Packages in OpenInteract>

=head1 COPYRIGHT

Copyright (c) 2001-2002 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters <chris@cwinters.com>

Christian Lemburg <lemburg@aixonix.de> suffered through early versions
of the package management system and offered insightful feedback,
including a pointer to L<ExtUtils::Manifest> and the advice to move to
a text-based storage system.

=cut
