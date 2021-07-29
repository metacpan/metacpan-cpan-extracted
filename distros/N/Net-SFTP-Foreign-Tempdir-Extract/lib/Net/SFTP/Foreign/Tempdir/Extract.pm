package Net::SFTP::Foreign::Tempdir::Extract;
use strict;
use warnings;
use base qw{Package::New};
use File::Tempdir qw{};
use Net::SFTP::Foreign qw{};
use Net::SFTP::Foreign::Tempdir::Extract::File;

our $VERSION = '0.18';

=head1 NAME

Net::SFTP::Foreign::Tempdir::Extract - Secure FTP client integrating Path::Class, Tempdir, and Archive Extraction

=head1 SYNOPSIS

  use Net::SFTP::Foreign::Tempdir::Extract;
  my $sftp = Net::SFTP::Foreign::Tempdir::Extract->new(
                                                       host   => $host,
                                                       user   => $user,
                                                       match  => qr/\.zip\Z/,
                                                       backup => './backup', #default is not to backup
                                                       delete => 1,          #default is not to delete
                                                      );
  my $file = $sftp->next;

=head1 DESCRIPTION

Secure FTP client which downloads files locally to a temp directory for operations and automatically cleans up all temp files after variables are out of scope.

This package assume SSH keys are correctly installed on local account and remote server.

=head1 USAGE

=head2 File Downloader

This is a simple file downloader implementation

  use Net::SFTP::Foreign::Tempdir::Extract;
  my $sftp = Net::SFTP::Foreign::Tempdir::Extract->new(host=>$remote_host, user=>$remote_user);
  my $file = $sftp->download($remote_folder, $remote_filename);

=head2 File Watcher

This is a simple file watcher implementation

  use Net::SFTP::Foreign::Tempdir::Extract;
  my $sftp = Net::SFTP::Foreign::Tempdir::Extract->new(
                                                       host=>'remote_server',
                                                       user=>'remote_account',
                                                       match=>qr/\.zip\Z/,
                                                       folder=>'/remote_folder'
                                                      );
  my $file = $sftp->next or exit;        #nothing to process so exit
  print "$file";                       #process file here

=head2 Subclass

This is a typical subclass implementation for a particular infrastructure

  {
    package My::SFTP;
    use base qw{Net::SFTP::Foreign::Tempdir::Extract};
    sub host   {'remote_server.domain.tld'};
    sub folder {'/remote_folder'};
    sub match  {qr/\.zip\Z/};
    sub backup {time};
    1;
  }

  my $sftp = My::SFTP->new;
  while (my $file = $sftp->next) {
    printf "File %s is a %s\n", "$file", ref($file);
  }

Which outputs something like this.

  File /tmp/hwY9jVeYo3/file1.zip is a Net::SFTP::Foreign::Tempdir::Extract::File
  File /tmp/ytWaYdPXuD/file2.zip is a Net::SFTP::Foreign::Tempdir::Extract::File
  File /tmp/JrsrkleBOy/file3.zip is a Net::SFTP::Foreign::Tempdir::Extract::File

=head1 CONSTRUCTOR

=head2 new

=head1 METHODS

=head2 download

Downloads the named file in the folder.

  my $file = $sftp->download('remote_file.zip');                   #isa Net::SFTP::Foreign::Tempdir::Extract::File
  my $file = $sftp->download('/remote_folder', 'remote_file.zip'); #  which isa Path::Class::File object with an extract method

=cut

