package Sys::Export::Unix::WriteFS;

# ABSTRACT: An export target that writes files to a directory in the host filesystem
our $VERSION = '0.002'; # VERSION


use v5.26;
use warnings;
use experimental qw( signatures );
use Carp qw( croak carp );
our @CARP_NOT= qw( Sys::Export::Unix );
use Cwd qw( abs_path );
use Sys::Export qw( :stat_modes :stat_tests isa_hash );
require Sys::Export::Unix;

sub new {
   my $class= shift;
   my %attrs= @_ == 1 && isa_hash $_[0]? %{$_[0]}
      : !(@_ & 1)? @_
      : croak "Expected hashref or even-length list";

   defined $attrs{dst} or croak "Require 'dst' attribute";
   my $dst_abs= abs_path($attrs{dst} =~ s,(?<=[^/])$,/,r)
      or croak "dst directory '$attrs{dst}' does not exist";
   length $dst_abs > 1
      or croak "cowardly refusing to export to '$dst_abs'";
   $attrs{dst_abs}= "$dst_abs/";

   $attrs{tmp} //= do {
      my $tmp= File::Temp->newdir;
      # Make sure can rename() from this $tmp to $dst
      my ($tmp_dev)= stat "$tmp/";
      my ($dst_dev)= stat $attrs{dst};
      $tmp= File::Temp->newdir(DIR => $attrs{dst_abs})
         if $tmp_dev != $dst_dev;
      $tmp;
   };

   my $self= bless \%attrs, $class;

   return $self;
}


sub dst($self)          { $self->{dst} }
sub dst_abs($self)      { $self->{dst_abs} }
sub tmp($self)          { $self->{tmp} }
sub on_collision($self) { $self->{on_collision} }

