package Sys::Export::VFAT::File;

our $VERSION = '0.004'; # VERSION
# ABSTRACT: Represents a file in VFAT, including packed encodings of directories

use v5.26;
use warnings;
use experimental qw( signatures );
use Sys::Export::VFAT;
use Carp;
our @CARP_NOT= qw( Sys::Export::VFAT );


sub new($class, %attrs) {
   my $self= bless {}, $class;
   for (qw( name size data flags btime atime mtime align device_offset cluster )) {
      if (defined (my $v= delete $attrs{$_})) {
         $self->{$_}= $v
      }
   }
   croak "Unknown attribute: ".join(', ', keys %attrs) if keys %attrs;
   $self;
}


sub name      { $_[0]{name} }
sub size      { $_[0]{size} }
sub data      { $_[0]{data} }
sub flags     { $_[0]{flags} }
sub mtime     { $_[0]{mtime} }
sub atime     { $_[0]{atime} }
sub btime     { $_[0]{btime} }
sub align     { $_[0]{align} }
sub device_offset { $_[0]{device_offset} }
sub cluster   { $_[0]{cluster} }
sub is_dir    { $_[0]{flags} & Sys::Export::VFAT::ATTR_DIRECTORY() }

# Avoiding dependency on namespace::clean
delete @{Sys::Export::VFAT::File::}{qw( carp confess croak )};
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Export::VFAT::File - Represents a file in VFAT, including packed encodings of directories

=head1 DESCRIPTION

Represents file (or directory) data to be encoded into the VFAT image.  This object functions
sort of like an 'inode', storing the attributes of the file, even though VFAT actually stores
the file attributes at the directory entry level.  This facilitates fun hacks like hard-linking
files in a VFAT filesystem even though VFAT doesn't permit that.

=head1 CONSTRUCTORS

=head2 new

  $file= Sys::Export::VFAT::File->new(%attributes);

=head1 ATTRIBUTES

=head2 name

Unicode full path of file, for debugging

=head2 size

Size, in bytes

=head2 data

A reference to literal data of this file, which could be a scalar ref or
L<LazyFileData|Sys::Export::LazyFileData> object.

=head2 flags

Default directory listing flags

=head2 btime

Default creation ('born') unix epoch time

=head2 mtime

Default modification unix epoch time

=head2 atime

Default last-access unix epoch time

=head2 align

Request file be allocated on a power-of-two boundary from the start of the device.

=head2 device_offset

If initially set, request that file be placed at an absolute offset from start of the device.
If it can't be honored, encoding of the filesystem will fail.  After encoding, this will be
set to the location chosen for the file.

=head2 cluster

After encoding, this will be set to the cluster ID of the file.

=head2 is_dir

True if L</flags> indicate that this is a directory.

=head1 VERSION

version 0.004

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
