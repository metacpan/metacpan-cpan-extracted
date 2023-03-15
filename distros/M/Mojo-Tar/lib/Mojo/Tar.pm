package Mojo::Tar;
use Mojo::Base 'Mojo::EventEmitter', -signatures;

use Carp qw(croak);
use Mojo::Collection;
use Mojo::Tar::File;
use Scalar::Util qw(blessed);

use constant DEBUG          => !!$ENV{MOJO_TAR_DEBUG};
use constant TAR_BLOCK_SIZE => 512;
use constant TAR_BLOCK_PAD  => "\0" x TAR_BLOCK_SIZE;

our $VERSION = '0.01';

has is_complete => 0;

sub create ($self) {
  my ($current, $handle, $header, $idx, $read) = (undef, undef, '', -1, 0);
  my $cb = sub (@) {
    unless ($current //= $self->files->[++$idx]) {
      return ''                 if $self->is_complete;
      warn "[tar:create] EOF\n" if DEBUG;
      return $self->is_complete(1) && TAR_BLOCK_PAD . TAR_BLOCK_PAD;
    }
    unless ($header) {
      warn "[tar:create] Adding @{[$current->asset]}\n" if DEBUG;
      $self->emit(adding => $current);
      return $header = $current->to_header;
    }

    $handle //= $current->asset->open('<');
    my $r = $handle->sysread(my $buffer, 131072) // croak "Unable to read @{[$current->asset]}: $!";
    $read += $r;
    return $buffer if length $buffer;

    warn "[tar:create] Added @{[$current->asset]} ($read)\n" if DEBUG;
    $self->emit(added => $current);
    ($current, $handle, $header) = (undef, undef, '');
    return __SUB__->();
  };

  return $self->is_complete(0) && $cb;
}

sub extract ($self, $bytes) {
  $self->{buf} .= $bytes;

  while (1) {
    last if length($self->{buf}) < 512;
    my $block = substr $self->{buf}, 0, 512, '';

    if (my $file = $self->{current}) {
      $file->add_block($block);
      $self->emit(extracted => delete $self->{current}) if $file->is_complete;
    }
    elsif ($block eq TAR_BLOCK_PAD) {
      warn "[tar:extract] Got tar pad block\n" if DEBUG;
      $self->{buf} = '';
      return $self->is_complete(1);
    }
    else {
      my $file = Mojo::Tar::File->new->from_header($block);
      push @{$self->files}, $file;
      $self->is_complete(0)->emit(extracting => $file);
      $file->size ? ($self->{current} = $file) : $self->emit(extracted => $file);
    }
  }

  return $self;
}

sub files ($self, $files = undef) {
  return $self->{files} //= Mojo::Collection->new unless $files;

  my $c = $self->{files} = Mojo::Collection->new;
  for my $file (@$files) {
    if (blessed($file) && $file->isa('Mojo::Tar::File')) {
      push @$c, $file;
    }
    else {
      push @$c, Mojo::Tar::File->new->asset(Mojo::File->new("$file"))->path("$file");
    }
  }

  return $self;
}

sub looks_like_tar ($self, $bytes) {
  state $padding = "\0" x TAR_USTAR_PADDING_LEN;
  return
      length($bytes) < TAR_BLOCK_SIZE                                          ? 0
    : substr($bytes, TAR_USTAR_PADDING_POS, TAR_USTAR_PADDING_LEN) ne $padding ? 0
    : Mojo::Tar::File->new->from_header($bytes)->checksum                      ? 1
    :                                                                            0;
}

sub new ($class, @attrs) {
  my $self = $class->SUPER::new(@attrs);
  $self->files($self->{files}) if $self->{files};
  return $self;
}

1;

=encoding utf8

=head1 NAME

Mojo::Tar - Stream your (ustar) tar files

=head1 SYNOPSIS

