package Sys::Export;

our $VERSION = '0.006'; # VERSION
# ABSTRACT: Export a subset of an OS file tree, for chroot/initrd

use v5.26;
use warnings;
use experimental qw( signatures );
use Carp;
use Scalar::Util qw( blessed looks_like_number );
use Sys::Export::LogAny '$log';
use Exporter ();
use Fcntl ':mode';
BEGIN {
   # Fcntl happily exports macros that don't exist, then fails at runtime.
   # Replace non-existent test macros with 'false', and nonexistent modes with 0.
   # But, on MSWin32, the constant for S_IFLNK is 0x4000 and just isn't defined in Fcntl
   # because the headers don't define it.
   for (qw( S_ISREG S_ISDIR S_ISLNK S_ISBLK S_ISCHR S_ISFIFO S_ISSOCK S_ISWHT
            S_IFREG S_IFDIR S_IFLNK S_IFBLK S_IFCHR S_IFIFO  S_IFSOCK S_IFWHT S_IFMT )
   ) {
      next if eval { __PACKAGE__->can($_)->($_ =~ /_IS/? (0) : ()); 1 };
      delete ${Sys::Export::}{$_};
      if ($^O eq 'MSWin32' && $_ eq 'S_IFLNK') {
         eval 'sub Sys::Export::S_IFLNK { 0x6000 } 1' or die "S_IFLNK $@";
      } elsif ($^O eq 'MSWin32' && $_ eq 'S_ISLNK') {
         eval 'sub Sys::Export::S_ISLNK { S_IFMT($_[0]) == 0x6000 } 1' or die "S_ISLNK $@";
      } else {
         eval "sub Sys::Export::$_ { 0 } 1" or die "$@";
      }
   }
}
our @EXPORT_OK= qw(
   isa_exporter isa_export_dst isa_userdb isa_user isa_group exporter isa_hash isa_array isa_int
   isa_handle isa_pow2 isa_data_ref round_up_to_pow2 round_up_to_multiple map_or_load_file filedata
   add skip find which finish rewrite_path rewrite_user rewrite_group expand_stat_shorthand
   write_file_extent _pack _unpack
   S_ISREG S_ISDIR S_ISLNK S_ISBLK S_ISCHR S_ISFIFO S_ISSOCK S_ISWHT
   S_IFREG S_IFDIR S_IFLNK S_IFBLK S_IFCHR S_IFIFO  S_IFSOCK S_IFWHT S_IFMT
);
our %EXPORT_TAGS= (
   basic_methods => [qw( exporter add skip find which finish rewrite_path rewrite_user rewrite_group filedata )],
   isa => [qw( isa_exporter isa_export_dst isa_userdb isa_user isa_group isa_hash isa_array isa_handle isa_int isa_pow2 isa_data_ref )],
   stat_modes => [qw( S_IFREG S_IFDIR S_IFLNK S_IFBLK S_IFCHR S_IFIFO  S_IFSOCK S_IFWHT S_IFMT )],
   stat_tests => [qw( S_ISREG S_ISDIR S_ISLNK S_ISBLK S_ISCHR S_ISFIFO S_ISSOCK S_ISWHT )],
);
my ($is_module_name, $require_module);

# optional dependency on Module::Runtime.  This way if there's any bug in my cheap
# substitute, the fix is to just install the official module.
if (eval { require Module::Runtime; }) {
   $is_module_name= \&Module::Runtime::is_module_name;
   $require_module= \&Module::Runtime::require_module;
} else {
   $is_module_name= sub { $_[0] =~ /^[A-Z_a-z][0-9A-Z_a-z]*(?:::[0-9A-Z_a-z]+)*\z/ };
   $require_module= sub { require( ($_[0] =~ s{::}{/}gr).'.pm' ) };
}


