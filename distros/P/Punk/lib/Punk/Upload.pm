package Punk::Upload;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.14';

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

=head1 SEE ALSO

L<Punk>, L<Punk::Request/upload>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
