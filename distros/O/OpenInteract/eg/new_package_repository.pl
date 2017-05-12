#!/usr/bin/perl

# $Id: new_package_repository.pl,v 1.1 2001/02/20 04:04:23 lachoy Exp $

# new_package_repository.pl
#
#  Translates from the old package repository format (SPOPS::GDBM) to
#  the new format (OpenInteract::PackageRepository, using
#  SPOPS::HashFile)
#
# Author: Chris Winters <chris@cwinters.com>

# See also: the 'upgrade_repository' command in 'oi_manage', which is
# friendlier to run.

use strict;
use GDBM_File;
use OpenInteract::PackageRepository;

my $gdbm_file_fragment = join( '/', 'conf', 'package_install.gdbm' );
my $hash_file_fragment = $OpenInteract::PackageRepository::PKG_DB_FILE;
{
  my ( $directory, $gdbm_file, $repos_file ) = @ARGV;
  unless ( -d $directory ) {
    die <<USAGE;
Usage: $0 directory [ gdbm-filename, repository-filename ]

If 'gdbm-filename' or 'repository-filename' are not given, the
following values will be used:

 gdbm:       'directory'/$gdbm_file_fragment
 repository: 'directory'/$hash_file_fragment
USAGE
  }

  $gdbm_file  ||= join( '/', $directory, $gdbm_file_fragment );
  $repos_file ||= join( '/', $directory, $hash_file_fragment );
  die "GDBM file specified ($gdbm_file) does not exist.\n" unless ( -f $gdbm_file );

  my ( %gdbm );
  tie( %gdbm, 'GDBM_File', $gdbm_file, GDBM_File::GDBM_READER, 0666 );
  my $hash = eval { OpenInteract::PackageRepository->new({ 
                                     filename => $repos_file, 
                                     perm => 'new' }) };
  die "Cannot create a new package repository! Error: $@" if ( $@ );
  while ( my ( $k, $v ) = each %gdbm ) {
    my ( $class, $pkg_key ) = split /\-\-/, $k;
    my ($data );
    eval $v;
    $hash->{ $pkg_key } = $data;
    warn "--Saved information for package key: $pkg_key\n";
  }
  untie %gdbm;
  $hash->save({ dumper_level => 1 });
  rename( $gdbm_file, "$gdbm_file.old" );
  warn "GDBM file renamed:\n   $gdbm_file --> $gdbm_file.old\n";
}