sub import {
   my $class= $_[0];
   my $caller= caller;
   my %ctor_opts;
   for (my $i= 1; $i < $#_; ++$i) {
      if (ref $_[$i] eq 'HASH') {
         %ctor_opts= ( %ctor_opts, %{ splice(@_, $i--, 1) } );
      }
      elsif ($_[$i] =~ /^-(type|src|dst|tmp|src_userdb|dst_userdb|rewrite_path|rewrite_user|rewrite_group)\z/) {
         $ctor_opts{$1}= (splice @_, $i--, 2)[1];
      }
   }
   if (keys %ctor_opts) {
      init_global_exporter(%ctor_opts);
      # caller requested the global exporter instance, so also include the standard methods
      # unless it looks like they were more selective about what to import.
      push @_, 'exporter', ':basic_methods'
         unless grep /^(add|:.*methods)\z/, @_;
   }
   goto \&Exporter::import;
}

our $exporter;
sub exporter { $exporter }

our %osname_to_class= (
   linux => 'Linux',
);

sub init_global_exporter(%config) {
   my $type= delete $config{type} // $^O;
   # remap known OS names
   my $class= $osname_to_class{$type} // $type;
   # prefix bare names with namespace
   $class= "Sys::Export::$class" unless $class =~ /::/;
   $is_module_name->($class) or croak "Invalid module name '$class'";
   # if it fails, die with 'croak'
   eval { $require_module->($class) } or croak "$@";
   # now construct one
   $exporter= $class->new(%config);
}


sub add           { $exporter->add(@_) }
sub skip          { $exporter->skip(@_) }
sub find          { $exporter->src_find(@_) }
sub which :prototype($) { $exporter->src_which(@_) }
sub finish        { $exporter->finish(@_) }
sub rewrite_path  { $exporter->rewrite_path(@_) }
sub rewrite_user  { $exporter->rewrite_user(@_) }
sub rewrite_group { $exporter->rewrite_group(@_) }


sub isa_hash       :prototype($) { ref $_[0] eq 'HASH' }
sub isa_array      :prototype($) { ref $_[0] eq 'ARRAY' }
sub isa_handle     :prototype($) { ref $_[0] eq 'GLOB' || (ref $_[0] && (ref $_[0])->isa('IO::Handle')) }
sub isa_int        :prototype($) { looks_like_number($_[0]) && int($_[0]) == $_[0] }
sub isa_exporter   :prototype($) { blessed($_[0]) && $_[0]->isa('Sys::Export::Exporter') }
sub isa_export_dst :prototype($) { blessed($_[0]) && $_[0]->can('add') && $_[0]->can('finish') }
sub isa_userdb     :prototype($) { blessed($_[0]) && $_[0]->can('user') && $_[0]->can('group') }
sub isa_user       :prototype($) { blessed($_[0]) && $_[0]->isa('Sys::Export::Unix::UserDB::User') }
sub isa_group      :prototype($) { blessed($_[0]) && $_[0]->isa('Sys::Export::Unix::UserDB::Group') }
sub isa_pow2       :prototype($) { !($_[0] & ($_[0]-1)) }
sub isa_data_ref   :prototype($) { ref $_[0] eq 'SCALAR' || blessed($_[0]) && $_[0]->can('as_scalarref') }


sub _parse_major_minor_data($attrs, $data) {
   @{$attrs}{'rdev_major','rdev_minor'}= isa_array $data? @$data : split(/[,:]/, $data);
}
our %_mode_alias= (
   file => [ S_IFREG,  sub { 0666 & ~umask } ],
   dir  => [ S_IFDIR,  sub { 0777 & ~umask } ],
   sym  => [ S_IFLNK,  sub { 0777 } ],
   blk  => [ S_IFBLK,  sub { 0666 & ~umask }, \&_parse_major_minor_data, ],
   chr  => [ S_IFCHR,  sub { 0666 & ~umask }, \&_parse_major_minor_data, ],
   fifo => [ S_IFIFO,  sub { 0666 & ~umask } ],
   sock => [ S_IFSOCK, sub { 0666 & ~umask } ],
);
our @_mode_by_int;
$_mode_by_int[$_->[0]]= $_ for values %_mode_alias;
$_mode_by_int[0]= undef; # don't map 0 to any mode

