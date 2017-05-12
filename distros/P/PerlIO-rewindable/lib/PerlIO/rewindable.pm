=head1 NAME

PerlIO::rewindable - I/O layer to allow rewinding of streams

=head1 SYNOPSIS

	binmode \*STDIN, ":rewindable";

=head1 DESCRIPTION

This PerlIO layer makes it possible to rewind an input stream that would
otherwise not be rewindable, such as a TTY or a pipe from another process.
Reads pass through this layer, reading from the underlying stream, but
this layer keeps a copy of everything that is read.  C<seek> can be used
to move around within the saved data to reread it.

C<seek>s may be relative (whence=1, C<SEEK_CUR>) or absolute (whence=1,
C<SEEK_SET>).  For the purposes of absolute seeking, position 0 is
wherever the stream was when this layer was pushed.  C<tell> can be
used to read this absolute position.  End-relative C<seek>s (whence=2,
C<SEEK_END>) are not supported, even if the underlying stream has
signalled EOF.  If the underlying stream is actually seekable, for
example if it is actually a regular file, that aspect of it is hidden
by the rewindability layer.

Seeking both backwards and forwards is supported within the saved data
that was previously read.  Seeking forwards past the last data read from
the underlying stream is not currently supported, but this may change
in the future.

Writing is not permitted through the rewindability layer.

If this layer is popped, it attempts to maintain any rewound state, by
generating a temporary PerlIO layer to hold pending data.  This is then
subject to normal PerlIO behaviour, which does not strongly maintain
consistency of such rewinding.

=cut

package PerlIO::rewindable;

{ use 5.008001; }
use warnings;
use strict;

our $VERSION = "0.001";

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

=head1 SEE ALSO

L<IO::Handle/ungetc>,
L<PerlIO>,
L<perlfunc/open>,
L<perlfunc/seek>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2010, 2011 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
