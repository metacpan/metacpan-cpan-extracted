package Path::Extended::Entity;

use strict;
use warnings;
use Carp ();
use File::Spec;
use Log::Dump;
use Scalar::Util qw( blessed );

use overload
  '""'   => sub { shift->path },
  'cmp'  => sub { return "$_[0]" cmp "$_[1]" },
  'bool' => sub { shift->_boolify },
  '*{}'  => sub { shift->_handle };

sub new {
  my $class = shift;
  my $self  = bless {}, $class;

  $self->_initialize(@_) or return;

  $self;
}

sub _initialize {1}
sub _boolify {1}

sub _class {
  my ($self, $type) = @_;
  my $class = ref $self;
  $class =~ s/::(?:File|Dir|Entity)$//;
  return $class unless $type;
  return $class.'::'.($type eq 'file' ? 'File' : 'Dir');
}

sub _set_path {
    my ($self, $path) = @_;
    $self->{input_path} = $self->_unixify($path);
    $self->{abs_path}   = $self->_unixify( File::Spec->rel2abs($path) );

    # respect setting of _attribute when already done
    $self->{_stringify_absolute} ||= File::Spec->file_name_is_absolute($path);
}

sub _related {
  my ($self, $type, @parts) = @_;

  my $class = $self->_class($type);
  eval "require $class" or Carp::croak $@;
  my $item;
  if ( @parts && $parts[0] eq '..' ) { # parent
    require File::Basename;
    $item = $class->new( File::Basename::dirname($self->_absolute) );
  }
  elsif ( @parts && File::Spec->file_name_is_absolute($parts[0]) ) {
    $item = $class->new( @parts );
  }
  else {
    $item = $class->new( $self->_absolute, @parts );
  }
  foreach my $key ( grep /^_/, keys %{ $self } ) {
    $item->{$key} = $self->{$key};
  }
  $item;
}

sub _unixify {
  my ($self, $path) = @_;

  $path =~ s{\\}{/}g if $^O eq 'MSWin32';

  return $path;
}

sub _handle { shift->{handle} }

sub _stringify_absolute {
  my $self = shift;
  $self->{_stringify_absolute} && !$self->{_base} ? 1 : '';
}

# returns the string version of the path
sub path {
  my $self = shift;
  return ( $self->_stringify_absolute ) ? $self->_absolute : $self->_relative;
}

sub stringify { shift->path }

sub is_dir      { shift->{is_dir} }
sub is_open     { shift->{handle} ? 1 : 0 }


sub is_absolute {
  my $self = shift;
  File::Spec->file_name_is_absolute($self->{input_path});
}

sub resolve {
  my $self = shift;
  Carp::croak "$self: $!" unless -e $self->{abs_path};
  # WoP :
  # Cwd::realpath returns the resolved absolute path
  # calling File::Spec->file_name_is_absolute() not necessary
  $self->{abs_path}  = $self->_unixify(Cwd::realpath($self->{abs_path}));
  $self->{_stringify_absolute} = File::Spec->file_name_is_absolute($self->{abs_path});
  $self;
}

sub _absolute {
  my ($self, %options) = @_;

  my $path = File::Spec->canonpath( $self->{abs_path} );
  if ( $options{native} ) {
    return $path;
  }
  elsif ( $self->{_compat} ) {
    my ($vol, @parts) = File::Spec->splitpath( $path );
    $vol = '' if $Path::Extended::IgnoreVolume;
    return $self->_unixify( File::Spec->catpath($vol, File::Spec->catdir( @parts ), '') );
  }
  else {
    return $self->_unixify($path);
  }
}

sub _relative {
  my $self = shift;
  my $base = @_ % 2 ? shift : undef;
  my %options = @_;

  $base ||= $options{base} || $self->{_base};

  my $path = File::Spec->abs2rel( $self->{abs_path}, $base );
     $path = $self->_unixify($path) unless $options{native};

  $path;
}

sub absolute { shift->_absolute(@_) }
sub relative { shift->_relative(@_) }

sub parent { shift->_related( dir => '..' ); }

sub unlink {
  my $self = shift;

  $self->close if $self->is_open;
  unlink $self->_absolute if $self->exists;
}

sub exists {
  my $self = shift;

  -e $self->_absolute ? 1 : 0;
}

sub is_writable {
  my $self = shift;

  -w $self->_absolute ? 1 : 0;
}