sub expand_stat_shorthand {
   @_= @{$_[0]} if @_ == 1 && isa_array $_[0];
   my %attrs= @_ > 2 && isa_hash $_[-1]? %{ pop @_ } : ();
   my ($mode, $name, $data)= @_;
   my $mode_desc;
   if (isa_int $mode) {
      $mode_desc= $_mode_by_int[$mode & S_IFMT]
         or carp sprintf("Numeric mode %x doesn't match any known node types", $mode);
   }
   else {
      $mode =~ /^([a-z]+)([0-7]+)?\z/
         or croak "Invalid mode '$mode': expected number, or prefix file/dir/sym/blk/chr/fifo/sock followed by octal permissions";
      $mode_desc= $_mode_alias{$1}
         or croak "Unknown mode alias '$1'";
      $mode= $mode_desc->[0] | (defined $2? oct($2) : $mode_desc->[1]->());
   }
   $attrs{mode}= $mode;
   length $name or croak "Name must be nonzero length";
   $attrs{name}= $name;
   if (defined $data) {
      if ($mode_desc && $mode_desc->[2]) {
         $mode_desc->[2]->(\%attrs, $data);
      } else {
         $attrs{data}= $data;
      }
   }
   return %attrs;
}


sub round_up_to_pow2($n) {
   croak "Not defined for negative numbers" unless $n > 0;
   return 1 if $n <= 1;
   --$n;
   $n |= $n >> 1;
   $n |= $n >> 2;
   $n |= $n >> 4;
   $n |= $n >> 8;
   $n |= $n >> 16;
   $n |= $n >> 32;
   return $n+1;
}

sub round_up_to_multiple($n, $pow2) {
   croak "Not defined for negative numbers" unless $n > 0;
   my $mask= $pow2-1;
   return ($n + $mask) & ~$mask;
}


if (eval { require File::Map; }) {
   eval q{
      sub map_or_load_file($filename, $offset=0, $length=undef) {
         my $buf;
         defined $length? File::Map::map_file($buf, $filename, "<", $offset, $length)
            : File::Map::map_file($buf, $filename, "<", $offset, $length);
         return \$buf;
      }
      1;
   } or die "$@";
} else {
   *map_or_load_file= *_load_file;
}

sub _load_file($filename, $offset= 0, $length= undef) {
   open my $fh, "<:raw", $filename
      or die "open($filename): $!";
   my $size= -s $fh;
   croak "Offset beyond end of file ($filename, $offset > $size)" if $offset > $size;
   $length //= $size - $offset;
   my $buf= '';
   if ($length) {
      if ($offset > 0) {
         sysseek($fh, $offset, 0) == $offset
            or croak "sysseek($filename, $offset): $!";
      }
      sysread($fh, $buf, $length) == $size
         or die "sysread($filename, $size): $!";
   }
   \$buf;
}


sub filedata {
   state $loaded= require Sys::Export::LazyFileData;
   Sys::Export::LazyFileData->new(@_);
}


sub write_file_extent($fh, $addr, $size, $data_ref, $ofs=0, $descrip=undef) {
   $log->tracef("write %s at 0x%X-0x%X from buf size 0x%X%s",
      $descrip//'blocks', $addr, $addr+$size, length($$data_ref), $ofs? sprintf(" ofs 0x%X", $ofs) : ''
      ) if $log->is_trace;
   return unless $size > 0;
   if (defined $addr) {
      my $reached= sysseek($fh, $addr, 0) // croak "sysseek($addr): $!";
      $reached == $addr or croak "sysseek($addr) arrived at $reached instead of $addr";
   }
   $ofs //= 0;
   my $avail= $data_ref? (length($$data_ref) - $ofs) : 0;
   my $second;
   # always write full size, padding with zeroes
   if ($avail < $size) {
      # If the scalar is particularly large, do two writes instead of reallocating the buffer.
      if ($avail > 0x100000) {
         my $first_write= $avail - ($avail & 0xFFF);
         $second= pack 'a'.($size-$first_write), substr($$data_ref, $first_write);
         $size= $first_write;
      } else {
         my $data= pack 'a'.$size, ($avail > 0? substr($$data_ref, $ofs) : '');
         $data_ref= \$data;
         $ofs= 0;
      }
   }
   my $wrote= syswrite($fh, $$data_ref, $size, $ofs);
   croak "syswrite: $!" if !defined $wrote;
   croak "Unexpected short write ($wrote != $size)" if $wrote != $size;
   if (length $second) {
      $wrote= syswrite($fh, $second);
      croak "syswrite: $!" if !defined $wrote;
      croak "Unexpected short write ($wrote != $size)" if $wrote != length($second);
   }
   return 1;
}

