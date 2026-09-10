package Punk::Request;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.48';

1;

__END__

=head1 NAME

Punk::Request - a lazy wrapper over the PSGI environment

=head1 DESCRIPTION

Nothing is parsed until asked for, and everything parsed is cached on
the object: query pairs, form bodies, cookies, the raw body. Reached
through L<Punk::Context/req>.

The object is a plain blessed array with a fixed slot layout and an
all-C implementation - percent-decoding, pair splitting, multi-value
promotion and header lookup without the regex engine; the body read
runs through PerlIO and JSON decodes through File::Raw::JSON's C ABI.
Load this module through L<Punk>, which loads the compiled core first.

=head1 METHODS

=head2 new($env)

Constructed by the dispatcher; wraps the PSGI environment.

=head2 env

=head2 method

=head2 path

The raw environment, request method and path (C</> when empty).

=head2 address

The client's address: C<REMOTE_ADDR>. On a directly-exposed application that
is the socket peer. Behind a reverse proxy with the C<proxy> keyword in force
it is the resolved client, because L<Punk> rewrites the env key rather than
adding a second one - see L<Punk/proxy>. The connecting address is then
available as C<< $c->env->{'punk.peer_addr'} >>.

=head2 header($name)

A request header by name, case-insensitively (C<Content-Type> and
C<Content-Length> included).

=head2 headers

Every request header as a hashref, keyed lowercase and dash-separated -
C<x-forwarded-for>, C<content-type>, C<content-length> - which is how
HTTP/2 spells them and the same shape the OpenAPI validation path builds.

Reach for L</header> when you know the name: it folds case, and a plain
hash cannot, so C<< $req->headers->{'X-Foo'} >> misses where
C<< $req->header('X-Foo') >> hits. This is for the cases where you want
them all - logging, proxying, signing.

The hash is built fresh each call, so keeping or changing it is safe.

=head2 param($name)

Query parameter first, then form body parameter. A repeated parameter
yields an arrayref.

=head2 params

=head2 params(@names)

With no names, one merged hashref, query winning over form.

With names, only those, looked up the way L</param> looks one up. The
return follows context: a list of values in the order asked for, C<undef>
for a name neither table has -

    my ($page, $size) = $req->params(qw(page size));

or, in scalar context, a hashref holding only the names that were there,
which is the shape to build a filter from -

    my %filter = %{ $req->params(qw(state queue task)) };

A dereference block puts what it wraps in scalar context, so the C<%{ }>
above gets the hashref. Somewhere already in list context - an argument
list, a hash constructor - it takes the slice instead, so ask for the
hashref explicitly there with C<scalar>.

Passing a list that happens to be empty is passing no names at all, and
so gives everything: guard the call where the names are built at runtime.

=head2 query

=head2 form

The parsed body: C<application/x-www-form-urlencoded> pairs, or the field parts
of a C<multipart/form-data> submission (whose file parts become uploads).

=head2 upload($name)

=head2 uploads

The L<Punk::Upload> for a multipart file field - the first if several - and the
C<< { name =E<gt> upload | [uploads] } >> hash of all of them. Both parse the
body once.

=head2 body

The raw request body bytes (undef when there is none), read once and
rewound.

=head2 json

The body decoded as JSON through File::Raw::JSON's C ABI.

=head2 xml

The body parsed as XML through File::Raw::XML's C ABI, as a
L<File::Raw::XML::Document>; C<undef> when there is no body. Walk it with
C<< ->root >> and the node methods, or query it with C<< ->xpath >>.

Punk maps nothing between XML and Perl data. JSON's model is Perl's, so a
hash reference has one obvious encoding; XML's is not, and every convention
for elements against attributes, ordering, mixed content and repeated
elements is wrong for some schema. What you get is the document.

The parse is strict: a document type declaration is refused wherever it
stands, which is what removes external entities, parameter entities, the
external DTD fetch, XXE and the billion laughs - not as a setting that could
be turned off, but as a shape the parser will not accept. There are no
options, and there will not be: a profile or a resolver reachable from a
request is the switch that would give all of that back. A body that is not
well-formed dies, as a malformed JSON body does; the size ceiling is
C<max_body>, which refuses an oversized body before it is read at all.

The document is parsed once and kept for the rest of the request, so two
calls answer with the same object rather than two copies - which is what
makes a node's C<< ->doc >> and a C<by_id> result name one document. That
tree is editable, so a change one caller makes is a change the next one
sees, the way C<body> hands back the one cached scalar.

=head2 body_each($code, %options)

    my $bytes = $c->req->body_each(sub {
        my ($chunk, $req) = @_;
        $digest->add($chunk);
    });

The body a window at a time instead of all at once. C<$code> is called with
each chunk and the request; the return value is the total byte count.

C<body> copies the whole request into one scalar, which is right for JSON and
wrong for anything large - the server is already holding those bytes, and the
copy doubles them for as long as the handler runs. This is the same window the
multipart parser has always read uploads through, for a body that is not
multipart: an import, an C<application/octet-stream> C<PUT>, a feed of
newline-delimited JSON.

Options: C<chunk>, the window size in bytes (default 65536), and C<max>, a
ceiling after which the read croaks (default 0, no ceiling).

=head2 body_to($dest, %options)

    my $bytes = $c->req->body_to('/var/spool/import.ndjson');
    my $bytes = $c->req->body_to($fh, chunk => 1024 * 1024);

The body straight to a file - a path, which is opened and closed here, or a
handle already open for writing. Nothing larger than one window is ever held
in the application. Takes the same C<chunk> and C<max> options, and returns
the byte count.

=head2 Reading the body once

A body can be read whole or in chunks, not both ways round. After
C<body_each> or C<body_to> the bytes have gone, and C<body>, C<json> and
C<form> croak saying so rather than answering with nothing - an empty string
where a body was expected is a bug that ships. The other order is not a trap:
a body already read whole is replayed to C<body_each> from the copy, so the
order two pieces of code happen to run in cannot break either.

=head2 A body with no CONTENT_LENGTH

An HTTP/2 or HTTP/3 client streaming an upload declares no length: both
versions forbid C<Transfer-Encoding>, so such a request carries no framing
header at all. HTTP/1.1 spells the same thing C<< Transfer-Encoding: chunked >>.
Either way there is no length to read to, and what decides whether the body
can be read is C<psgix.input.buffered>.

A server that sets it - Hyperman on every protocol version, Starman, anything
that buffers the request before calling the application - is holding a finite
body already, so it is read to EOF. A server that does not is handing over a
live socket, where reading to EOF is how an application hangs: an HTTP/1.1
chunked body croaks with that reason rather than hanging, and a request with
no framing header at all is taken to have no body and nothing is read. That
last case is the ordinary bodyless C<POST>, and going looking for a body there
would turn it into an error.

C<max> is the ceiling in all of this. Without an explicit one the route's
L<Punk/max_body> applies, which is the ceiling C<max_body> could not enforce
up front for want of a declared length to compare against.

=head2 cookies

=head2 cookie($name)

The request cookie jar (first value wins) / one cookie value.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
