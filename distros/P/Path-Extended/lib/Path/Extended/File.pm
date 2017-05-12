package Path::Extended::File;

use strict;
use warnings;
use base qw( Path::Extended::Entity );
use IO::Handle;
use Sub::Install;

sub _initialize {
  my ($self, @args) = @_;

  my $file = File::Spec->catfile( @args );
  $self->{_stringify_absolute} = 1; # always true for ::Extended::File
  $self->{is_dir}    = 0;
  $self->_set_path($file);
}

sub basename {
  my $self = shift;
  require File::Basename;
  return File::Basename::basename( $self->{abs_path} );
}

sub open {
  my ($self, $mode) = @_;

  $self->close if $self->is_open;

  $mode ||= 'r';

  my $fh;
  if ( $mode =~ /:/ ) {
    open $fh, $mode, $self->_absolute
      or do { $self->log( error => "Can't open $self: $!" ); return; };
  }
  else {
    open $fh, IO::Handle::_open_mode_string($mode), $self->{abs_path}
      or do { $self->log( error => "Can't open $self: $!" ); return; };
  }

  return $fh if $self->{_compat} && defined wantarray;

  $self->{handle} = $fh;

  $self;
}

sub openr { shift->open('r') }
sub openw { shift->open('w') }

sub sysopen {
  my $self = shift;

  $self->close if $self->is_open;

  CORE::sysopen my $fh, $self->_absolute, @_
    or do { $self->log( error => "Can't open $self: $!" ); return; };

  $self->{handle} = $fh;

  $self;
}

sub close {
  my $self = shift;

  if ( my $fh = delete $self->{handle} ) {
    CORE::close $fh;
  }
}

sub binmode {
  my $self = shift;

  return unless $self->is_open;

  my $fh = $self->{handle};

  if ( @_ ) {
    CORE::binmode $fh, shift;
  }
  else {
    CORE::binmode $fh;
  }
}

BEGIN {
  my @io_methods = qw(
    print printf say getline getlines read sysread write syswrite
    autoflush flush printflush getc ungetc truncate blocking
    eof fileno error sync fcntl ioctl
  );

  foreach my $method (@io_methods) {
    Sub::Install::install_sub({
      as   => $method,
      code => sub {
        return unless $_[0]->is_open; shift->{handle}->$method(@_);
      },
    });
  }
}

sub lock_ex { return unless $_[0]->is_open; shift->_lock }
sub lock_sh { return unless $_[0]->is_open; shift->_lock('share') }

sub _lock {
  my ($self, $mode) = @_;

  my $fh = $self->{handle};

  require Fcntl;
  flock $fh, ( $mode && $mode eq 'share' )
    ? Fcntl::LOCK_SH()
    : Fcntl::LOCK_EX();
}

sub seek {
  my ($self, $pos, $whence) = @_;

  return unless $self->is_open;

  my $fh = $self->{handle};

  seek $fh, $pos, $whence;
}

sub sysseek {
  my ($self, $pos, $whence) = @_;

  return unless $self->is_open;

  my $fh = $self->{handle};

  sysseek $fh, $pos, $whence;
}

sub tell {
  my $self = shift;

  return unless $self->is_open;

  my $fh = $self->{handle};

  tell $fh;
}

