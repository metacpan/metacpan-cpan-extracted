package Path::Extended::Tiny;

use strict;
use warnings;
use Carp;
use Path::Tiny ();
use Scalar::Util ();
use Exporter 5.57 qw/import/;
use IO::Handle;

our $VERSION = '0.08';

our @EXPORT    = qw(file dir file_or_dir dir_or_file);
our @EXPORT_OK = (@Path::Tiny::EXPORT, @Path::Tiny::EXPORT_OK);
our $AUTOLOAD;

use overload
  '""'   => sub { shift->_path },
  'cmp'  => sub { return "$_[0]" cmp "$_[1]" },
  'bool' => sub { shift->_boolify },
  '*{}'  => sub { shift->_handle };

sub new { shift; _new(@_) }

sub _new {
  my $path;
  if (ref $_[0] eq __PACKAGE__) {
    $path = shift->[0];
    if (@_) {
      my $new = Path::Tiny::path(@_);
      if ($new->is_absolute) {
        $path = $new;
      } else {
        $path = $path->child($new);
      }
    }
  } else {
    $path = Path::Tiny::path(@_);
  }
  bless [$path], __PACKAGE__;
}

sub _boolify { 1 }
sub _handle { $_[0]->[1] }

*file = *dir = *subdir = *file_or_dir = *dir_or_file = \&_new;

# ::Entity methods

sub path { $_[0]->[0]->stringify }
sub stringify { $_[0]->[0]->stringify }
sub parent { _new($_[0]->[0]->parent) }
sub _path { $_[0]->[0][0] }

sub is_dir { -d $_[0]->_path ? 1 : 0 }
sub is_open { $_[0]->[1] || $_[0]->[2] ? 1 : 0 }
sub is_absolute { $_[0]->[0]->is_absolute }
sub resolve { $_[0]->[0] = $_[0]->[0]->realpath; $_[0] }
sub absolute { $_[0]->[0]->absolute }
sub relative {
  my $self = shift;
  my $base = @_ == 1 ? shift : {@_}->{base};
  $self->[0]->relative($base);
}
sub unlink {
  my $self = shift;
  $self->close if $self->is_open;
  unlink $self->_path if $self->exists;
}
sub exists { -e $_[0]->_path ? 1 : 0 }
sub is_writable { -w $_[0]->_path ? 1 : 0 }
sub is_readable { -r $_[0]->_path ? 1 : 0 }
sub copy_to {
  my ($self, $dest) = @_;
  unless ($dest) { return $self->_error("requires destination") }
  require File::Copy::Recursive;
  File::Copy::Recursive::rcopy($self->_path, $dest) or return $self->_error("Can't copy $self to $dest");
  $self;
}
sub move_to {
  my ($self, $dest) = @_;
  unless ($dest) { return $self->_error("requires destination") }
  $self->close if $self->is_open;
  require File::Copy::Recursive;
  File::Copy::Recursive::rmove($self->_path, $dest) or return $self->_error("Can't move $self to $dest");
  @{$self} = @{_new($dest)};
  $self;
}
sub rename_to {
  my ($self, $dest) = @_;
  unless ($dest) { return $self->_error("requires destination") }
  $self->close if $self->is_open;
  rename $self->_path, $dest or return $self->_error("Can't rename $self to $dest");
  @{$self} = @{_new($dest)};
  $self;
}
sub stat { $_[0]->[0]->stat }
sub lstat { $_[0]->[0]->lstat }

# polymorphic methods for ::File and ::Dir