sub download {
  my $self         = shift;
  my $sftp         = $self->sftp;
  my $remote       = pop                    or die('Error: filename required.');
  my $folder       = shift                  || $self->folder;
  my $tmpdir       = File::Tempdir->new     or die('Error: Could not create File::Tempdir object');
  my $local_folder = $tmpdir->name          or die('Error: Temporary directory not configured.');
  $sftp->setcwd($folder)                    or die(sprintf('Error: %s', $sftp->error));
  $sftp->mget($remote, $local_folder)       or die(sprintf('Error: %s', $sftp->error));
  my $file         = Net::SFTP::Foreign::Tempdir::Extract::File->new($local_folder => $remote);
  die("Error: Could not read $file.") unless -r $file;
  $file->{'__tmpdir'}=$tmpdir; #must keep tmpdir scope alive
  my $backup = $self->backup;
  if ($backup) {
    $sftp->mkpath($backup)                    or die('Error: Cannot create backup directory');
    $sftp->rename($remote, "$backup/$remote") or die("Error: Cannot rename remote file $remote to $backup/$remote");
  } elsif ($self->delete) {
    $sftp->remove($remote)                    or warn("Warning: Cannot delete remote file $remote");
  }
  return $file;
}

=head2 next

Downloads the next file in list and saves it locally to a temporary folder. Returns a L<Path::Class::File> object or undef if there are no more files.

  my $file = $sftp->next or exit;  #get file or exit

  while (my $file = $sftp->next) {
    print "$file";
  }

=cut

sub next {
  my $self=shift;
  my $list=$self->list;
  if (@$list) {
    my $file=shift @$list;
    #print Dumper($file);
    return $self->download($file);
  } else {
    return;
  }
}

=head2 list

Returns list of filenames remaining to be processed that match the folder and regular expression

Note: List is shifted for each call to next method

=cut

sub list {
  my $self=shift;
  $self->{'list'}=shift if @_;
  unless (defined($self->{'list'})) {
    #printf "%s: Listing files in folder: %s\n", DateTime->now, $self->folder;
    $self->{'list'}=$self->sftp->ls(
                                    $self->folder,
                                    wanted     => $self->match,
                                    ordered    => 1,
                                    no_wanted  => qr/\A\.{1,2}\Z/,
                                    names_only => 1,
                                   );
    die(sprintf(qq{Error: File list did not return as expected. Verify folder "%s" exists and is readable.}, $self->folder))
      unless (defined($self->{'list'}) and ref($self->{'list'}) eq 'ARRAY');
  }
  return wantarray ? @{$self->{'list'}} : $self->{'list'};
}

=head2 upload

Uploads file to the folder and returns the count of uploaded files.

  $sftp->folder("/remote_folder"); #or set on construction
  $sftp->upload('local_file.zip');
  $sftp->upload('local_file1.zip', 'local_file2.zip');

The upload method is a simple wrapper around Net::SFTP::Foreign->mput that is parallel to download.

=cut

sub upload {
  my $self   = shift;
  my @files  = @_;
  my $sftp   = $self->sftp;
  return $sftp->mput(\@files, $self->folder);
}

=head1 PROPERTIES

=head2 host

SFTP server host name.

  $sftp->host("");           #default

=cut

sub host {
  my $self=shift;
  if (@_) {
    $self->{'host'} = shift;
    delete $self->{'list'};
    delete $self->{'sftp'};
  }
  $self->{'host'}=$self->_host_default unless defined($self->{'host'});
  return $self->{'host'};
}

sub _host_default {
  return '';
}

=head2 user

SFTP user name (defaults to current user)

  $sftp->user(undef);        #default

=cut

sub user {
  my $self=shift;
  if (@_) {
    $self->{'user'} = shift;
    delete $self->{'list'};
    delete $self->{'sftp'};
  }
  return $self->{'user'};
}

=head2 port

SFTP port number (defaults to undef not passed through)

  $sftp->port(undef);        #default

=cut

sub port {
  my $self=shift;
  if (@_) {
    $self->{'port'} = shift;
    delete $self->{'list'};
    delete $self->{'sftp'};
  }
  $self->{'port'}=undef unless defined $self->{'port'};
  return $self->{'port'};
}

=head2 options

