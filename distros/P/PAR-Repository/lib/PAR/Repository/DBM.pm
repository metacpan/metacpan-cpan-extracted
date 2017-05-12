package PAR::Repository::DBM;

use 5.006;
use strict;
use warnings;

use Carp qw/croak/;
use File::Spec::Functions qw/catfile splitpath/;
use DBM::Deep;
use Fcntl qw/:flock/;
use File::Copy qw();

our $VERSION = '0.20';
use constant 'MODULES_DBM_FILE'      => 'modules_dists.dbm';
use constant 'SYMLINKS_DBM_FILE'     => 'symlinks.dbm';
use constant 'SCRIPTS_DBM_FILE'      => 'scripts_dists.dbm';
use constant 'DEPENDENCIES_DBM_FILE' => 'dependencies.dbm';
use constant 'DBM_CHECKSUMS_FILE'    => 'dbm_checksums.txt';

=head1 NAME

PAR::Repository::DBM - DBM tools for PAR::Repository

=head1 SYNOPSIS

  use PAR::Repository;

=head1 DESCRIPTION

This module is for internal use only.
It contains code for accessing the DBM files of a
PAR repository.

=head2 EXPORT

None.

=head2 GLOBALS

This package has a few constants:

C<MODULES_DBM_FILE>, C<SYMLINKS_DBM_FILE>, and C<SCRIPTS_DBM_FILE>,
C<DEPENDENCIES_DBM_FILE>, and C<DBM_CHECKSUMS_FILE>.
They are accessible
as functions via C<PAR::Repository::DBM::...>. They indicate
the file names of the DBM databases and the DBM checksums file.

=head1 DATABASE STRUCTURE

This section outlines the structure of the DBM::Deep
database files used by PAR::Repository.

If you need to care about this, you should be a
PAR::Repository developer.

=head2 MODULES-DISTS DBM

The DBM file is a hash at top level.

It associates namespaces (keys) with a number of file names and
versions. The values of the top level hash are hashes again. These
contain file names as keys and corresponding versions as values.

Example:

  {
    'Math::Symbolic::Derivative' => {
      'Math-Symbolic-0.502-x86_64-linux-gnu-thread-multi-5.8.7.par' => '0.502',
      'Math-Symbolic-0.200-x86_64-linux-gnu-thread-multi-5.8.6.par' => '0.200',
    },
  }

This example means that the C<Math::Symbolic::Derivative> module can
be found in the two listed distribution files in the repository
with the listed versions. Note that the distribution version needs not
be the same as the B<module> version. The module version is the one
separately indicated.

=head2 SYMLINKS DBM

The DBM file is a hash at top level.

It associates real files in the repository (keys) with a number of
symbolic links.
The values of the top level hash are arrays of distribution file names
which are symlinks.

Example: (with some extra linebreaks to keep the text width down)

  {
    'Math-Symbolic-0.502-x86_64-linux-gnu-thread-multi-5.8.7.par'
       => [
            'Math-Symbolic-0.502-any_arch-5.8.7.par',
            'Math-Symbolic-0.502-x86_64-linux-gnu-thread-multi-'
            .'any_version.par',
            'Math-Symbolic-0.502-any_arch-any_version.par'
          ],
  }

In the example, the first file is the real file and the paths/file names
in the value array are the names of the symbolic links.

=head2 SCRIPTS-DISTS DBM

This DBM file is a hash at top level. It associates script (executable)
names with distributions much like the C<modules_dists.dbm> file.

Example:

  {
    'parrepo' => {
      'PAR-Repository-0.03-x86_64--5.8.7.par'        => '0.02',
      'PAR-Repository-0.02-any_arch-any_version.par' => '0.01',
    },
  }

=head2 DEPENDENCIES DBM

This DBM file stores distribution names and associates them with
names of modules it depends on and their minimum versions. It does
not differentiate between the various types of dependencies that
can be found in a CPAN C<META.yml> file.

Example:

 {
   'Distname-0.03-x86_64-any_version.par' => {
      'Module::It::Depends::On' => '1.00',
   },
 }

=head1 METHODS

Following is a list of class and instance methods.
(Instance methods until otherwise mentioned.)

