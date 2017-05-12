package Ogg::Vorbis::Decoder;

use strict;
use vars qw($VERSION);

$VERSION = '0.9';

BOOT_XS: {
        # If I inherit DynaLoader then I inherit AutoLoader
	require DynaLoader;

	# DynaLoader calls dl_load_flags as a static method.
	*dl_load_flags = DynaLoader->can('dl_load_flags');

	do {__PACKAGE__->can('bootstrap') ||
		\&DynaLoader::bootstrap}->(__PACKAGE__,$VERSION);
}

sub current_bitstream {
	my $self = shift;
	return $self->{'BSTREAM'};
}

1;

__END__

=head1 NAME

Ogg::Vorbis::Decoder - An object-oriented Ogg Vorbis to decoder

=head1 SYNOPSIS

  use Ogg::Vorbis::Decoder;
  my $decoder = Ogg::Vorbis::Decoder->open("song.ogg");
  my $buffer;
  while ((my $len = $decoder->read($buffer) > 0) {
    # do something with the PCM stream
  }

  OR

  open OGG, "song.ogg" or die $!;
  my $decoder = Ogg::Vorbis::Decoder->open(\*OGG);

  OR

  # can also be IO::Socket or any other IO::Handle subclass.
  my $fh = IO::Handle->new("song.ogg");
  my $decoder = Ogg::Vorbis::Decoder->open($fh);

=head1 DESCRIPTION

This module provides users with Decoder objects for Ogg Vorbis files.
One can read data in PCM format from the stream, seek by raw bytes,
pcm samples, or time, and gather decoding-specific information not
provided by Ogg::Vorbis::Header.  Currently, we provide no support for
the callback mechanism provided by the Vorbisfile API; this may be
included in future releases.

=head1 CONSTRUCTOR

=head2 C<open ($filename)>

Opens an Ogg Vorbis file for decoding. It opens a handle to the file or uses
an existing handle and initializes all of the internal vorbis decoding
structures.  Note that the object will maintain open file descriptors until
the object is collected by the garbage handler. Returns C<undef> on failure.

=head1 INSTANCE METHODS

=head2 C<read ($buffer, [$size, $word, $signed])>

Reads PCM data from the Vorbis stream into C<$buffer>.  Returns the
number of bytes read, 0 when it reaches the end of the stream, or a
value less than 0 on error. 

The optional parameters include (with corresponding default values):

C<size = 4096>
C<word = 2>
C<signed = 1>

Consult the Vorbisfile API (http://www.xiph.org/ogg/vorbis/doc/vorbisfile/reference.html) 
for an explanation of the various values.

=head2 C<sysread ($buffer, [$size, $word, $signed])>

An alias for C<read>

=head2 C<raw_seek ($pos)>

Seeks through the compressed bitstream to the offset specified by
C<$pos> in raw bytes.  Returns 0 on success.

=head2 C<pcm_seek ($pos, [$page])>

Seeks through the bitstream to the offset specified by C<$pos> in pcm
samples.  The optional C<$page> parameter is a boolean flag that, if
set to true, will cause the method to seek to the closest full page
preceding the specified location.  Returns 0 on success.

=head2 C<time_seek ($pos, [$page])>

Seeks through the bitstream to the offset specified by C<$pos> in
seconds.  The optional C<$page> parameter is a boolean flag that, if
set to true, will cause the method to seek to the closest full page
preceding the specified location.  Returns 0 on success.

=head2 C<current_bitstream ()>

Returns the current logical bitstream of the decoder.  This matches the
bitstream paramer optionally passed to C<read>.  Useful for saving a
bitstream to jump to later or to pass to various information methods.

=head2 C<bitrate ([$stream])>

Returns the average bitrate for the specified logical bitstream.  If
C<$stream> is left out or set to -1, the average bitrate for the entire
stream will be reported.

=head2 C<bitrate_instant ()>

Returns the most recent bitrate read from the file.  Returns 0 if no
read has been performed or bitrate has not changed.

=head2 C<streams ()>

Returns the number of logical bitstreams in the file.

=head2 C<seekable ()>

Returns non-zero value if file is seekable, 0 if not.

=head2 C<serialnumber ([$stream])>

Returns the serial number of the specified logical bitstream, or that
of the current bitstream if C<$stream> is left out or set to -1.

=head2 C<raw_total ([$stream])>

Returns the total number of bytes in the physical bitstream or the
specified logical bitstream.

=head2 C<pcm_total ([$stream])>

Returns the total number of pcm samples in the physical bitstream or the
specified logical bitstream.

=head2 C<time_total ([$stream])>

Returns the total number of seconds in the physical bitstream or the
specified logical bitstream.

=head2 C<raw_tell ()>

Returns the current offset in bytes.

=head2 C<pcm_tell ()>

Returns the current offset in pcm samples.

=head2 C<time_tell ()>

Returns the current offset in seconds.

=head1 REQUIRES

libogg, libvorbis, libogg-dev, libvorbis-dev

=head1 CURRENT AUTHOR

Dan Sully E<lt>daniel@cpan.orgE<gt>

=head1 AUTHOR EMERITUS

Dan Pemstein E<lt>dan@lcws.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2004-2010, Dan Sully.  All Rights Reserved.

Copyright (c) 2003, Dan Pemstein.  All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at
your option) any later version.  A copy of this license is included
with this module (LICENSE.GPL).

=head1 SEE ALSO

L<Ogg::Vorbis::Header>

=cut
