package Nuvol::Role::File;
use Mojo::Base -role, -signatures;

use Mojo::File;
use Mojo::URL;
use Mojo::UserAgent;

requires qw|_do_remove _do_slurp _do_spurt _from_file _from_host _from_url _get_download_url _to_host|;

# methods

sub copy_from ($self, $source) {
  my $sourcefile;

  if (ref $source) {
    $sourcefile = $source;
  } else {
    Carp::croak "'$source' is not a file!" if $source =~ /\/$/;
    $sourcefile = $self->drive->item($source);
  }

  my $source_ref = ref $sourcefile;
  if ($source_ref =~ /Mojo::File/) {
    $self->_from_host($sourcefile);
  } elsif ($source_ref eq ref $self) {
    $self->_from_file($sourcefile);
  } elsif ($source_ref =~ /Mojo::URL/) {
    $self->_from_url($sourcefile);
  } else {
    Carp::croak "Copy from $source_ref not supported!";
  }

  return $self;
}

sub copy_to ($self, $target) {
  my $targetfile;

  if (ref $target) {
    $targetfile = $target;
  } else {
    $target .= $self->name if $target =~ /\/$/;
    $targetfile = $self->drive->item($target);
  }

  my $target_ref = ref $targetfile;
  if ($target_ref =~ /Mojo::File/) {
    $self->_to_host($targetfile);
  } elsif ($target_ref eq ref $self) {
    $targetfile->_from_file($self);
  } else {
    Carp::croak "Copy to $target_ref not supported!";
  }

  return $targetfile;
}

sub download_url ($self)  { return Mojo::URL->new($self->_get_download_url); }
sub remove ($self)        { return $self->_do_remove; }
sub slurp ($self)         { return $self->_load->_do_slurp; }
sub spurt ($self, @bytes) { return $self->_load->_do_spurt(@bytes); }

# internal methods

sub _download_upload ($self, $url) {
  my $res      = Mojo::UserAgent->new->get($url)->result;
  Carp::confess $res->message if $res->is_error;

  my $tempfile = Mojo::File::tempfile;
  $res->content->asset->move_to($tempfile);
  $self->_from_host($tempfile);
}

1;

=encoding utf8

=head1 NAME

Nuvol::Role::File - Role for files

=head1 SYNOPSIS

    my $file = $drive->item('path/to/file');

    $file->copy_from;
    $file->copy_to;
    $file->spurt;
    $file->slurp;
    $file->download_url;
    $file->remove;

=head1 DESCRIPTION

L<Nuvol::Role::File> is a file role for L<items|Nuvol::Item>. It is automatically applied if an item
is recognized as a file.

=head1 METHODS

=head2 copy_from

    $file = $file->copy_from($source);

Copies the content of a source into the file. The source can be another L<Nuvol::Role::File>, a
string with a path on the current drive, a L<Mojo::File>, or a L<Mojo::URL>. It is the reverse of
L</copy_to>.

    $source = $drive->item('path/to/source');
    $file   = $file->copy_from($source);

Copies the file from another L<Nuvol::Role::File>.

    $source = 'path/to/source';
    $file   = $file->copy_from($source);

Copies the file from another file defined as source on the current drive.

    $source = Mojo::File->new('path/to/local_file');
    $file   = $file->copy_from($source);

Uploads the content of a local L<Mojo::File>.

    $source = Mojo::URL->new('https://url/of/the/file');

Downloads the content from a L<Mojo::URL>.

=head2 copy_to

    $target = $file->copy_to($target);

Copies the content of the file to a target that can be another L<Nuvol::Role::File>, a string with
the path on the current drive, or a L<Mojo::File>. It is the reverse of L</copy_from> and returns
the object where the content was copied to.

    $targetfile = $drive->item('path/to/targetfile');
    $targetfile = $file->copy_to($targetfile);

    $target_path = 'path/to/targetfile';
    $targetfile  = $file->copy_to($target_path);

Copies the file to another file, defined as L<Nuvol::Role::File> or a path to this file.

    $targetfolder = $drive->item('path/to/targetfolder/');
    $targetfile   = $file->copy_to($targetfolder);

    $target_path = 'path/to/targetfolder/';
    $targetfile  = $file->copy_to($target_path);

Copies the file to another file with the same name in the target folder, defined as
L<Nuvol::Role::Folder> or a path to this folder.

    $targetfile = Mojo::File->new('path/to/local_file');
    $targetfile = $file->copy_to($targetfile);

Copies the content to a file in the local file system, defined as L<Mojo::File>.

=head2 download_url

    $url = $file->download_url;

Getter for a short-lived URL to download the content.

=head2 remove

    $file = $file->remove;

Removes the file.

=head2 slurp

    $data = $file->slurp;

Reads the content at once.

=head2 spurt

    $file = $file->spurt(@data);

Writes data directly to the file and replaces its content.

=head1 SEE ALSO

L<Nuvol::Item>, L<Nuvol::Role::Folder>.

=cut