sub slurp {
  my ($self, @args) = @_;

  my $options = ( @args == 1 and ref $args[0] eq 'HASH' )
    ? $args[0]
    : { @args };

  my $iomode = $options->{iomode} || 'r';
  $self->open($iomode);
  unless ( $self->is_open ) {
    $self->log( warn => "Can't read", $self->{abs_path}, $! );
    return;
  }

  $self->binmode if $options->{binmode};
  my @callbacks;
  my $callback = sub {
    my $line = shift;
    for my $subr (@callbacks) { $line = $subr->(local $_ = $line) }
    $line;
  };
  if ( $options->{chomp} ) {
    push @callbacks, sub { my $line = shift; chomp $line; $line };
  }
  if ( $options->{decode} ) {
    require Encode;
    push @callbacks, sub {
      Encode::decode( $options->{decode}, shift )
    };
  }
  if ( $options->{callback} ) {
    push @callbacks, $options->{callback};
  }
  my $filter;
  if ( my $rule = $options->{filter} ) {
    $filter = qr/$rule/;
  }
  $options->{ignore_return_value} = 1 if !defined wantarray;

  # shortcut
  if (!@callbacks and !$filter and !wantarray) {
    my $got = do { local $/; $self->getline };
    $self->close;
    return $got;
  }

  my @lines;
  while( defined (my $line = $self->getline )) {
    $line = $callback->($line);
    next if $filter && $line !~ /$filter/;
    push @lines, $line unless $options->{ignore_return_value};
  }
  $self->close;
  return wantarray ? @lines : join '', @lines;
}

sub grep {  # just a spoonful of sugar
  my ($self, $rule, @args) = @_;

  my $options = ( @args == 1 and ref $args[0] eq 'HASH' )
    ? $args[0]
    : { @args };

  $options->{filter} = $rule;

  $self->slurp($options);
}

sub save {
  my ($self, $content, @args) = @_;

  my $options = ( @args == 1 and ref $args[0] eq 'HASH' )
    ? $args[0]
    : { @args };

  if ( $options->{mkdir} ) {
    $self->parent->mkdir;
  }
  my $mode = $options->{mode} || $options->{append} ? '>>' : '>';
  $self->open($mode);
  unless ( $self->is_open ) {
    $self->log( warn => "Can't save", $self->_absolute, $! );
    return;
  }

  if ( $options->{lock} ) {
    unless ( $self->lock_ex ) {
      $self->log( warn => "Can't lock", $self->{abs_path}, $! );
      return;
    }
  }
  $self->binmode if $options->{binmode};

  my @callbacks;
  my $callback = sub {
    my $line = shift;
    for my $subr (@callbacks) { $line = $subr->(local $_ = $line) }
    $line
  };
  if ( $options->{encode} ) {
    require Encode;
    push @callbacks, sub {
      Encode::encode( $options->{encode}, shift )
    };
  }
  if ( $options->{callback} ) {
    push @callbacks, $options->{callback};
  }

  $self->print(
    map { $callback->($_) }
    ref $content eq 'ARRAY' ? @{ $content } : $content
  );
  $self->close;

  if ( $options->{mtime} ) {
    $self->mtime( $options->{mtime} );
  }

  $self;
}

sub touch {
  my $self = shift;

  if ( $self->exists ) {
    $self->mtime(time);
  }
  else {
    $self->openw or return;
    $self->close;
  }
  $self;
}

sub size { return -s ( $_[0]->{handle} || $_[0]->{abs_path} ) }

sub mtime {
  my $self = shift;

  return unless $self->exists;

  if ( @_ ) {
    my $mtime = shift;
    utime $mtime, $mtime, $self->_absolute;
  }
  else {
    return $self->stat->mtime;
  }
}

sub remove { shift->unlink(@_) }

1;

__END__

=head1 NAME

Path::Extended::File

=head1 SYNOPSIS

  use Path::Extended::File;
  my $file = Path::Extended::File->new('path/to/file');

  # you can get information of the file
  print $file->basename;  # file
  print $file->absolute;  # /absolute/path/to/file

  # you can get an object for the parent directory
  my $parent_dir = $file->parent;

  # Path::Extended::File object works like an IO handle
  $file->openr;
  my $first_line = $file->getline;
  print <$file>;
  close $file;

  # it also can do some extra file related tasks
  $file->copy_to('/other/path/to/file');
  $file->unlink if $file->exists;

  $file->slurp(chomp => 1, callback => sub {
    my $line = shift;
    print $line, "\n" unless substr($line, 0, 1) eq '#';
  });

  file('/path/to/other_file')->save(\@lines, { mkdir => 1 });

  # it has a logger, too
  $file->log( fatal => "Couldn't open $file: $!" );

