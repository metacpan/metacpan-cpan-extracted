package Sys::Export::ISO9660::File;

our $VERSION = '0.005'; # VERSION
# ABSTRACT: Represents a file in ISO9660, including packed encodings of directories

use v5.26;
use warnings;
use experimental qw( signatures );
use parent 'Sys::Export::Extent';
use Sys::Export::ISO9660;
our @CARP_NOT= qw( Sys::Export::ISO9660 );


sub block_size($self) { 2048 }
sub mtime($self, @v) { @v? ($self->{mtime}= $v[0]) : $self->{mtime} }
sub flags($self, @v) { @v? ($self->{flags}= $v[0]) : $self->{flags} }
sub is_dir($self) { ($self->{flags}||0) & Sys::Export::ISO9660::FLAG_DIRECTORY() }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Export::ISO9660::File - Represents a file in ISO9660, including packed encodings of directories

=head1 CONSTRUCTORS

=head2 new

  $file= Sys::Export::ISO9660::File->new(%attributes);

Represents file (or directory) data to be encoded into the ISO image.

=head1 ATTRIBUTES

=head2 name

Unicode full path to file, for debugging.

=head2 block_size

Always 2048.

=head2 size

Size, in bytes.  See L<Sys::Export::Extent/size>.

=head2 device_offset

Byte offset from start of image.  See L<Sys::Export::Extent/device_offset>.

=head2 block_address

LBA number (device_offset / 2048) where this file is located on the device.
Reading this attribute returns C<undef> if C<device_offset> is undefined or negative.

=head2 data

Data to be written to extent.  See L<Sys::Export::Extent/data>.

=head2 mtime

Unix epoch time of file creation/modification, used as default for directory entries.
(every directory entry can override the mtime)

=head2 flags

Bit flags of file.  Constants come from C<< use Sys::Export::ISO9660 ':flags' >>.

=head2 is_dir

True if the flags include C<FLAG_DIRECTORY>

=head1 VERSION

version 0.005

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