sub logger {
  my $self = shift;
  if (@_) { $self->[3] = $_[0] ? 0 : 1 }
}
sub log { my $self = shift; carp @_ unless $self->[3] }
sub _error { shift->log(@_); return }
sub basename { $_[0]->[0]->basename }
sub open {
  my ($self, $mode) = @_;
  $self->close if $self->is_open;
  if (-d $self->_path) {
    opendir my $dh, $self->_path or return $self->_error("Can't open $self: $!");
    $self->[2] = $dh;
  } else {
    unless ($mode && $mode =~ /:/) {
      $mode = IO::Handle::_open_mode_string($mode || 'r');
    }
    open my $fh, $mode, $self->_path or return $self->_error("Can't open $self: $!");
    $self->[1] = $fh;
  }
  $self;
}
sub close {
  my $self = shift;
  my $ret;
  if ($self->[1]) {
    $ret = CORE::close $self->[1];
    $self->[1] = undef;
  }
  if ($self->[2]) {
    $ret = closedir $self->[2];
    $self->[2] = undef;
  }
  $ret;
}
sub read {
  my $self = shift;
  if ($self->[1]) { return $self->[1]->read(@_) }
  if ($self->[2]) { return readdir $self->[2] }
}
sub seek {
  my $self = shift;
  if ($self->[1]) { return seek $self->[1], shift, shift }
  if ($self->[2]) { return seekdir $self->[2], shift || 0 }
}
sub tell {
  my $self = shift;
  if ($self->[1]) { return tell $self->[1] }
  if ($self->[2]) { return telldir $self->[2] }
}
sub remove {
  my ($self, @args) = @_;
  $self->close if $self->is_open;
  return $self unless $self->exists;
  if (-d $self->_path) {
    require File::Path;
    eval { File::Path::rmtree($self->_path, @args); 1 }
      or return $self->_error($@);
  }
  elsif (-f $self->_path) {
    CORE::unlink $self->_path;
  }
  $self;
}

# ::File methods

sub touch { $_[0]->[0]->touch; $_[0] }

sub openr { shift->open('r') }
sub openw { shift->open('w') }
sub sysopen {
  my $self = shift;
  $self->close if $self->is_open;
  CORE::sysopen my $fh, $self->_path, @_ or return $self->_error("Can't open $self: $!");
  $self->[1] = $fh;
  $self;
}
sub binmode {
  my $self = shift;
  return unless $self->[1];
  @_ ? CORE::binmode $self->[1], shift : CORE::binmode $self->[1];
}

# IO methods
BEGIN {
  no strict 'refs';
  for my $method (qw(
    print printf say getline getlines sysread write syswrite
    autoflush flush printflush getc ungetc truncate blocking
    eof fileno error sync fcntl ioctl
  )) {
    *$method = sub {
      my $self = shift;
      $self->[1] and $self->[1]->$method(@_);
    };
  }
}

sub lock_ex {
  my $self = shift;
  require Fcntl;
  $self->[1] and flock $self->[1], Fcntl::LOCK_EX();
}

sub lock_sh {
  my $self = shift;
  require Fcntl;
  $self->[1] and flock $self->[1], Fcntl::LOCK_SH();
}

sub sysseek {
  my ($self, $pos, $whence) = @_;
  $self->[1] and sysseek $self->[1], $pos, $whence;
}

sub slurp {
  my ($self, @args) = @_;
  my $opts = _opts(@args);
  my $iomode = $opts->{iomode} || 'r';
  $self->open($iomode);
  unless ($self->is_open) {
    return $self->_error("Can't read $self: $!");
  }
  $self->binmode if $opts->{binmode};

  my @callbacks;
  my $callback = sub {
    my $line = shift;
    for my $subr (@callbacks) { $line = $subr->(local $_ = $line) }
    $line;
  };
  if ( $opts->{chomp} ) {
    push @callbacks, sub { my $line = shift; chomp $line; $line };
  }
  if ( $opts->{decode} ) {
    require Encode;
    push @callbacks, sub {
      Encode::decode( $opts->{decode}, shift )
    };
  }
  if ( $opts->{callback} ) {
    push @callbacks, $opts->{callback};
  }
  my $filter;
  if (my $rule = $opts->{filter}) {
    $filter = qr/$rule/;
  }
  $opts->{ignore_return_value} = 1 if !defined wantarray;

  # shortcut
  if (!@callbacks and !$filter and !wantarray) {
    my $got = do { local $/; $self->getline };
    $self->close;
    return $got;
  }

  my @lines;
  while(defined (my $line = $self->getline)) {
    $line = $callback->($line);
    next if $filter && $line !~ /$filter/;
    push @lines, $line unless $opts->{ignore_return_value};
  }
  $self->close;
  return wantarray ? @lines : join '', @lines;
}

