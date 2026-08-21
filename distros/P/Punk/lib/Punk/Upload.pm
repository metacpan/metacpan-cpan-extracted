package Punk::Upload;

use 5.010;
use strict;
use warnings;
use Carp ();
use Punk ();

our $VERSION = '0.27';

# A read handle on a spilled part, or undef when the bytes are in memory.
# Perl rather than XS because making a filehandle in XS is a glob dance for
# something `open` does in one line - and the rest of this class is XS, so
# this is the only reason the module is loaded at all.
sub fh {
    my ($self) = @_;
    my $path = $self->path;
    return undef unless defined $path && length $path;
    open my $fh, '<:raw', $path
        or Carp::croak("Punk::Upload: cannot open '$path': $!");
    return $fh;
}

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

A part smaller than 64 KiB is held in memory. A larger one is written to a
temp file as it arrives, and the object carries a C<path> to it rather than
the bytes - so an upload costs a file and a few kilobytes, whatever its size.

=head1 METHODS

=head2 filename

The client-supplied file name. B<Do not trust it as a path.> It is request
bytes: it never names the temp file, and it should never name yours.

=head2 name

The form field name.

=head2 type

The part's C<Content-Type> (C<application/octet-stream> if the client sent
none).

=head2 size

The byte length.

=head2 path

The temp file holding the bytes, or C<undef> when the part was small enough to
stay in memory.

The file belongs to the request and is removed when it ends - including when
the handler died. Do not keep the path expecting the file to still be there;
use C<save> or L</fh>.

=head2 fh

A read handle on the temp file, or C<undef> when the bytes are in memory.

The way to process a large upload without ever holding it: read it in chunks,
hash it, hand it to something that takes a handle.

=head2 content

The uploaded bytes.

When the part is on disk this B<reads the whole file into memory>, which is
exactly what streaming it to disk avoided. That is fine for a small part and
is why the method still exists and still works; on a large one it is the cost
you were avoiding, paid in one line. L</fh> or L</path> instead.

=head2 save($path)

Put the uploaded bytes at C<$path>. Returns true, croaks if it cannot.

When the part is already a file and C<$path> is on the B<same filesystem>,
this is a C<rename> - the bytes are not read or written at all. Across
filesystems it copies in chunks, still without them passing through memory.
A part held in memory is simply written out.

So the spill directory wants to be on the same filesystem as wherever you keep
things. That is the difference between free and another whole copy of a large
file.

=head1 WHERE THE TEMP FILES LIVE

C<upload_dir> on the application, else C<TMPDIR>, else F</tmp>:

    upload_dir '/var/lib/myapp/incoming';

Name it, for two reasons. It decides the B<filesystem>, which decides whether
C<save> is a rename. And it decides what is on that filesystem: uploads are
attacker-controlled bytes taking attacker-chosen amounts of space, bounded by
the server's request ceiling, and putting them somewhere with the room and the
permissions you intended is better than discovering F</tmp> was shared with
something that mattered.

Names there owe nothing to the client's filename, and every file is removed
when its request ends.

=head1 SIZE, HONESTLY

An upload no longer arrives in memory at all. Measured end to end through a
socket, into a handler that holds the upload:

    128 MiB upload    worker RSS 15.5 MiB

against roughly 275 MiB before the streaming work, when the bytes were
resident four times over - the server's read buffer, the SV behind
C<psgi.input>, Punk's own slurp of the body, and the decoded part.

What still bounds you:

=over 4

=item * L<Hyperman/max_body> is the largest request B<accepted>. It is no
longer a memory ceiling, so it can be raised for uploads without raising what
a worker holds.

=item * B<Chunked bodies are not spilled by Hyperman.> A
C<Transfer-Encoding: chunked> request has no C<Content-Length> to divert on
and still accumulates in memory.

=item * Disk is now the resource an upload spends. A ceiling is still the
thing standing between a form and a full filesystem, and streaming does not
make attacker-controlled bytes safe to accept - only cheaper to receive.

=back

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