There is no C<PAR::Repository::DBM> object.
L<PAR::Repository> inherits from this class.

=cut

=head2 modules_dbm

Opens the modules_dists.dbm.zip file in the repository and
returns a tied hash reference to that file. Second return value is the
file name.

If the file does not exist, it returns the empty list.

You should know what you are doing when you use this
method.

=cut

sub modules_dbm {
  my $self = shift;
  $self->verbose(2, 'Entering modules_dbm()');

  if (defined $self->{modules_dbm_hash}) {
    return $self->{modules_dbm_hash};
  }

  my $old_dir = Cwd::cwd();
  chdir($self->{path});
  my $file = PAR::Repository::DBM::MODULES_DBM_FILE().'.zip';
  chdir($old_dir), return() if not -f $file;

  my ($hash, $tempfile) = $self->_open_dbm($file);
  chdir($old_dir), return() if not defined $hash;

  $self->{modules_dbm_hash} = $hash;
  $self->{modules_dbm_temp_file} = $tempfile;

  chdir($old_dir);

  return ($hash, $tempfile);
}


=head2 symlinks_dbm

Opens the symlinks.dbm.zip file in the repository and
returns a tied hash reference to that file. Second
return value is the file name.

If the file does not exist, it returns the empty list.

You should know what you are doing when you use this
method.

=cut

sub symlinks_dbm {
  my $self = shift;
  $self->verbose(2, 'Entering symlinks_dbm()');

  if (defined $self->{symlinks_dbm_hash}) {
    return $self->{symlinks_dbm_hash};
  }

  my $old_dir = Cwd::cwd();
  chdir($self->{path});

  my $file = PAR::Repository::DBM::SYMLINKS_DBM_FILE().'.zip';

  chdir($old_dir), return() if not -f $file;

  my ($hash, $tempfile) = $self->_open_dbm($file);
  chdir($old_dir), return() if not defined $hash;

  $self->{symlinks_dbm_hash} = $hash;
  $self->{symlinks_dbm_temp_file} = $tempfile;

  chdir($old_dir);

  return($hash, $tempfile);
}

=head2 scripts_dbm

Opens the scripts_dists.dbm.zip file in the repository and
returns a tied hash reference to that file. Second return value is
the file name.

If the file does not exist, it returns the empty list.

You should know what you are doing when you use this
method.

=cut

sub scripts_dbm {
  my $self = shift;
  $self->verbose(2, 'Entering scripts_dbm()');

  if (defined $self->{scripts_dbm_hash}) {
    return $self->{scripts_dbm_hash};
  }

  my $old_dir = Cwd::cwd();
  chdir($self->{path});
  my $file = PAR::Repository::DBM::SCRIPTS_DBM_FILE().'.zip';
  chdir($old_dir), return() if not -f $file;

  my ($hash, $tempfile) = $self->_open_dbm($file);
  chdir($old_dir), return() if not defined $hash;

  $self->{scripts_dbm_hash} = $hash;
  $self->{scripts_dbm_temp_file} = $tempfile;

  chdir($old_dir);

  return($hash, $tempfile);
}

=head2 dependencies_dbm

Opens the dependencies.dbm.zip file in the repository and
returns a tied hash reference to that file. Second return value is the
file name.

If the file does not exist, it returns the empty list.

You should know what you are doing when you use this
method.

=cut

sub dependencies_dbm {
  my $self = shift;
  $self->verbose(2, 'Entering dependencies_dbm()');

  if (defined $self->{dependencies_dbm_hash}) {
    return $self->{dependencies_dbm_hash};
  }

  my $old_dir = Cwd::cwd();
  chdir($self->{path});
  my $file = PAR::Repository::DBM::DEPENDENCIES_DBM_FILE().'.zip';
  chdir($old_dir), return() if not -f $file;

  my ($hash, $tempfile) = $self->_open_dbm($file);
  chdir($old_dir), return() if not defined $hash;

  $self->{dependencies_dbm_hash} = $hash;
  $self->{dependencies_dbm_temp_file} = $tempfile;

  chdir($old_dir);

  return ($hash, $tempfile);
}