sub grep {
  my ($self, $rule, @args) = @_;
  my $opts = _opts(@args);
  $opts->{filter} = $rule;
  $self->slurp($opts);
}

sub save {
  my ($self, $content, @args) = @_;
  my $opts = _opts(@args);
  my $path = $self->[0];
  if ($opts->{mkdir}) {
    $path->parent->mkpath;
  }
  my $mode = $opts->{mode} || $opts->{append} ? '>>' : '>';
  $self->open($mode);
  unless ($self->is_open) {
    return $self->_error("Can't save $self: $!");
  }
  if ($opts->{lock} && !$self->lock_ex) {
    return $self->_error("Can't lock $self: $!");
  }
  $self->binmode if $opts->{binmode};

  my @callbacks;
  my $callback = sub {
    my $line = shift;
    for my $subr (@callbacks) { $line = $subr->(local $_ = $line) }
    $line
  };
  if ( $opts->{encode} ) {
    require Encode;
    push @callbacks, sub {
      Encode::encode( $opts->{encode}, shift )
    };
  }
  if ( $opts->{callback} ) {
    push @callbacks, $opts->{callback};
  }

  $self->print(
    map { $callback->($_) }
    ref $content eq 'ARRAY' ? @{ $content } : $content
  );
  $self->close;

  if ($opts->{mtime}) {
    $self->mtime($opts->{mtime});
  }
  $self;
}

sub size {
  my $self = shift;
  return unless $self->exists;
  $self->[0]->stat->size;
}

sub mtime {
  my $self = shift;
  return unless $self->exists;
  if (@_) {
    utime $_[0], $_[0], $self->_path;
  } else {
    $self->[0]->stat->mtime;
  }
}

# ::Dir methods

sub mkdir {
  my $self = shift;
  unless ($self->exists) {
    require File::Path;
    eval { File::Path::mkpath($self->_path); 1 }
      or return $self->_error($@);
  }
  $self;
}
*mkpath = \&mkdir;

sub rewind { $_[0]->[2] and rewinddir $_[0]->[2] }
sub find { shift->_find(0, @_) }
sub find_dir { shift->_find(1, @_) }
sub _find {
  my ($self, $is_dir, $rule, %opts) = @_;
  require Text::Glob;
  $rule = Text::Glob::glob_to_regex($rule);
  my $iter = $self->[0]->iterator({recurse => 1});
  my @paths;
  while(my $path = $iter->()) {
    next unless ($is_dir ? -d $path : -f $path);
    my $relpath = $path->relative($self->[0]);
    next unless $relpath =~ /$rule/;
    next if $relpath =~ m{/\.};
    push @paths, _new($path);
  }
  if ($opts{callback}) {
    @paths = $opts{callback}->(@paths);
  }
  @paths;
}
sub rmdir {
  my ($self, @args) = @_;
  $self->close if $self->is_open;
  if ($self->exists && -d $self->_path) {
    require File::Path;
    eval { File::Path::rmtree($self->_path, @args); 1 }
      or return $self->_error($@);
  }
  $self;
}
*rmtree = \&rmdir;

