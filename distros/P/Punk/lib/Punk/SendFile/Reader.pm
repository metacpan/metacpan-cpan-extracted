package Punk::SendFile::Reader;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.17';

1;

__END__

=head1 NAME

Punk::SendFile::Reader - the bounded body of a ranged send_file response

=head1 DESCRIPTION

You never construct one of these. When C<< $c->send_file >> answers a
C<Range> request from a file it cannot hand the server a plain
filehandle - a PSGI server reads a filehandle body to end of file, and a
C<206> must stop at the end of the range. This object is the PSGI body
protocol over exactly that window: C<getline> returns successive chunks
of up to 64KB until the range is spent, then C<undef>; C<close> closes
the underlying handle. The handle is also closed when the object is
freed.

A server that streams bodies natively never reads it chunkwise at all:
C<fileno> exposes the descriptor, and together with the response's
C<Content-Length> that is the whole window.

The class lives in the C core (C<punk_sendfile.h>, C<xs/sendfile.xs>);
this file is documentation.

=head1 METHODS

=head2 getline

The next chunk (at most 64KB, never past the range), or C<undef> when
the range is spent.

=head2 close

Close the underlying filehandle. C<getline> afterwards returns C<undef>.

=head2 fileno

The underlying file descriptor, or -1 once closed. A server that streams
natively (Hyperman 0.20+) uses C<fileno> plus the response's
C<Content-Length> to send the range straight from the file - the fd's
current position is the start of the window - and never calls C<getline>
at all.

=head1 SEE ALSO

L<Punk::Context/send_file>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
