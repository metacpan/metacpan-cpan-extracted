package Net::SFTP::Foreign::Tempdir::Extract::File;
use strict;
use warnings;
use File::Tempdir qw{};
use Path::Class::File 0.34 qw{}; #move_to capability
use Archive::Extract qw{};
use base qw{Path::Class::File};

our $VERSION = '0.18';

=head1 NAME

Net::SFTP::Foreign::Tempdir::Extract::File - Path::Class::File with an extract method

=head1 SYNOPSIS

  use Net::SFTP::Foreign::Tempdir::Extract;
  my $sftp = Net::SFTP::Foreign::Tempdir::Extract->new(user=>$user, match=>qr/\.zip\Z/);
  my $file = $sftp->next; # isa Net::SFTP::Foreign::Tempdir::Extract::File

=head1 DESCRIPTION

Net::SFTP::Foreign::Tempdir::Extract::File is a convince wrapper around L<Path::Class>, L<Archive::Extract> and L<File::Tempdir>

=head1 USAGE

  my $archive = Net::SFTP::Foreign::Tempdir::Extract::File->new( $path, $filename );
  my @files = $archive->extract; #array of Net::SFTP::Foreign::Tempdir::Extract::File files

=head2 extract

Extracts tar.gz and Zip files to temporary directory (any format supported by L<Archive::Extract>)

  my @files = $archive->extract; #list of Net::SFTP::Foreign::Tempdir::Extract::File files
  my $files = $archive->extract; #array reference of Net::SFTP::Foreign::Tempdir::Extract::File files

Note: These files are temporary and will be cleaned up when the file object variable goes out of scope.

=cut

sub extract {
  my $self   = shift;
  my $ae     = Archive::Extract->new(archive=>"$self") or die(qq{Error: Cannot create Archive::Extract object with archive "$self". Verfiy extension.});
  my $ae_dir = File::Tempdir->new                      or die(qq{Error: Cannot create File::Tempdir object});
  $ae->extract(to => $ae_dir->name)                    or die(qq{Error: }. $ae->error); #extracts all files to a temp dir
  my @files  = ();
  my $filenames = $ae->files; #array reference in scalar context
  #loop through each file, bless and move to individual temp folders
  foreach my $filename (@$filenames) {
    my $file    = $self->new($ae_dir->name => $filename); #isa Path::Class::File object
    die(sprintf(qq{Error: File "%s" is not readable.}, $file)) unless -r $file;

    next unless -f $file;                                 #only process files and not folders

    my $tmpdir  = File::Tempdir->new;                     #separate tmp directory for each file for fine grained cleanup
    die(sprintf(qq{Error: Dir "%s" is not a directory}, $tmpdir->name)) unless -d $tmpdir->name;

    $file->move_to(Path::Class::File->new($tmpdir->name, $file->basename)) or die("Error: Failed to move file to temp directory");
    $file->{"__tmpdir"} = $tmpdir;                        #needed for scope clean up of File::Tempdir object
    die(sprintf(qq{Error: File "%s" is not readable.}, $file)) unless -r $file;

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

Use GitHub to fork repository and submit pull requests.

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT

=head1 COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2021 Michael R. Davis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=head1 SEE ALSO

L<Path::Class>, L<File::Tempdir>, L<Archive::Extract>

=cut

1;