sub next {
  my $self = shift;
  $self->open unless $self->is_open;
  my $next = $self->read;
  unless (defined $next) {
    $self->close;
    return;
  }
  $self->[0]->child($next);
}
sub children {
  my ($self, %opts) = @_;
  $self->open or return;
  my @children;
  while (defined(my $path = $self->read)) {
    next if (!$opts{all} && ($path eq '.' || $path eq '..'));
    my $child = $self->[0]->child($path);
    if ($opts{prune} or $opts{no_hidden}) {
      if (ref $opts{prune} eq ref qr//) {
        next if $path =~ /$opts{prune}/;
      }
      elsif (ref $opts{prune} eq ref sub {}) {
        next if $opts{prune}->(_new($child));
      }
      else {
        next if $path =~ /^\./;
      }
    }
    push @children, _new($child);
  }
  $self->close;
  return @children;
}

sub recurse {
  my $self = shift;
  my %opts = (
    preorder => 1,
    depthfirst => 0,
    prune => 1,
    (@_ == 1 && ref $_[0] eq ref sub {}) ? (callback => $_[0]) : @_
  );
  my $callback = $opts{callback}
    or Carp::croak "Must provide a 'callback' parameter to recurse()";
  my @queue = ($self);

  my $visit_entry;
  my $visit_dir =
    $opts{depthfirst} && $opts{preorder}
    ? sub {
      my $dir = shift;
      $callback->($dir);
      unshift @queue, $dir->children( prune => $opts{prune} );
    }
    : $opts{preorder}
    ? sub {
      my $dir = shift;
      $callback->($dir);
      push @queue, $dir->children( prune => $opts{prune} );
    }
    : sub {
      my $dir = shift;
      $visit_entry->($_) for $dir->children( prune => $opts{prune} );
      $callback->($dir);
    };

  $visit_entry = sub {
    my $entry = shift;
    if ($entry->is_dir) { $visit_dir->($entry) }
    else { $callback->($entry) }
  };

  while (@queue) {
    $visit_entry->( shift @queue );
  }
}
sub volume { $_[0]->[0]->volume }
sub subsumes {
  my ($self, $other) = @_;
  $self->[0]->subsumes($other);
}

sub contains {
  my ($self, $other) = @_;
  return !!(-d $self and (-e $other or -l $other) and $self->subsumes($other));
}

sub _opts { @_ == 1 && ref $_[0] eq ref {} ? $_[0] : {@_} }

sub AUTOLOAD {
  return if $AUTOLOAD =~ /::DESTROY$/;
  $AUTOLOAD =~ s/.*:://;
  $AUTOLOAD =~ s/_pt$//;
  my $self = shift;
  if (ref $self) { $self->[0]->$AUTOLOAD(@_); }
  else { Path::Tiny->$AUTOLOAD(@_) }
}

1;

__END__

=encoding utf-8

=head1 NAME

Path::Extended::Tiny - a Path::Tiny wrapper for Path::Extended compatibility

=head1 SYNOPSIS

    use Path::Extended::Tiny;

    # These objects have the (almost) same methods as Path::Extended
    # but use Path::Tiny internally.
    my $file = file('path/to/file.txt');
    my $dir  = dir('path/to/somewhere');

    # These objects autoload Path::Tiny methods as well.
    $file->spew('write something to the path');
    $dir->remove_tree;

    # As for conflicting methods, append _pt to use Path::Tiny ones.
    $file->slurp_pt;

=head1 DESCRIPTION

This module reimplements important interfaces of L<Path::Extended>
with L<Path::Tiny> to help migration. If you have some utilities
that have used L<Path::Extended> and exposed its objects to other
modules/applications, this would help you and your users.

If you write something new, just use L<Path::Tiny>.

=head1 METHODS

See L<Path::Extended> and L<Path::Tiny> for details.

=head1 NOTABLE INCOMPATIBLE METHODS

The following methods have incompatibility between Path::Extended
and Path::Tiny. For easier migration, you might want to replace
them with the ones with _pt suffix step by step. When everything
is ready, replace Path::Extended::Tiny with Path::Tiny and
remove _pt.

=over 4

=item absolute

=item basename

=item children

=item parent

=item remove

=item slurp

=back

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kenichi Ishigaki.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
