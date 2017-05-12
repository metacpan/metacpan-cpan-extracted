package Net::SFTP::Foreign::Tempdir::Extract::File;
use strict;
use warnings;
use base qw{Path::Class::File};
use File::Tempdir qw{};
use Archive::Extract qw{};

our $VERSION = '0.08';

=head1 NAME

Net::SFTP::Foreign::Tempdir::Extract::File - Path::Class::File with an extract method

=head1 SYNOPSIS

  use Net::SFTP::Foreign::Tempdir::Extract;
  my $sftp=Net::SFTP::Foreign::Tempdir::Extract->new(user=>$user, match=>qr/\.zip\Z/);
  my $file=$sftp->next; # isa Net::SFTP::Foreign::Tempdir::Extract::File

=head1 DESCRIPTION

Net::SFTP::Foreign::Tempdir::Extract::File is a convince wrapper around L<Path::Class>, L<Archive::Zip> and L<File::Tempdir>

=head1 USAGE

  my $archive = Net::SFTP::Foreign::Tempdir::Extract::File->new( $path, $filename );
  my @files = $archive->extract; #array of Net::SFTP::Foreign::Tempdir::Extract::File files

=head2 extract

Extracts Zip files to temporary directory

  my @files = $archive->extract; #list of Net::SFTP::Foreign::Tempdir::Extract::File files
  my $files = $archive->extract; #array reference of Net::SFTP::Foreign::Tempdir::Extract::File files

Note: These files are temporary and will be cleaned up when the variable goes out of scope.

=cut

sub extract {
  my $self = shift;
  my $ae     = Archive::Extract->new(archive=>"$self");
  my $ae_dir = File::Tempdir->new;
  $ae->extract(to=>$ae_dir->name) or die $ae->error;
  my @files  = ();
  foreach my $filename ($ae->files) {
    my $tmpdir  = File::Tempdir->new;                         #separate tmp directory for each file for fine grained cleanup
    my $file     = $self->new($filename);                     #isa Path::Class::File object
    $file->move_to($tmpdir->name) or die("Error: Failed to move file to temp directory");
    $file->{"__tmpdir"} = $tmpdir;                            #needed for scope clean up of File::Tempdir object
    die("Error: File $file is not readable.") unless -r $file;
    push @files, $file;
  }
  return wantarray ? @files : \@files;
}

#head2 __tmpdir
#
#property to keep the tmp directory in scope for the life of the file object
#
#cut

=head1 TODO

Support other archive formats besides zip

=head1 BUGS

Send email to author and log on RT.

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  Satellite Tracking of People, LLC
  mdavis@stopllc.com
  http://www.stopllc.com/

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

L<File::Tempdir>, L<Archive::Zip>

=cut

1;
