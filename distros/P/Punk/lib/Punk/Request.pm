package Punk::Request;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.14';

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