=head2 close_modules_dbm

Closes the C<modules_dists.dbm> file committing any
changes and then zips it back into
C<modules_dists.dbm.zip>.

This is called when the object is destroyed.

=cut

sub close_modules_dbm {
  my $self = shift;
  $self->verbose(2, 'Entering close_modules_dbm()');
  my $hash = $self->{modules_dbm_hash};
  return if not defined $hash;

  my $obj = tied($hash);
  $self->{modules_dbm_hash} = undef;
  undef $hash;
  undef $obj;

  $self->_zip_file(
      $self->{modules_dbm_temp_file},
      catfile($self->{path}, PAR::Repository::DBM::MODULES_DBM_FILE().'.zip'),
      PAR::Repository::DBM::MODULES_DBM_FILE(),
  );

  unlink $self->{modules_dbm_temp_file};
  $self->{modules_dbm_temp_file} = undef;

  return 1;
}


=head2 close_symlinks_dbm

The same as C<close_modules_dbm()> but for the
file C<symlinks.dbm.zip>.

Also called on object destruction.

=cut

sub close_symlinks_dbm {
  my $self = shift;
  $self->verbose(2, 'Entering close_symlinks_dbm()');
  my $hash = $self->{symlinks_dbm_hash};
  return if not defined $hash;

  my $obj = tied($hash);
  $self->{symlinks_dbm_hash} = undef;
  undef $hash;
  undef $obj;

  $self->_zip_file(
      $self->{symlinks_dbm_temp_file},
      catfile($self->{path}, PAR::Repository::DBM::SYMLINKS_DBM_FILE().'.zip'),
      PAR::Repository::DBM::SYMLINKS_DBM_FILE(),
  );

  unlink $self->{symlinks_dbm_temp_file};
  $self->{symlinks_dbm_temp_file} = undef;

  return 1;
}

=head2 close_scripts_dbm

Closes the C<scripts_dists.dbm> file committing any
changes and then zips it back into
C<scripts_dists.dbm.zip>.

This is called when the object is destroyed.

=cut

sub close_scripts_dbm {
  my $self = shift;
  $self->verbose(2, 'Entering close_scripts_dbm()');
  my $hash = $self->{scripts_dbm_hash};
  return if not defined $hash;

  my $obj = tied($hash);
  $self->{scripts_dbm_hash} = undef;
  undef $hash;
  undef $obj;

  $self->_zip_file(
      $self->{scripts_dbm_temp_file},
      catfile($self->{path}, PAR::Repository::DBM::SCRIPTS_DBM_FILE().'.zip'),
      PAR::Repository::DBM::SCRIPTS_DBM_FILE()
  );

  unlink $self->{scripts_dbm_temp_file};
  $self->{scripts_dbm_temp_file} = undef;

  return 1;
}


=head2 close_dependencies_dbm

Closes the C<dependencies.dbm> file committing any
changes and then zips it back into
C<dependencies.dbm.zip>.

This is called when the object is destroyed.

=cut

sub close_dependencies_dbm {
  my $self = shift;
  $self->verbose(2, 'Entering close_dependencies_dbm()');
  my $hash = $self->{dependencies_dbm_hash};
  return if not defined $hash;

  my $obj = tied($hash);
  $self->{dependencies_dbm_hash} = undef;
  undef $hash;
  undef $obj;

  $self->_zip_file(
      $self->{dependencies_dbm_temp_file},
      catfile($self->{path}, PAR::Repository::DBM::DEPENDENCIES_DBM_FILE().'.zip'),
      PAR::Repository::DBM::DEPENDENCIES_DBM_FILE(),
  );

  unlink $self->{dependencies_dbm_temp_file};
  $self->{dependencies_dbm_temp_file} = undef;

  return 1;
}


=head2 update_dbm_checksums

Updates the DBM checksums file C<dbm_checksums.txt> with the
checksums of the currently existing zipped DBM files.

This is called when the L<PAR::Repository> object is destroyed.

Maintainer note: Very similar code lives in the
C<PAR::Repository::Client::DBM::_calculate_cache_local_checksums>
method. Keep in sync or refactor.

=cut