SSH options passed to the more property of L<Net::SFTP::Foreign> as an array reference.

  $sftp->options(['-q']);    #default
  $sftp->options([]);        #no options
  $sftp->options(['-v']);    #verbose

=cut

sub options {
  my $self=shift;
  if (@_) {
    $self->{'options'} = shift;
    delete $self->{'list'};
    delete $self->{'sftp'};
  }
  $self->{'options'} = $self->_options_default unless defined $self->{'options'};
  die 'Error: options must be an array reference.' unless ref($self->{'options'}) eq 'ARRAY';
  return $self->{'options'};
}

sub _options_default {['-q']};

=head2 folder

Folder on remote SFTP server.

  $sftp->folder("/home/user/download");

Note: Some SFTP servers put clients in a change rooted environment.

=cut

sub folder {
  my $self=shift;
  if (@_) {
    $self->{'folder'} = shift;
    delete $self->{'list'};
   }
  $self->{'folder'}=$self->_folder_default unless defined $self->{'folder'};
  return $self->{'folder'};
}

sub _folder_default {
  return '/incoming';
}

=head2 match

Regular Expression to match file names for the next iterator

  $sftp->match(qr/\Aremote_file\.zip\Z/);   #exact file
  $sftp->match(qr/\.zip\Z/);                #any zip file
  $sftp->match(undef);                      #reset to default - all files

=cut

sub match {
  my $self=shift;
  if (@_) {
    $self->{'match'} = shift;
    delete $self->{'list'};
  }
  $self->{'match'}=$self->_match_default unless defined($self->{'match'});
  return $self->{'match'};
}

sub _match_default {
  return qr//;
}

=head2 backup

Sets or returns the backup folder property.

  $sftp->backup("");         #don't backup
  $sftp->backup("./folder"); #backup to folder

Note: If configured, backup overrides delete option.

=cut

sub backup {
  my $self=shift;
  $self->{'backup'}=shift if @_;
  $self->{'backup'}='' unless defined($self->{'backup'});
  return $self->{'backup'};
}

=head2 delete

Sets or returns the delete boolean property.

  $sftp->delete(0);          #don't delete
  $sftp->delete(1);          #delete after downloaded

Note: Ineffective when backup option is configured.

=cut

sub delete {
  my $self=shift;
  $self->{'delete'}=shift if @_;
  $self->{'delete'}=0 unless defined($self->{'delete'});
  return $self->{'delete'};
}

=head1 OBJECT ACCESSORS

=head2 sftp

Returns a cached connected L<Net::SFTP::Foreign> object

=cut

sub sftp {
  my $self=shift;
  unless (defined $self->{'sftp'}) {
    my %params      = ();
    $params{'host'} = $self->host    or die('Error: host required');
    $params{'user'} = $self->user    if $self->user;           #not required
    $params{'port'} = $self->port    if defined($self->port);  #not required
    $params{'more'} = $self->options if @{$self->options} > 0; #not required
    my $sftp        = Net::SFTP::Foreign->new($params{'host'}, %params);
    die(
      sprintf("Error connecting to sftp://%s%s%s/ - %s", 
                  ($params{'user'} ? $params{'user'} . '@' : ''),
                  $params{'host'},
                  ($params{'port'} ? ':' . $params{'port'} : ''),
                  $sftp->error
      )
    ) if $sftp->error;
    $self->{'sftp'} = $sftp;
  }
  return $self->{'sftp'};
}

=head1 BUGS

Use GitHub to fork repository and submit pull requests.

=head2 Testing

This packages relies on the SSH keys to be operational for the local account.  To test your SSH keys from the command line type  `sftp user@server`. If this command prompts the user for a password, then your SSH keys are not installed correctly.  You cannot reliably test with `ssh user@server` as the remote administrator may have disabled the terminal service over SSH.

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

=head2 Building Blocks

L<Path::Class::File>, L<Net::SFTP::Foreign>, L<File::Tempdir>

=cut

1;