sub is_readable {
  my $self = shift;

  -r $self->_absolute ? 1 : 0;
}

sub copy_to {
  my ($self, $destination) = @_;

  unless ( $destination ) {
    $self->log( fatal => 'requires destination' );
    return;
  }

  my $class = ref $self;
  $destination = $class->new( "$destination" );

  require File::Copy::Recursive;
  File::Copy::Recursive::rcopy( $self->_absolute, $destination->_absolute )
    or do { $self->log( error => "Can't copy $self to $destination: $!" ); return; };

  $self;
}

sub move_to {
  my ($self, $destination) = @_;

  unless ( $destination ) {
    $self->log( fatal => 'requires destination' );
    return;
  }

  my $class = ref $self;
  $destination = $class->new( "$destination" );

  $self->close if $self->is_open;

  require File::Copy::Recursive;
  File::Copy::Recursive::rmove( $self->_absolute, $destination->_absolute )
    or do { $self->log( error => "Can't move $self to $destination: $!" ); return; };

  $self->{abs_path} = $destination->_absolute;

  $self;
}

sub rename_to {
  my ($self, $destination) = @_;

  unless ( $destination ) {
    $self->log( fatal => 'requires destination' );
    return;
  }

  my $class = ref $self;
  $destination = $class->new( "$destination" );

  $self->close if $self->is_open;

  rename $self->_absolute => $destination->_absolute
    or do { $self->log( error => "Can't rename $self to $destination: $!" ); return; };

  $self->{abs_path} = $destination->_absolute;

  $self;
}

sub stat {
  my $self = shift;

  require File::stat;
  File::stat::stat( $self->{handle} || $self->{abs_path} );
}

sub lstat {
  my $self = shift;

  require File::stat;
  File::stat::lstat( $self->{handle} || $self->{abs_path} );
}

1;

__END__

=head1 NAME

Path::Extended::Entity

=head1 SYNOPSIS

  use Path::Extended::File;
  my $file = Path::Extended::File->new('path/to/some.file');

=head1 DESCRIPTION

This is a base class for L<Path::Extended::File> and L<Path::Extended::Dir>.

=head1 METHODS

=head2 new

creates an appropriate object. Note that this base class itself doesn't hold anything.

=head2 absolute

may take an optional hash, and returns an absolute path of the file/directory. Note that back slashes in the path will be converted to forward slashes unless you explicitly set a C<native> option to true.

=head2 relative

may take an optional hash, and returns a relative path of the file/directory (compared to the current directory (Cwd::cwd) by default, but you may change this bahavior by passing a C<base> option). Note that back slashes in the path will be converted to forward slashes unless you explicitly set a C<native> option to true.

=head2 is_absolute

returns if the path you passed to the constructor was absolute or not (note that the path stored in an object is always absolute).

=head2 is_dir

returns if the object represents directory or not.

=head2 resolve

does a physical cleanup of the path with L<Cwd::realpath>, that means, resolves a symbolic link if necessary. Note that this method may croak (when the path does not exist).

=head2 copy_to

copies the file/directory to the destination by C<File::Copy::copy>.

=head2 move_to

moves the file/directory to the destination by C<File::Copy::move>. If the file/directory is open, it'll automatically close.

=head2 rename_to

renames the file/directory. If the file/directory is open, it'll automatically close. If your OS allows rename of an open file, you may want to use built-in C<rename> function for better atomicity.

=head2 unlink

unlinks the file/directory. The same thing can be said as for the C<rename_to> method.

=head2 exists

returns true if the file/directory exists.

=head2 is_readable, is_writable

returns true if the file/directory is readable/writable.

=head2 is_open

returns true if the file/directory is open.

=head2 stat, lstat

returns a File::stat object for the file/directory.

=head2 parent

returns a L<Path::Extended::Dir> object that points to the parent directory of the file/directory.

=head2 path, stringify

explicitly returns a path string.

=head2 log, logger, logfile, logfilter

You may optionally pass a logger object with C<log> method that accepts C<< ( label => @log_messages ) >> array arguments to notifty when some (usually unfavorable) thing occurs. By default, a built-in L<Carp> logger will be used. If you want to disable logging, set a false value to C<logger>. See L<Log::Dump> for details, and for how to use C<logfile> and C<logfilter> methods.

=head1 SEE ALSO

L<Path::Extended>, L<Path::Extended::File>, L<Path::Extended::Dir>, L<Log::Dump>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