if (eval { pack('Q<', 1) }) {
   *_pack= \*CORE::pack;
   *_unpack= \*CORE::unpack;
} else {
   eval <<'END';
   # On perl without 64-bit support, replace all 'Q' with 32-bit operations
   # This does not handle full pack syntax, just what is used in this module collection.
   sub _pack {
      my $fmt= shift;
      my $new_fmt= '';
      my @new_args;
      require Math::BigInt;
      my $mask32= Math::BigInt->new('4294967295');
      for (split / +/, $fmt) {
         if ($_ eq 'Q>') {
            # Convert a 64-bit integer into two 32-bit big-endian arguments
            $new_fmt .= 'NN';
            my $qw= Math::BigInt->new(shift);
            push @new_args, ($qw >> 32)->numify(), ($qw & $mask32)->numify();
         } elsif ($_ eq 'Q<') {
            # Convert 64-bit integer into two 32-bit little-endian arguments
            $new_fmt .= 'VV';
            my $qw= Math::BigInt->new(shift);
            push @new_args, ($qw & $mask32)->numify(), ($qw >> 32)->numify();
         } else {
            $new_fmt .= $_;
            push @new_args, shift;
         }
      }
      return pack $new_fmt, @new_args;
   }
   # This does not handle full unpack syntax, just what is used in this module collection.
   sub _unpack {
      my $fmt= shift;
      my $new_fmt= '';
      my @replacements;
      require Math::BigInt;
      my @fields= split / +/, $fmt;
      for (reverse 0 .. $#fields) {
         if ($fields[$_] eq 'Q>') {
            $new_fmt .= 'a8';
            push @replacements, [ $_, sub {
               my ($h,$l)= unpack('NN', $_[0]);
               (Math::BigInt->new($h) << 32) | $l
            }];
         } elsif ($fields[$_] eq 'Q<') {
            $new_fmt .= 'a8';
            push @replacements, [ $_, sub {
               my ($l, $h)= unpack('VV', $_[0]);
               (Math::BigInt->new($h) << 32) | $l
            }];
         }
      }
      my @vals= unpack $new_fmt;
      for (@replacements) {
         $vals[$_->[0]]= $_->[1]->($vals[$_->[0]]);
      }
      return @vals;
   }
END
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Export - Export a subset of an OS file tree, for chroot/initrd

=head1 SYNOPSIS

  use Sys::Export -src => '/', -dst => [ CPIO => "initrd.cpio" ];
  
  rewrite_path '/sbin'     => '/bin';
  rewrite_path '/usr/sbin' => '/bin';
  rewrite_path '/usr/bin'  => '/bin';
  
  # Add files and their dependencies
  add '/bin/busybox';
  add qw( bin/sh bin/date bin/cat bin/mount );
  
  # tell 'add' to ignore specific files
  skip 'usr/share/zoneinfo/tzdata.zi';
  
  # recurse and filter directories with 'find'
  add find 'usr/share/zoneinfo', sub { ! /(leapseconds|\.tab|\.list)$/ };
  
  # Inject dynamically generated files
  add [ file400 => "/etc/some-service.conf", <<~END ];
      # Some config file
      secret = $secret
      END
  
  # Inject files that come from a different name, or outside the 'src' tree
  add [ file644 => "/opt/some-app/data", filedata("/path/to/some/data") ];
  
  # For Linux, generate minimal /etc/passwd /etc/group /etc/shadow according
  # to UID/GID which were exported so far.
  exporter->add_passwd;
  
  finish;

=head1 DESCRIPTION

This module is designed to export a subset of an operating system to a new directory,
automatically detecting and including any libraries or interpreters required by the requested
subset, and optionally rewriting paths and users/groups and updating the copied files to refer
to the rewritten paths, when possible.

The actual export implementation is handled by a OS-specific module, like L<Sys::Export::Linux>.
This top-level module just exports methods.  You can configure a global exporter instance on
the C<use> line, and then call its methods via exported functions.  For instance,

  use Sys::Export \%options;

is roughly equivalent to:

  BEGIN {
    if ($^O eq 'linux') {
      require Sys::Export::Linux;
      $Sys::Export::exporter= Sys::Export::Linux->new(\%options);
    } else {
      ...
    }
    sub exporter      { $Sys::Export::exporter }
    sub add           { $Sys::Export::exporter->add(@_) }
    sub rewrite_path  { $Sys::Export::exporter->rewrite_path(@_) }
    sub rewrite_user  { $Sys::Export::exporter->rewrite_user(@_) }
    sub rewrite_group { $Sys::Export::exporter->rewrite_group(@_) }
    sub finish        { $Sys::Export::exporter->finish }
  }

In other words, just a convenience for creating an exporter instance and giving you access to
most of its important methods without needing to reference the object.  You can skip this
module entirely and just directly use a C<Sys::Export::Linux> object, if you prefer.

Currently, only Linux is fully supported.

=head1 CONFIGURATION

The following can be passed on the C<use> line to configure a global exporter object:

=over

=item A Hashref

  use Sys::Export { ... };

The keys of the hashref will be passed to the exporter constructor (aside from the key
C<'type'> which is used to override the default class)

=item -type

Specify a class of exporter, like C<'Linux'> or C<'Sys::Export::Linux'>.  Names without colons
imply a prefix of C<Sys::Export::>.

=item -src

Source directory; see L<Sys::Export::Unix/src>.

=item -dst

Destination directory or CPIO instance; see L<Sys::Export::Unix/dst>.

=item -src_userdb

Defines UID/GID of source filesystem; see L<Sys::Export::Unix/src_userdb>.

=item -dst_userdb

Defines UID/GID of destination; see L<Sys::Export::Unix/dst_userdb>.

=item -rewrite_path

Hashref of rewrites; see L<Sys::Export::Unix/rewrite_path>.

=item -rewrite_user

Hashref of rewrites; see L<Sys::Export::Unix/rewrite_user>.

=item -rewrite_group

Hashref of rewrites; see L<Sys::Export::Unix/rewrite_group>.

=back

=head1 EXPORTS

=head2 exporter

A function to access C<$Sys::Exporter::exporter>

=head2 init_global_exporter

  init_global_exporter(\%config);

A function to initialize C<$Sys::Exporter::exporter>, which also handles autoselecting the
type of the exporter.

=head2 C<:basic_methods> bundle

You get this bundle by default if you configured a global exporter.  The following methods of
the global exporter object get exported as functions:

=over

=item L<add|Sys::Export::Unix/add>

=item L<skip|Sys::Export::Unix/skip>

=item L<find|Sys::Export::Unix/src_find>

=item L<which|Sys::Export::Unix/src_which>

=item L<finish|Sys::Export::Unix/finish>

=item L<rewrite_path|Sys::Export::Unix/rewrite_path>

=item L<rewrite_user|Sys::Export::Unix/rewrite_user>

=item L<rewrite_group|Sys::Export::Unix/rewrite_group>

=back

along with the exports L</exporter> and L</filedata>.

=head2 C<:isa> bundle

  use Sys::Export ":isa";

These boolean functions are useful for type inspection.

=over

=item isa_exporter

Is it an object and an instance of C<Sys::Export::Exporter>?

=item isa_export_dst

Is it an object which can receive exported files? (C<add> and C<finish> methods)

=item isa_userdb

Is it an instance of C<Sys::Export::Unix::UserDB>?

=item isa_user

Is it an instance of C<Sys::Export::Unix::UserDB::User>?

=item isa_group

Is it an instance of C<Sys::Export::Unix::UserDB::Group>?

=item isa_hash

Is it a hashref?

=item isa_array

Is it an arrayref?

=item isa_data_ref

Is it a scalar ref or an object with method C<as_scalarref>?

=item isa_handle

Is it a GLOB ref or IO::Handle?

=item isa_int

Is it an integer?

=item isa_pow2

Is it a power of 2?

=back

=head2 C<:stat_modes> bundle

  S_IFREG S_IFDIR S_IFLNK S_IFBLK S_IFCHR S_IFIFO  S_IFSOCK S_IFWHT S_IFMT

These are like the exports from L<Fcntl>, but return 0 if the macro is not defined on this platform.

=head2 C<:stat_tests> bundle

  S_ISREG S_ISDIR S_ISLNK S_ISBLK S_ISCHR S_ISFIFO S_ISSOCK S_ISWHT

These are like the exports from L<Fcntl>, but return false if the macro is not defined on this platform.

=head2 expand_stat_shorthand

  @kv_list= expand_stat_shorthand($arrayref);
  @kv_list= expand_stat_shorthand($mode, $name);
  @kv_list= expand_stat_shorthand($mode, $name, $mode_specific_data);
  @kv_list= expand_stat_shorthand($mode, $name, \%other_attrs);
  @kv_list= expand_stat_shorthand($mode, $name, $mode_specific_data, \%other_attrs);

This is a utility function that takes a shorthand array notation for a directory entry, and
expands it to the file attribute names as used in L<Sys::Export::Unix/add> or
L<Sys::Export::CPIO/add>.

The C<$mode> can either be a numeric Unix mode like C<< use Fcntl 'S_IFDIR'; (S_IFDIR|0755) >>
or a name like C<'dir'> (with default permissions) or a name with a permission suffix like
C<'dir755'>.

For example:

  [ file644 => "foo", $literal_data ],
  [ file644 => "foo", { data_path => $filename } ],
  [ dir700  => "root/.ssh" ],
  [ dir1777 => "tmp" ],
  [ sym     => "bar" => "foo" ],
  [ chr777  => "dev/null" => [1,3] ],
  [ blk660  => "dev/sda"  => [8,0], { group => "disk" } ],
  [ fifo    => "run/queue" ],
  [ sock    => "run/mysqld/mysql.sock", { user => "mysql", group => "mysql" } ],

The default permissions are C<< 0777 & ~umask >> for a directory, C<0777> for symlinks, and
C<< 0666 & ~umask >> for others.

=head2 round_up_to_pow2

  $pow2= round_up_to_pow2($number);

Return a number rounded up to the next power of 2, or itself if it was already a power of 2.
Dies if the number is less than 0.  Returns 1 when C<$number> is 0.

=head2 round_up_to_multiple

  $aligned= round_up_to_multiple($n, $pow2);

Return a number rounded up to the next multiple of a power of 2.
Dies if the number is less than 0.

=head2 map_or_load_file

  $scalar_ref= map_or_load_file($path);
  $scalar_ref= map_or_load_file($path, $offset);
  $scalar_ref= map_or_load_file($path, $offset, $length);

If L<File::Map> is available, this creates a read-only memory map of the file (from the
specified offset) and returns a scalar ref to it.  If not, it simply loads the file into
a scalar and returns a ref to that.  You should assume the data in the scalar is read-only.

=head2 filedata

  $filedata= filedata($path);
  $filedata= filedata($path, $offset);
  $filedata= filedata(\$scalar_ref, $offset, $length);

This is a shortcut for creating L<Sys::Export::LazyFileData> objects.  These objects delay the
memory-mapping of a file (or substr operation on a large scalar) until it is needed.  This is
a convenient way to pass file data to various methods such as L</add>.

=head2 write_file_extent

  write_file_extent($fh, $file_addr, $size, $data_ref, $data_ofs, $description=undef);

This utility method writes a full extent of a file, padding the supplied data with NUL bytes
if needed.  It first seeks to C<$file_addr>, then writes a full C<$size> bytes from
C<$$data_ref> from offset C<$data_ofs> if possible.
If the length of the scalar in C<$$data_ref> is too short, this pads the write with NUL bytes.
If C<$$data_ref> is especially large (>1MiB) it first performs a syswrite of as many whole pages
of the data as possible, then pads the final page with NUL bytes on a second syswrite.

You can skip the seek operation with an undefined C<$file_addr>, in which case it just syswrites
from the current position of the file.

C<$description> is for debug-logging purposes and can be C<undef>.

If any syscall fails, or can't write the full size, this croaks.

=head1 VERSION

version 0.006

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