# a hashref tracking files with link-count higher than 1, so that hardlinks can be preserved.
# the keys are "$dev:$ino"
sub _link_map($self) { $self->{link_map} //= {} }

sub DESTROY($self, @) {
   $self->finish if $self->{_delayed_apply_stat};
}


sub add($self, $file) {
   croak "Path must start with a name, not slash or dot: '$file->{name}'"
      if $file->{name} =~ m{(^|^\.|^\.\.)(/|\z)};
   my $mode= $file->{mode} // croak "attribute 'mode' is required, for '$file->{name}'";
   # Does it already exist?
   my $dst_abs= $self->dst_abs . $file->{name};
   my %old;
   if (@old{qw( dev ino mode nlink uid gid rdev size atime mtime)}= lstat($dst_abs)) {
      # If the user says to ignore it, nothing to do:
      my $action= $self->on_collision // 'ignore_if_same';
      $action= $action->($dst_abs, $file)
         if ref $action eq 'CODE';
      return !!0 if $action eq 'ignore';
      return !!0 if $action eq 'ignore_if_same' && $self->_croak_if_different($file, \%old);
      croak "Unknown on_collision action '$action'" unless $action eq 'overwrite';
      # overwrite, but directory might not be empty, so handle that later
      unlink $dst_abs unless S_ISDIR($old{mode});
   }
   return S_ISREG($mode)? $self->_add_file($file)
        : S_ISDIR($mode)? $self->_add_dir($file, (defined $old{mode}? \%old : undef))
        : S_ISLNK($mode)? $self->_add_symlink($file)
        : (S_ISBLK($mode) || S_ISCHR($mode))? $self->_add_devnode($file)
        : S_ISFIFO($mode)? $self->_add_fifo($file)
        : S_ISSOCK($mode)? $self->_add_socket($file)
        : croak "Can't export ".(S_ISWHT($mode)? 'whiteout entries' : '(unknown)')
            .': "'.($file->{src_path} // $file->{data_path} // $file->{name}).'"'
}

our %_mode_name= (
   S_IFREG  , 'file', 
   S_IFDIR  , 'dir',
   S_IFLNK  , 'symlink',
   S_IFBLK  , 'block device',
   S_IFCHR  , 'char device',
   S_IFIFO  , 'fifo',
   S_IFSOCK , 'socket',
   (S_IFWHT? (
   S_IFWHT  , 'whiteout',
   ):()),
);
sub _mode_name($mode) { $_mode_name{($mode & S_IFMT)} // '(unknown)' }

# Compare two dirents and croak if new is not equivalent to old
sub _croak_if_different($self, $file, $old) {
   my $dst_abs= $self->dst_abs . $file->{name};
   croak "Attempt to write "._mode_name($file->{mode})." overtop existing "._mode_name($old->{mode})." at $dst_abs"
      if ($file->{mode} & S_IFMT) != ($old->{mode} & S_IFMT);
   croak "Attempt to write ownership $file->{uid}:$file->{gid} to $dst_abs which was previously $old->{uid}:$old->{gid}"
      if (defined $file->{uid} && $file->{uid} != $old->{uid}) || (defined $file->{gid} && $file->{gid} != $old->{gid});
   # For symlinks, compare only the content of the link.  Permissions are ignored.
   if (S_ISLNK($file->{mode})) {
      my $targ= readlink $dst_abs;
      croak "Attempt to rewrite symlink $dst_abs from $targ to $file->{data}"
         if $targ ne $file->{data};
      return !!0;
   }
   # For everything else, compare permissions
   croak "Attempt to write permissions ".($file->{mode} & ~S_IFMT)." overtop existing ".($old->{mode} & ~S_IFMT)." at $dst_abs"
      unless $file->{mode} == $old->{mode};

   if (S_ISREG($file->{mode})) {
      # compare file contents
      croak "Attempt to overwrite $dst_abs with different content"
         if (defined $file->{size} && $file->{size} != $old->{size})
            || !_contents_same($file, $dst_abs);
   }
   elsif (S_ISBLK($file->{mode}) || S_ISCHR($file->{mode})) {
      # compare major/minor numbers
      croak "Attempt to overwrite $dst_abs with different major/minor value"
         if $file->{rdev} != $old->{rdev};
   }
   1;
}

# Compare file contents for equality
sub _contents_same($file, $dst_abs) {
   Sys::Export::Unix::_load_or_map_file($file->{data}, $file->{data_path})
      unless defined $file->{data};
   Sys::Export::Unix::_load_or_map_file(my $dst_data, $dst_abs);
   return $file->{data} eq $dst_data;
}

# compare device nodes for equality
sub _rdev_same($file, $old) {
   # old will always have 'rdev' defined because we ran lstat.
   # file might not if the user specified rdev_major and rdev_minor
   if (defined $file->{rdev}) {
      return $file->{rdev} == $old->{rdev};
   } elsif (defined $file->{rdev_major} && defined $file->{rdev_minor}) {
      my ($maj, $min)= Sys::Export::Unix::_dev_major_minor($old->{rdev});
      return $file->{rdev_major} == $maj && $file->{rdev_minor} == $min;
   } else {
      return !!0; # not defined, so can't be same
   }
}

# Install a file into ->dst
sub _add_file($self, $file) {
   my $dst= $self->dst_abs . $file->{name};
   my $tmp= $file->{data_path};
   # See if this is supposed to be a hardlink
   if ($file->{nlink} > 1) {
      if (defined(my $already= $self->_link_map->{"$file->{dev}:$file->{ino}"})) {
         # Yep, make a link of that file instead of copying again
         link($already, $dst)
            or croak "link($already, $dst): $!";
         return !!1;
      }
   }
   # Record all file inodes in case a delayed hardlink is created by the caller
   $self->_link_map->{"$file->{dev}:$file->{ino}"}= $dst;
   # The caller may have created data_path within our ->tmp directory.
   # If not, first write the data into a temp file there.
   if (!defined $tmp || substr($tmp, 0, length $self->tmp) ne $self->tmp) {
      if (!defined $file->{data}) {
         defined $file->{data_path}
            or croak "No 'data' or 'data_path' for file $file->{name}";
         Sys::Export::Unix::_load_or_map_file($file->{data}, $file->{data_path});
      }
      $tmp= File::Temp->new(DIR => $self->tmp, UNLINK => 0);
      Sys::Export::Unix::_syswrite_all($tmp, \$file->{data});
   }
   # Apply matching permissions and ownership
   $self->_apply_stat("$tmp", $file);
   # Rename the temp file into place
   rename($tmp, $dst) or croak "rename($tmp, $dst): $!";
}

# Install a dir into ->dst, unless it already exists
sub _add_dir($self, $dir, $old) {
   my $dst_abs= $self->dst_abs . $dir->{name};
   # If the directory already exists, just apply the permissions
   mkdir($dst_abs) || croak "mkdir($dst_abs): $!"
      unless $old;
   $self->_apply_stat($dst_abs, $dir);
}

# Install a symlink into ->dst
sub _add_symlink($self, $file) {
   my $dst_abs= $self->dst_abs . $file->{name};
   length $file->{data}
      or croak "Missing symlink contents for $file->{name}";
   symlink($file->{data}, $dst_abs)
      or croak "symlink($file->{data}, $dst_abs): $!";
   $self->_apply_stat($dst_abs, $file);
}

# Install a device node into ->dst
sub _add_devnode($self, $file) {
   if (defined $file->{rdev} && (!defined $file->{rdev_major} || !defined $file->{rdev_minor})) {
      my ($major,$minor)= Sys::Export::Unix::_dev_major_minor($file->{rdev});
      $file->{rdev_major} //= $major;
      $file->{rdev_minor} //= $minor;
   }
   my $dst_abs= $self->dst_abs . $file->{name};
   Sys::Export::Unix::_mknod_or_die($dst_abs, $file->{mode}, $file->{rdev_major}, $file->{rdev_minor});
   $self->_apply_stat($dst_abs, $file);
}

# Install a fifo into ->dst
sub _add_fifo($self, $file) {
   require POSIX;
   my $dst_abs= $self->dst_abs . $file->{name};
   POSIX::mkfifo($dst_abs, $file->{mode})
      or croak "mkfifo($dst_abs): $!";
   $self->_apply_stat($dst_abs, $file);
}

# Bind a socket (thus creating it) in ->dst
sub _add_socket($self, $file) {
   require Socket;
   my $dst_abs= $self->dst_abs . $file->{name};
   socket(my $s, Socket::AF_UNIX(), Socket::SOCK_STREAM(), 0) or die "socket: $!";
   bind($s, Socket::pack_sockaddr_un($dst_abs)) or die "Failed to bind socket at $dst_abs: $!";
   $self->_apply_stat($dst_abs, $file);
}


sub finish($self) {
   my $todo= delete $self->{_delayed_apply_stat};
   # Reverse sort causes child directories to be updated before parents,
   # which is required for updating mtimes.
   $self->_delayed_apply_stat(@$_)
      for sort { $b->[0] cmp $a->[0] } @$todo;
   # free the temp directory if it was located within /dst_abs
   undef $self->{tmp};
}

# Apply permissions and mtime to a path
sub _apply_stat($self, $abs_path, $stat) {
   my ($mode, $uid, $gid, $atime, $mtime)= (lstat $abs_path)[2,4,5,8,9]
      or croak "Failed to stat file just created at '$abs_path': $!";
   my $change_uid= defined $stat->{uid} && $stat->{uid} != $uid;
   my $change_gid= defined $stat->{gid} && $stat->{gid} != $gid;
   if ($change_uid || $change_gid) {
      # only UID 0 can change UID, and only GID 0 or GID in supplemental groups can change GID.
      $uid= -1 unless $change_uid && $> == 0;
      $gid= -1 unless $change_gid && ($) == 0 || grep $stat->{gid}, split / /, $) );
      # Only attempt change if able
      POSIX::lchown($uid, $gid, $abs_path) or croak "lchown($uid, $gid, $abs_path): $!"
         if $uid >= 0 || $gid >= 0;
   }

   my @delayed;

   # Don't change permission bits on symlinks
   if (!S_ISLNK($mode) && ($mode & 0xFFF) != ($stat->{mode} & 0xFFF)) {
      # If changing permissions on a directory to something that removes our ability
      # to write to it, delay this change until the end.
      if (S_ISDIR($mode) && !(($stat->{mode} & 0222) && ($stat->{mode} & 0111))) {
         push @delayed, 'chmod';
      }
      else {
         chmod $stat->{mode}&0xFFF, $abs_path
            or croak sprintf "chmod(0%o, %s): $!", $stat->{mode}&0xFFF, $abs_path;
      }
   }

   if (!S_ISLNK($mode) && (defined $stat->{mtime} || defined $stat->{atime})) {
      if (S_ISDIR($mode)) {
         # No point in applying mtime to a directory now, because it will get
         # changed when sub-entries get written.
         push @delayed, 'utime';
      }
      else {
         utime $stat->{atime}, $stat->{mtime}, $abs_path
            or warn "utime($abs_path): $!";
      }
   }

   push @{$self->{_delayed_apply_stat}}, [ $abs_path, $stat, @delayed ]
      if @delayed;
}
sub _delayed_apply_stat($self, $abs_path, $stat, @delayed) {
   if (grep $_ eq 'chmod', @delayed) {
      chmod $stat->{mode}&0xFFF, $abs_path
         or croak sprintf "chmod(0%o, %s): $!", $stat->{mode}&0xFFF, $abs_path;
   }
   if (grep $_ eq 'utime', @delayed) {
      utime $stat->{atime}, $stat->{mtime}, $abs_path
         or warn "utime($abs_path): $!";
   }
}

# Avoiding dependency on namespace::clean
{  no strict 'refs';
   delete @{"Sys::Export::Unix::"}{qw(
      croak carp abs_path S_IFMT
      S_ISREG S_ISDIR S_ISLNK S_ISBLK S_ISCHR S_ISFIFO S_ISSOCK S_ISWHT 
      S_IFREG S_IFDIR S_IFLNK S_IFBLK S_IFCHR S_IFIFO  S_IFSOCK S_IFWHT
   )};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Export::Unix::WriteFS - An export target that writes files to a directory in the host filesystem

=head1 SYNOPSIS

This is used automatically when you specify a path string as the 'dst' parameter of the Unix
exporter.

  use Sys::Export::Unix;
  my $exporter= Sys::Export::Unix->new(
    src => '/', dst => '/initrd'
  );

=head1 DESCRIPTION

This module simply writes all exported files to the host's filesystem.  This is more-or-less
the default that people use when building system images, but the downside is that it reqrires
the build script to be run as root.  You can avoid this by using L<Sys::Export::CPIO> as an
export target, which is able to write directory entries directly to the cpio archive, skipping
any local filesystem writes.

Note that this module tracks device and inode in order to preserve hard-links, though only
entries with C<nlink> greater than 1 are considered.  To generate a hard link, specify a
distinct C<dev> and C<ino> combination (and nlink greater than 1) and then repeat those
parameters later in order to link to the previous file.

=head1 CONSTRUCTORS

=head2 new

  Sys::Export::Unix::WriteFS->new(\%attributes); # hashref
  Sys::Export::Unix::WriteFS->new(%attributes);  # key/value list

Required attributes:

=over

=item dst

The root of the exported system.  This directory must exist, and should be empty unless you
specify 'on_collision'.

=back

Options:

=over

=item tmp

A temporary directory in the same filesystem as L</dst> where this module can prepare temporary
files, then C<rename> them into place.  This prevents any partially-prepared files from ending
up in the destination tree.  If you specify this, it is your responsibility to clean it up,
such as by passing an instance of C<< File::Temp->newdir >>.

By default, this module uses the normaal File::Temp location, unless that path is not on the
same volume as the destination, in which case it will create a temp directory within C<$dst>.

=item on_collision

Specifies what to do if there is a name collision in the destination.  The default
'ignore_if_same' causes an exception unless the existing file is identical to the one that
would be written.

Setting this to 'overwrite' will unconditionally replace files as it runs.  Setting it to
'ignore' will silently ignore collisions and leave the existing file in place.
Setting it to a coderef will provide you with the path and content thata was about to be
written to it:

  on_collision => sub ($dst_abs, $fileinfo) {
    # dst_abs is the absolute path about to be written
    # fileinfo is the hash of file attributes passed to ->add
    # _ will be set to an lstat of $dst_abs
    return $action; # 'ignore' or 'overwrite' or 'ignore_if_same'
  }

=back

=head1 ATTRIBUTES

=head2 dst

The root of the destination filesystem.  This is the logical root of your destination
filesystem.  The directory must exist, cannot be the actual "/" root directory, and probably
ought to be empty to avoid collisions.

=head2 dst_abs

The C<abs_path> of the root of the destination filesystem, always ending with '/'.
This is only defined if L<dst> is B<not> a coderef.

=head2 tmp

The C<abs_path> of a directory to use for temporary staging before renaming into L</dst>.
This must be in the same volume as C<dst> so that C<rename()> can be used to move temporary
files into their C<dst> location.  A default will be chosen within C<< /dst_abs >> if that
isn't the same device as the natural.  It will be cleaned up automatically or when you call
L</finish>.

=head1 METHODS

=head2 add

  $exporter->add(\%file_attrs);

Add content to a destination path.  File attributes are:

  name            # destination path relative to destination root
  data            # literal data content of file (must be bytes, not unicode)
  data_path       # absolute path of file to load 'data' from
  dev             # device, from stat
  dev_major       # major(dev), if you know it and don't know 'dev'
  dev_minor       # minor(dev), if you know it and don't know 'dev'
  ino             # inode, from stat
  mode            # permissions and type, as per stat
  nlink           # number of hard links
  uid             # user id
  gid             # group id
  rdev            # referenced device, for device nodes
  rdev_major      # major(rdev), if you know it and don't know 'rdev'
  rdev_minor      # minor(rdev), if you know it and don't know 'rdev'
  size            # size, in bytes.  Can be ommitted if 'data' is present
  mtime           # modification time, as per stat

Returns a true value if the file/dirent was written to the filesystem, or false otherwise.
Errors writing to the filesystem will generate exceptions rather than a false return value, but
a false return may occur if you set C<< on_collision => 'ignore' >>.

=head2 finish

Apply any postponed changes to the destination filesystem.  For instance, this applies mtimes
to directories since writing the contents of the directory would have changed the mtime.

=head1 VERSION

version 0.002

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