=head1 DESCRIPTION

This class implements file-specific methods. Most of them are simple wrappers of the equivalents from various File::* or IO::* classes. See also L<Path::Class::Entity> for common methods like C<copy> and C<move>.

=head1 METHODS

=head2 new

takes a path or parts of a path of a file, and creates a L<Path::Extended::File> object. If the path specified is a relative one, it will be converted to the absolute one internally. Note that this doesn't open a file even when you pass an extra file mode (which will be considered as a part of the file name).

=head2 basename

returns a base name of the file via C<File::Basename::basename>.

=head2 open

opens the file with a specified mode, and returns the $self object to chain methods, or undef if there's anything wrong (the handle opened is stored internally). You can use characters like "r" and "w", or symbols like "<" and ">". If you want to specify IO layers, use the latter format (e.g. "<:raw"). If the file is already open, it closes at first and opens again.

=head2 openr, openw

These are shortcuts for ->open("r") and ->open("w") respectively.

=head2 sysopen

takes the third (and the fourth if necessary) arguments (i.e. mode and permission) of the native C<sysopen>, and opens the file, and returns the $self object, or undef if there's anything wrong. The handle opened is stored internally.

=head2 binmode

may take an argument (to specify I/O layers), and arranges for the stored file handle to handle binary data properly. No effect if the file is not open.

=head2 close

closes the stored file handle and removes it from the object. No effect if the file is not open.

=head2 print, printf, say, getline, getlines, read, sysread, write, syswrite, autoflush, flush, printflush, getc, ungetc, truncate, blocking, eof, fileno, error, sync, fcntl, ioctl

are simple wrappers of the equivalents of L<IO::Handle>. No effect if the file is not open.

=head2 lock_ex, lock_sh

locks the stored file handle with C<flock>. No effect if the file is not open.

=head2 seek, sysseek, tell

are simple wrappers of the equirvalent built-in functions. Note that L<Path::Extended> doesn't export constants like C<SEEK_SET>, C<SEEK_CUR>, C<SEEK_END>.

=head2 mtime

returns a mtime of the file/directory. If you pass an argument, you can change the mtime of the file/directory.

=head2 size

returns a size of the file/directory.

=head2 remove

unlink the file.

=head2 slurp

may take a hash (or a hash referernce) option, then opens the file, does various things for each line with callbacks if necessary, and returns an array of the lines (list context), or the concatenated string (scalar context).

Options are:

=over 4

=item binmode

arranges for the file handle to read binary data properly if set to true.

=item chomp

chomps the end-of-lines if set to true.

=item decode

decodes the lines with the specified encoding.

=item callback

does arbitrary things through the specified code reference.

=item filter

C<slurp> usually returns all the (processed) lines. With this option (which should be a string or a regex), C<slurp> returns only the lines that match the filter rule.

=item ignore_return_value

C<slurp> usually stores everything on memory, but sometimes you don't need a return value (especially when you do something with a C<callback>). If this is set to true, C<slurp> doesn't store lines on memory. Note that if you use C<slurp> in the void context, this will be set to true internally.

=back

=head2 grep

  my @found = $file->grep('string or regex', ...);

=head2 save

takes a string or an array reference of lines, and an optional hash (or a hash reference), then opens the file, does various things for each line (or the entire string) with callbacks if necessary, and saves the content to the file, and returns the $self object or undef if there's anything wrong.

Options are:

=over 4

=item mkdir

creates a parent directory if necessary.

=item mode, append

takes a mode specification ("w", "a", or equivalent symbols). The default is a write mode, and if you set C<append> option to true, it will be changed to a append mode.

=item lock

locks exclusively while writing.

=item binmode

arranges for the file handle to write binary data properly.

=item encode

encodes the lines (or the entire string) with the specified encoding.

=item callback

does arbitrary things through the specified code reference.

=item mtime

changes the last modified time to the specified time.

=back

=head2 touch

changes file access and modification times, or creates a blank file when it doesn't exist.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
