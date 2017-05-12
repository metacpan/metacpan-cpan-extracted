package PAR::Repository::Zip;

use 5.006;
use strict;
use warnings;

use Carp qw/croak/;
use File::Spec;
use File::Temp;
#use File::Path qw/rmtree/;
#use ExtUtils::Manifest;
#require ExtUtils::MM;
use Archive::Zip;

our $VERSION = '0.20';

=head1 NAME

PAR::Repository::Zip - ZIP file handling routines for PAR::Repository

=head1 SYNOPSIS

  use PAR::Repository;
  ...

=head1 DESCRIPTION

This module is for internal use only.
It contains code for dealing with ZIP files. .par archives
are ZIP files.

B<All methods here-in are considered private methods (note the
underscores in the names). Do not use outside of PAR::Repository.>
(Of course, you are free to copy the source code (see license).)

=head2 EXPORT

None.

=head1 METHODS

Following is a list of class and instance methods.
(Instance methods until otherwise mentioned.)

There is no C<PAR::Repository::Zip> object.
L<PAR::Repository> inherits from this class.

=cut

=head2 _unzip_dist_to_path

First argument should be path and file name of a .par
distribution. Second argument may be a path to unzip the
distribution to. (Defaults to current working directory.)

Unzips the distribution to the specified directory and returns
the directory name. Returns the empty list on failure.

=cut

sub _unzip_dist_to_path {
  my $self = shift;
  $self->verbose(2, "Entering _unzip_to_path()");
  my $dist = shift;
  my $path = shift || File::Spec->curdir;
  return unless -f $dist;

  my $zip = Archive::Zip->new;
  local %SIG;
  $SIG{__WARN__} = sub { print STDERR $_[0] unless $_[0] =~ /\bstat\b/ };
  return
    unless $zip->read($dist) == Archive::Zip::AZ_OK()
           and $zip->extractTree('', "$path/") == Archive::Zip::AZ_OK();
  return $path;
}

=head2 _unzip_dist_to_tmpdir

Creates a temporary directory and extracts a .par/zip archive into it.
First argument must be the archive file and (optional) second argument may
be a sub directory (of the temp dir) to extract into. This is mainly intended for
C<blib/> sub directories.

=cut

sub _unzip_dist_to_tmpdir {
  my $self = shift;
  $self->verbose(2, "Entering _unzip_dist_to_tmpdir()");
  my $dist   = File::Spec->rel2abs(shift);
  my $subdir = shift;
  my $tmpdir = File::Temp::mkdtemp(File::Spec->catdir(File::Spec->tmpdir, "parXXXXX")) or die $!;
  my $path = $tmpdir;
  $path = File::Spec->catdir($tmpdir, $subdir) if defined $subdir;
  $self->_unzip_dist_to_path($dist, $path);

  chdir $tmpdir;
  return ($dist, $tmpdir);
}

=head2 _zip_file

Callable as class or instance method.

Zips the file given as first argument to the file
given as second argument. If there is no second argument,
zips to "file1.zip" where "file1" was the first argument.

Returns the name of the zip file.

Optional third argument is the zip member name to use.

=cut

sub _zip_file {
  my $class = shift;
  my $file = shift;
  return unless -f $file;
  my $target = shift;
  my $member_name = shift;
  $member_name = $file if not defined $member_name;
  $target = $file.'.zip' if not defined $target;

  my $zip = Archive::Zip->new;
  my $member = $zip->addFile( $file, $member_name );
  $member->desiredCompressionLevel( Archive::Zip::COMPRESSION_LEVEL_BEST_COMPRESSION() );
  $zip->writeToFileNamed( $target ) == Archive::Zip::AZ_OK() or die $!;
  
  return $target;
}

=head2 _unzip_file

Unzips the file given as first argument to the file
given as second argument.
If a third argument is used, the zip member of that name
is extracted. If the zip member name is omitted, it is
set to the target file name.

Returns the name of the unzipped file.

=cut

sub _unzip_file {
  my $class = shift;
  my $file = shift;
  my $target = shift;
  my $member = shift;
  $member = $target if not defined $member;
  return unless -f $file;

  my $zip = Archive::Zip->new;
  local %SIG;
  $SIG{__WARN__} = sub { print STDERR $_[0] unless $_[0] =~ /\bstat\b/ };
      
  return unless $zip->read($file) == Archive::Zip::AZ_OK()
         and $zip->extractMember($member, $target) == Archive::Zip::AZ_OK();

  return $target;
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