sub update_dbm_checksums {
  my $self = shift;
  $self->verbose(2, 'Entering update_dbm_checksums()');

  # find a working base64 MD5 implementation
  my $md5_function;
  eval { require Digest::MD5; $md5_function = \&Digest::MD5::md5_base64; };
  eval { require Digest::Perl::MD5;  $md5_function = \&Digest::Perl::MD5::md5_base64; } if $@;
  if ($@) {
    die "Could load neither Digest::MD5 nor Digest::Perl::MD5. Please upgrade your perl or install either of those modules.";
  }
  
  # Prepare temporary copy of the checkums file
  my ($tempfh, $tempfile) = File::Temp::tempfile(
      'temporary_dbm_checksum_XXXXX',
      UNLINK => 0,
      DIR    => File::Spec->tmpdir(),
  );
  print $tempfh <<'HERE';
# This checksums file has the format
# FILENAME BASE64_MD5_HASH
# where the file name and the MD5 hash are separated
# by a TAB character, not arbitrary whitespace!
HERE

  # calculate hashes and write them to the temp file
  foreach my $dbmfile (
      PAR::Repository::DBM::MODULES_DBM_FILE(),
      PAR::Repository::DBM::SCRIPTS_DBM_FILE(),
      PAR::Repository::DBM::SYMLINKS_DBM_FILE(),
      PAR::Repository::DBM::DEPENDENCIES_DBM_FILE(),
    ) {
    my $filepath = catfile($self->{path}, $dbmfile.'.zip');
    open my $fh, '<', $filepath or die "Could not open DBM file '$filepath' for reading: $!";
    flock $fh, LOCK_SH;
    local $/ = undef;
    my $hash = $md5_function->(<$fh>);
    close $fh;
    print $tempfh "$dbmfile.zip\t$hash\n";
  } # end foreach dbm files

  close $tempfh;
  # move temp file to destination
  my $target_file = catfile($self->{path}, PAR::Repository::DBM::DBM_CHECKSUMS_FILE());
  File::Copy::move($tempfile, $target_file)
    or die "Could not move checksums file '$tempfile' to '$target_file': $!";
  # FIXME, could this be done more user friendly? But somehow, the file ended up being 600 by default...
  chmod(0644, $target_file);

  return 1;
}


=head2 _open_dbm

Opens the zipped dbm file given as first argument.

This is B<only for internal use>.

=cut

sub _open_dbm {
  my $self = shift;
  $self->verbose(2, 'Entering _open_dbm()');
  my $file = shift;
  my ($tempfh, $tempfile) = File::Temp::tempfile(
      'temporary_dbm_XXXXX',
      UNLINK => 0,
      DIR    => File::Spec->tmpdir(),
      EXLOCK => 0,
  );
  my ($v, $p, $f) = splitpath($file);
  $f =~ s/\.zip$//;
  $self->_unzip_file($file, $tempfile, $f) or return undef;
  my %hash;
  my $obj = tie %hash, "DBM::Deep", {
    file    => $tempfile,
    locking => 1,
  }; 

  return (\%hash, $tempfile);
}

=head2 _create_dbm

Creates a zipped dbm file given as first argument.

This is B<only for internal use>.

=cut

sub _create_dbm {
  my $self = shift;
  $self->verbose(2, 'Entering _create_dbm()');
  my $file = shift;
  $file .= '.zip' unless $file =~ /\.zip$/i;

  my ($tempfh, $tempfile) = File::Temp::tempfile(
      'temporary_dbm_XXXXX',
      UNLINK => 0,
      DIR    => File::Spec->tmpdir(),
      EXLOCK => 0,
  );
  {
    my %hash;
    my $obj = tie %hash, "DBM::Deep", {
      file    => $tempfile,
      locking => 1,
    }; 
  }

  my ($v, $p, $f) = splitpath($file);
  $f =~ s/\.zip$//i;
  $self->_zip_file($tempfile, $file, $f) or unlink($tempfile), return();

  unlink($tempfile);

  return 1;
}

1;
__END__

=head1 AUTHOR

Steffen ME<0xfc>ller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2009 by Steffen ME<0xfc>ller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