=head2 Create

  use Mojo::Tar
  my $tar = Mojo::Tar->new;

  $tar->on(adding => sub ($self, $file) {
    warn sprintf qq(Adding "%s" %sb to archive\n), $file->path, $file->size;
  });

  my $cb = $tar->files(['a.baz', 'b.foo'])->create;
  open my $fh, '>', '/path/to/my-archive.tar';
  while (length(my $chunk = $cb->())) {
    print {$fh} $chunk;
  }

=head2 Extract

  use Mojo::Tar
  my $tar = Mojo::Tar->new;

  $tar->on(extracted => sub ($self, $file) {
    warn sprintf qq(Extracted "%s" %sb\n), $file->path, $file->size;
  });

  open my $fh, '<', '/path/to/my-archive.tar';
  while (1) {
    sysread $fh, my ($chunk), 512 or die $!;
    $tar->extract($chunk);
  }

=head1 DESCRIPTION

L<Mojo::Tar> can create and extract L<ustar|http://www.gnu.org/software/tar/manual/tar.html>
tar files as a stream. This can be useful if for example your webserver is
receiving a big tar file and you don't want to exhaust the memory while
reading it.

The L<pax|http://www.opengroup.org/onlinepubs/007904975/utilities/pax.html>
tar format is not planned, but a pull request is more than welcome!

Note that this module is currently EXPERIMENTAL, but the API will only change
if major design issues is discovered.

=head1 EVENTS

=head2 added

  $tar->on(added => sub ($tar, $file) { ... });

Emitted after the callback from L</create> has returned all the content of the C<$file>.

=head2 adding

  $tar->on(adding => sub ($tar, $file) { ... });

Emitted right before the callback from L</create> returns the tar header for the
C<$file>.

=head2 extracted

  $tar->on(extracted => sub ($tar, $file) { ... });

Emitted when L</extract> has read the complete content of the file.

=head2 extracting

  $tar->on(extracting => sub ($tar, $file) { ... });

Emitted when L</extract> has read the tar header for a L<Mojo::Tar::File>. This
event can be used to set the L<Mojo::Tar::File/asset> to something else than a
temp file.

=head1 ATTRIBUTES

=head2 files

  $tar = $tar->files(Mojo::Collection->new('a.file', ...)]);
  $tar = $tar->files([Mojo::File->new]);
  $tar = $tar->files([Mojo::Tar::File->new, ...]);
  $collection = $tar->files;

This attribute holds a L<Mojo::Collection> of L<Mojo::Tar::File> objects which
is used by either L</create> or L</extract>.

Setting this attribute will make sure each item is a L<Mojo::Tar::File> object,
even if the original list contained a L<Mojo::File> or a plain string.

=head2 is_complete

  $bool = $tar->is_complete;

True when the callback from L</create> has returned the whole tar-file or when
L</extract> thinks the whole tar file has been read.

Note that because of this, L</create> and L</extract> should not be called on
the same object.

=head1 METHODS

=head2 create

  $cb = $tar->create;

This method will take L</files> and return a callback that will return a chunk
of the tar file each time it is called, and an empty string when all files has
been processed. Example:

  while (length(my $chunk = $cb->())) {
    warn sprintf qq(Got %sb of tar data\n), length $chunk;
  }

The L</adding> and L</added> events will be emitted for each file. In addition
L</is_complete> will be set when all the L</files> has been processed.

=head2 extract

  $tar = $tar->extract($bytes);

Used to parse C<$bytes> and turn the information into L<Mojo::Tar::File>
objects which are emitted as L</extracting> and L</extracted> events.

=head2 looks_like_tar

  $bool = $tar->looks_like_tar($bytes);

Returns true if L<Mojo::Tar> thinks C<$bytes> looks like the beginning of a
tar stream. Currently this checks if C<$bytes> is at least 512 bytes long and
the checksum value in the tar header is correct.

=head2 new

  $tar = Mojo::Tar->new(\%attrs);
  $tar = Mojo::Tar->new(%attrs);

Used to create a new L<Mojo::Tar> object. L</files> will be normalized.

=head1 AUTHOR

Jan Henning Thorsen

=head1 COPYRIGHT AND LICENSE

Copyright (C) Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Archive::Tar>

=cut
