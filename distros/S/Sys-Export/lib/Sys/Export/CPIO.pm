package Sys::Export::CPIO;

# ABSTRACT: Write CPIO archives needed for Linux initrd
our $VERSION = '0.003'; # VERSION

use v5.26;
use warnings;
use experimental qw( signatures );
use Fcntl qw( S_IFDIR S_IFMT );
use Scalar::Util 'blessed';
use Carp;
our @CARP_NOT= qw( Sys::Export Sys::Export::Unix );
require Sys::Export::Unix; # for _dev_major_minor 


sub new($class, $f, @attrs) {
   croak "Expected even-length key/value list after filename" if @attrs & 1;
   my $filename;
   my $fh= blessed $f && $f->can('print')? $f
      : do { $filename= $f; open my $x, '>:raw', $f or die "open($f): $!"; $x };
   my $self= bless {
      fh => $fh,
      seen_inode => {},
      ino => 0,
      virtual_inodes => 1,
      filename => $filename,
      autoclose => defined $filename,
   }, $class;

   while (@attrs) {
      my ($attr, $val)= splice(@attrs, 0, 2);
      $self->$attr($val);
   }

   $self;
}


sub autoclose {
   $_[0]{autoclose}= !!$_[1] if @_ > 1; # cast to boolean
   $_[0]{autoclose}
}

sub filename {
   $_[0]{filename}= $_[1] if @_ > 1;
   $_[0]{filename}
}

sub virtual_inodes {
   $_[0]{virtual_inodes}= !!$_[1] if @_ > 1; # cast to boolean
   $_[0]{virtual_inodes}
}


sub add($self, $fileinfo) {
   my ($dev, $dev_major, $dev_minor, $ino, $mode, $nlink, $uid, $gid, $rdev, $rdev_major, $rdev_minor, $mtime, $name)
      = @{$fileinfo}{qw( dev dev_major dev_minor ino mode nlink uid gid rdev rdev_major rdev_minor mtime name )};
   # best-effort to extract major/minor from dev and rdev, unless user specified them
   ($dev_major, $dev_minor)= Sys::Export::Unix::_dev_major_minor($dev)
      if defined $dev and !defined $dev_major || !defined $dev_minor;
   ($rdev_major, $rdev_minor)= Sys::Export::Unix::_dev_major_minor($rdev)
      if defined $rdev and !defined $rdev_major || !defined $rdev_minor;
   defined $mode or croak "require 'mode'";
   defined $name or croak "require 'name'";

   my $size= length($fileinfo->{data}) // 0;
   # Handle hard links
   if ($nlink && $nlink > 1 && ($mode & S_IFMT) != S_IFDIR) {
      my $hardlink_key= "$dev_major:$dev_minor:$ino";
      if ($self->virtual_inodes) {
         # the previous virtual inode is stored in the seen_inode hash
         if ($ino= $self->{seen_inode}{$hardlink_key}) {
            $size= 0;
         } else {
            $ino= $self->{seen_inode}{$hardlink_key}= ++$self->{ino};
         }
         ($dev_major, $dev_minor)= (0,0);
      }
      else {
         $size= 0 if $self->{seen_inode}{$hardlink_key}++;
      }
   }
   elsif ($self->virtual_inodes) {
      ($dev_major, $dev_minor, $ino)= (0,0);
   }
   $ino //= ++$self->{ino};

   my $header= sprintf "070701%08X%08X%08X%08X%08X%08X%08X%08X%08X%08X%08X%08X%08X%s\0%s",
      $ino, $mode, $uid//0, $gid//0, $nlink//1, $mtime//0, $size,
      $dev_major//0, $dev_minor//0, $rdev_major//0, $rdev_minor//0,
      1+length $name, 0, $name,
      "\0"x((4 - ((13*8+6+length($name)+1) & 3)) & 3); # pad to multiple of 4
   die "BUG" if length $header & 3;

   $self->{fh}->print($header) || die "write: $!";
   # This is written in multiple parts like this because $fileinfo->{data} might be a File::Map,
   #  and optimal to pass that directly back to fprint without a perl-side concatenation.
   $self->{fh}->print($fileinfo->{data}) || die "write: $!"
      if $size;
   $self->{fh}->print("\0"x(4-($size & 3))) || die "write: $!"
      if $size & 3; # pad to multiple of 4
   $self;
}


sub finish($self) {
   $self->add({ mode => 0, ino => 0, name => 'TRAILER!!!' });
   $self->{fh}->flush;
   $self->{fh}->close if $self->autoclose;
   $self;
}

# Avoiding dependency on namespace::clean
{  no strict 'refs';
   delete @{"Sys::Export::CPIO::"}{qw(
      S_IFDIR S_IFMT blessed carp croak
   )}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Export::CPIO - Write CPIO archives needed for Linux initrd

=head1 SYNOPSIS

  my $cpio= Sys::Export::CPIO->new($file_name_or_handle, %attrs);
  $cpio->add(\%stat_name_and_data);
  $cpio->add(\%stat_name_and_data);
  $cpio->add(\%stat_name_and_data);
  ...
  $cpio->finish;  # write trailer entry and flush/close file.
                  # file is *not* closed automatically if you passed
                  # an open handle to the constructor.

=head1 DESCRIPTION

This module writes out the cpio "New ASCII Format", as required by Linux initrd.  It does very
little aside from packing the data, but has support for:

=over

=item hardlinks

If you add a file with C<< nlink > 1 >>, it will note the dev/ino and write the data.
If you record a second file also having C<< nlink > 1 >> with the same dev/ino, the size will
be written as zero and the data will be skipped. (this is the way cpio stores hardlinks)

=item rdev

You can pass the C<rdev> received from C<stat>, and this module makes a best-effort to break
that down into the major/minor numbers needed for cpio, but perl doesn't have access to the real
major/minor functions of your platform unless you install L<Unix::Mknod>.  If you were trying
to creaate a device node from pure configuration rather than the filesystem, just pass
C<rdev_major> and C<rdev_minor> instead of C<rdev>.

=item virtual_inodes

Since the original device and inode are not relevant to the initrd loading, this module can
replace the device with 0 and the inode with an incrementing sequence, which should compress
better.

Pass C<< (virtual_inodes => 0) >> to the constructor to disable this feature.

=back

=head1 CONSTRUCTORS

=head2 new

  my $cpio= Sys::Export::CPIO->new($fh_or_filename, %attrs);

The first argument is either a file handle object implementing 'print', or a file name.
If it is a file name, it is immediately opened in 'raw' mode and dies on failure.

The rest of the arguments can be used to initialize attributes.

=head1 ATTRIBUTES

=head2 autoclose

If true, calling L</finish> will close the file handle.  This is enabled by default if you
passed a filename to the constructor.

=head2 filename

Just informational for debugging.  Will be undef if you passed a file handle rather than a file
name to the constructor.

=head2 virtual_inodes

This is enabled by default, and rewrites the device_major/device_minor with zeroes and generates
a linear sequence for a virtual inode on each file.

=head1 METHODS

=head2 add

  $cpio->add({
    dev   => # or, ( dev_major =>, dev_minor => )
    ino   => # 
    mode  => #
    nlink => # same as stat() 
    uid   => # 
    gid   => # 
    mtime => #
    rdev  => # or, ( rdev_major =>, rdev_minor => )
    name  => # full path name, no leading '/'
    data  => # full content of file or symlink
  });

This simply packs the file metadata into a CPIO header, then writes the header, filename, and
data to the stream, padding as necessary.

=head2 finish

Writes end-of-file signature, and closes the handle if L</autoclose> is true.

=head1 VERSION

version 0.003

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
