package Punk::Upload;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.17';

1;

__END__

=head1 NAME

Punk::Upload - an uploaded file from a multipart form

=head1 SYNOPSIS

    post '/avatar' => sub {
        my ($c) = @_;
        my $up = $c->req->upload('avatar') or return $c->text('no file', 400);
        $up->save("/var/uploads/" . $up->filename);
        $c->json({ name => $up->filename, bytes => $up->size });
    };

=head1 DESCRIPTION

A file part of a C<multipart/form-data> request. C<< $c->req->form >> parses the
body once: ordinary fields become parameters (C<< $c->param >>), and file parts
become C<Punk::Upload> objects reachable through C<< $c->req->upload($name) >>
(or C<< $c->upload($name) >>) and C<< $c->req->uploads >>. A field uploaded more
than once yields an arrayref from C<uploads>; C<upload> gives the first.

The bytes are held in memory in this cut - bound your request body size
accordingly; a tempfile-backed mode for large uploads is a follow-on.

=head1 METHODS

=head2 filename

The client-supplied file name (do not trust it as a path).

=head2 name

The form field name.

=head2 type

The part's C<Content-Type> (C<application/octet-stream> if the client sent
none).

=head2 size

The byte length.

=head2 content

The uploaded bytes.

=head2 save($path)

Write the bytes to C<$path>. Croaks if it cannot open the file.

Note what this is not: the bytes were already resident before the handler
ran, so this is a write, not a stream. C<< ->save >> does not reduce the
memory an upload costs; it only puts a copy on disk.

=head1 SIZE, HONESTLY

An upload arrives whole, in memory, twice over - once in the server's read
buffer and again as the decoded part - before a handler sees it. So:

=over 4

=item * the practical maximum is the server's request ceiling, which for
L<Hyperman> is C<max_body> and defaults to B<16MB>

=item * raising that ceiling raises a worker's worst-case resident size in
proportion: roughly C<workers x max_body x concurrent uploads per worker>

=item * L<Punk/max_body> does B<not> help here. It refuses an oversize
request after the bytes have arrived, which saves the parse and the
handler but not the memory

=back

For genuinely large uploads, terminate them at a proxy or hand the client a
pre-signed direct-to-storage URL and take only the resulting key. Raising a
server ceiling to a gigabyte to accept gigabyte uploads does work, and
costs a gigabyte per concurrent upload per worker.

=head1 SEE ALSO

L<Punk>, L<Punk::Request/upload>, L<Punk/max_body>,
L<Hyperman/"max_body: the request ceiling">.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
