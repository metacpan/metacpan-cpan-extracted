package Punk::Static;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.28';

1;

__END__

=head1 NAME

Punk::Static - serving files from a directory

=head1 SYNOPSIS

    static '/static' => 'root/static';

    # a freshness lifetime for plain URLs
    static '/static' => 'root/static', max_age => 3600;

    # content-addressed URLs, opt-in
    static '/static' => 'root/static', fingerprint => 1;
    $c->asset('/static/app.css');   # /static/app.9f3a1c2b0d4e5f60.css

    # in a template
    {% "/static/app.css" | asset %}

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

=head2 Freshness

A validator makes a stale copy cheap to detect. It does not make it
unnecessary to ask: with no freshness lifetime, a browser revalidates
every asset on every page load, and a page with a dozen of them spends a
dozen round trips confirming that nothing changed.

The lifetime that would remove those round trips cannot safely be given
to C</static/app.css>, because that URL means something different after
every deploy. So the URL changes with the bytes:

    static '/static' => 'root/static', fingerprint => 1;

    $c->asset('/static/app.css')   # /static/app.9f3a1c2b0d4e5f60.css

C</static/app.9f3a1c2b0d4e5f60.css> is served from C<app.css> and
answers with

    Cache-Control: public, max-age=31536000, immutable

which is true of that URL whatever happens to the file. The digest is
checked against the file's current contents before the header is sent,
so a URL held over from an older deploy - a page still in a cache, a
bookmarked stylesheet - serves the current bytes with the ordinary
revalidating headers instead. C<immutable> is never sent for a URL that
could come to mean something else.

The digest is the first 8 bytes of SHA-256 over the contents, and the
contents are the point: an mtime differs per machine and per deploy, so
a fleet keyed on one would serve a different URL per box for identical
bytes, and HTML from one box would name an asset URL another box has
never heard of.

Only the C<< <name>.<digest>.<ext> >> form is recognised, in both
directions. A path with no extension has nowhere to put a digest, so
L</asset> hands it back unchanged and it serves as it always did. The
literal path is tried first, so a file genuinely checked in under a
fingerprinted name still serves as itself.

Precompressed siblings (C<app.css.gz>) are unaffected: the URL is named
by the identity file's digest, and the sibling still supplies the bytes,
its own C<ETag> and the C<Content-Encoding>.

The same story for a route that renders rather than reads is
L<Punk::Plugin::ConditionalGet>: a file gets both halves here - a
freshness lifetime so the request is not made, and a validator so it is
cheap when it is - while a dynamic response can rarely be given a
lifetime and so has only the second.

The response body is a real filehandle, so a server that can stream or
C<sendfile> does, rather than the file being read into memory first. A
C<HEAD> sends the same headers with an empty body and never opens the
file.

In production, static files usually belong in front of the application
(nginx, a CDN); this is for development and for the small set of assets
an app genuinely owns.

=head1 OPTIONS

The C<static> keyword takes them after the directory, and
L</app($dir, %opts)> takes the same set.

=over 4

=item max_age

Seconds of freshness for a B<plain> URL, sent as
C<Cache-Control: public, max-age=N>. There is no default: a mount that
says nothing behaves exactly as it did before, revalidating each time.
Give this only to assets you are willing to have served stale for that
long - the fingerprinted URL is the answer for everything else.

=item cache_control

A verbatim header value, overriding C<max_age>, for anything the two
spellings above do not cover (C<private, no-store> for a mount behind
authentication, say).

=item fingerprint

Content-addressed URLs. B<Off> unless asked for: fingerprinting changes
what a path means - a URL shaped like a fingerprint stops being a 404
and starts resolving to another file - and a mount should not begin
doing that because it was upgraded. Until it is on, L</asset> hands back
the URL it was given, so a template written against it works either way.

=item dev

Whether a cached digest is re-checked against the file. Under the
C<static> keyword this follows C<< $app->env >>: in C<development> an
edited file is re-read and gets a new URL on the next reload, and
outside it a digest is computed once and then believed, since files do
not change under a running process. Set it explicitly to override.

=back

=head1 METHODS

=head2 app($dir, %opts)

The PSGI coderef for a directory. Croaks unless the directory exists,
so a mistyped path fails at boot with the rest of the configuration, and
croaks on an option it does not recognise. The options may also be given
as a single hashref.

=head2 asset($url)

A context method, not a class method: C<< $c->asset('/static/app.css') >>
returns the content-addressed URL for a file under a static mount. A URL
under no static mount, under one with fingerprinting off, or naming a
file that cannot be read comes back exactly as it went in - the page
still works, it just revalidates.

Templates rendered through the shipped Stencil engine get the same thing
as a filter, registered unless the application has one of its own by
that name:

    <link rel="stylesheet" href="{% "/static/app.css" | asset %}">

=head1 SEE ALSO

L<Punk>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
