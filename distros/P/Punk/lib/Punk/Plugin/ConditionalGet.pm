package Punk::Plugin::ConditionalGet;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.27';

1;

__END__

=head1 NAME

Punk::Plugin::ConditionalGet - ETags and 304s for dynamic responses

=head1 SYNOPSIS

    package MyApp;
    use Punk;

    plugin 'ConditionalGet';

    # the validator: 304 without running the handler
    get '/api/orders' => sub { ... }, {
        etag => sub { $_[0]->model('Order')->max_updated_at },
    };

    # or from the rendered bytes: saves the wire, not the server
    get '/dashboard' => sub { ... }, { etag => 1 };

=head1 DESCRIPTION

A file on disk already has the whole story: L<Punk::Static> sends an
C<ETag>, answers C<304> to C<If-None-Match>, and since 0.23 can carry a
freshness lifetime as well. A route that renders a page or returns JSON
has had none of it, so an unchanged dashboard is re-queried, re-rendered,
re-sent and re-parsed on every poll. This plugin aims to plug that gap.

=head2 The validator

C<etag> takes a coderef. It receives the context, and returns something
the application knows cheaply that identifies the current entity - a
row's C<updated_at>, a cache generation, a build revision:

    get '/api/orders' => sub { ... }, {
        etag => sub { $_[0]->model('Order')->max_updated_at },
    };

If the client sends that tag back, the response is a C<304> B<and the
handler never runs>. No queries, no render, no serialisation. That is
what this is for: a body ETag saves bandwidth, a validator saves the
server.

Returning C<undef> means "I do not know". The request proceeds normally
with no C<ETag> at all - a validator that cannot answer must never be
able to produce a wrong C<304>, and saying so has to be cheaper to write
than guessing.

The validator runs on every request to the route, not only the
conditional ones, because the C<200> needs the tag too: a client never
given one can never send one back.

It is application code, so it runs where application errors go - a croak
in it is the app's C<500>, not a response that quietly got slower.

=head2 What a 304 does not skip

Only the handler. A C<304> from here is an ordinary response and goes
through the same finishing path as any other, so everything that
decorates a response still decorates it.

That matters most for the things a skipped handler would otherwise eat:

=over 4

=item * B<Flash> is consumed on first read. A request whose handler never
ran never read it, so a C<304> in between two page loads leaves the
message riding for the next one.

=item * B<The session> is written back when it changed. A C<304> that
changed nothing writes nothing, and a guard that refreshed something
still gets its C<Set-Cookie>.

=item * B<CSRF> tokens are not spent by a response that rendered no form.

=back

=head2 Set response policy in a hook, not in the handler

This follows from answering early, and it is the one thing that catches
people out.

A C<304> carries the headers the C<200> would have carried - the
C<Cache-Control>, the C<Vary>, the security headers, the C<Set-Cookie>
the session write-back added - minus the ones describing a body that is
not being sent (C<Content-Type>, C<Content-Length>,
C<Content-Encoding>).

But with C<< etag => sub {...} >> the handler B<never runs>, so a header
the handler would have set was never set at all:

    # NOT on the 304 - the handler did not run
    get '/dashboard' => sub {
        my ($c) = @_;
        $c->header('Cache-Control' => 'private, max-age=30');
        $c->text(...);
    }, { etag => sub { ... } };

    # on both the 200 and the 304
    hook before_dispatch => sub {
        $_[0]->header('Cache-Control' => 'private, max-age=30');
        return;
    };

The body ETag has no such limit: its handler ran, so everything it set is
on the C<200> and carried to the C<304>.

=head2 What a validator does to a shared cache

An ETag is a storage instruction. A response that is per-user, or
per-encoding, carrying a validator with nothing saying what it depends
on, can be stored by any intermediary and handed to the next request for
that URL - and then confidently revalidated, because now there is a tag
to revalidate with. So a response this plugin tags gets two things it
would not otherwise have.

=over 4

