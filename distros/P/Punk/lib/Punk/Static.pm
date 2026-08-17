package Punk::Static;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.14';

1;

__END__

=head1 NAME

Punk::Static - serving files from a directory

=head1 SYNOPSIS

    static '/static' => 'root/static';

    # or directly
    my $app = Punk::Static->app('root/static');

=head1 DESCRIPTION

The app behind the C<static> keyword, mounted behind a prefix so
C<PATH_INFO> arrives already stripped. Implemented in C: the method
check, the traversal guard, the C<stat>, the conditional-request
comparison and the header block all happen without a Perl frame.

C<GET> and C<HEAD> only; anything else is a C<405> with an C<Allow>
header. The content type comes from the file extension, falling back to
C<application/octet-stream>. C<Last-Modified> is sent on every response,
and a request whose C<If-Modified-Since> matches it exactly gets a
C<304> - which is all a static file needs, since the date a client
returns is the date it was given.

A path containing a C<..> segment or a NUL byte is a B<404>, not
something to normalise: a request carrying one is not asking for a file
this serves. Anything that is not a regular file is a 404 too.

The response body is a real filehandle, so a server that can stream or
C<sendfile> does, rather than the file being read into memory first. A
C<HEAD> sends the same headers with an empty body and never opens the
file.

In production, static files usually belong in front of the application
(nginx, a CDN); this is for development and for the small set of assets
an app genuinely owns.

=head1 METHODS

=head2 app($dir)

The PSGI coderef for a directory. Croaks unless the directory exists,
so a mistyped path fails at boot with the rest of the configuration.

=head1 SEE ALSO

L<Punk>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