=item * B<C<Vary: Accept-Encoding>, always.> Punk does not compress;
L<Hyperman> does, on the write path, after Punk has stopped looking. Two
clients, one accepting gzip and one not, therefore receive the same
entity and the same tag from here and B<different bytes> from the
server. A shared cache has to be told that or it stores one and serves
it to both. It is the same reasoning that puts this header on every
response from a C<static> mount, compressed or not.

=item * B<C<Cache-Control: private>, when the response could be about one
person.> A C<Set-Cookie> on the response is one signal; a C<Cookie> or
C<Authorization> on the B<request> is the one that matters, because a
signed-in user reading a page that changes nothing gets no write-back
and no C<Set-Cookie> - which is exactly the per-user response somebody
put an ETag on.

=back

Both merge rather than replace. An application that declared its own
C<Vary> keeps every token it named; an application that stated its own
C<Cache-Control> is never overruled, because it may have meant C<public>
and known why:

    get '/prices' => sub { ... }, { etag => 1 };   # gets private if
                                                   # cookies are in play

    get '/prices' => sub {                         # ...unless you say so
        $_[0]->header('Cache-Control' => 'public, max-age=60');
        ...
    }, { etag => 1 };

The C<private> rule is deliberately broad: a public page that happens to
carry an analytics cookie loses shared-cache storage on the routes that
opted into ETags, which costs a re-send. The other direction costs one
user being handed another user's page.

=head2 What this cannot check for you

If a handler negotiates B<by hand> - reading C<Accept> or
C<Accept-Language> itself and returning different bodies - nothing here
can see that, and the C<Vary> that would make it safe is yours to set.
L<respond_to|Punk::Context/respond_to> already declares C<Vary: Accept>
on every outcome, so negotiation done through it is covered.

That gap is not made by this plugin - a response varying on an
undeclared header is mis-served from a shared cache with or without an
ETag - but a validator amplifies it, because the cache stops guessing
and starts revalidating.

=head2 Guards run first

This is the part worth knowing before enabling it on anything private.

The check sits between a route's guards and its handler - deliberately,
and not in the C<before_dispatch> hook phase that looks like its natural
home. C<before_dispatch> runs B<ahead> of the guards, so a validator
there would answer C<304> to a request an authentication guard was about
to refuse: a user who logged out, still holding a tag from when they had
not, would send it, get a C<304>, and their browser would render the
private page it still had instead of the login redirect.

So an unauthorised request is refused exactly as it would have been
without this plugin, tag or no tag.

=head2 Method

C<GET> and C<HEAD> only. A conditional C<POST> means C<If-Match> and
optimistic concurrency, which is a different feature wearing the same
header family, and conflating the two would be a correctness bug rather
than a missing one.

A C<HEAD> answers with the same tag its C<GET> would, in both outcomes,
or the cheap probe would be useless.

=head2 What the body ETag will not touch

=over 4

=item * B<Anything but a 200.> A C<404> body is not the resource, and a
C<500> that renders identically twice must not be cached as though it
were one.

=item * B<A response that already carries an C<ETag>.> C<send_file>'s
strong validator, or this plugin's own C<< etag => sub {...} >> on the
same route, was produced by something that knew more than the bytes do.

=item * B<A body that is not an arrayref of strings.> A filehandle or a
L<Punk::SendFile::Reader> would have to be consumed to be hashed, and a
streaming or detached response has no last byte to hash at all. They
pass through untouched.

=back

C<< etag => 0 >> is the same as saying nothing. C<etag> is not an option
on a C<websocket> or C<sse> route, and those keywords refuse it where it
is written rather than at C<to_app>.

=head1 OPTIONS

None. The plugin takes no configuration - the decision is per route, as
C<etag> - and an option handed to it croaks rather than being ignored.

=head1 SEE ALSO

L<Punk>, L<Punk::Static> for the same story on files,
L<Punk::Context/send_file> for downloads, which have carried validators
all along.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
