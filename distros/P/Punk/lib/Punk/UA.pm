package Punk::UA;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.12';

1;

__END__

=head1 NAME

Punk::UA - the outbound HTTP agent on the context

=head1 SYNOPSIS

    package MyApp;
    use Punk;

    ua timeout => 10, headers => { 'X-Api-Key' => secret('api.key') };

    # blocking, wherever you are
    get '/sync' => sub {
        my ($c) = @_;
        my $res = $c->ua->get('https://api.example.com/thing')->get;
        $c->json({ upstream => $res->content });
    };

    # or hand the future back and let the worker serve others meanwhile
    get '/async' => sub {
        my ($c) = @_;
        $c->ua->get('https://api.example.com/thing')
          ->then(sub { $c->json({ upstream => $_[0]->content }) });
    };

    # several at once, on the one loop
    get '/fan' => sub {
        my ($c) = @_;
        my @f = map { $c->ua->get($_) } @urls;
        Fetch::Future->needs_all(@f)
            ->then(sub { $c->json([ map { $_->content } @_ ]) });
    };

=head1 DESCRIPTION

C<< $c->ua >> is a L<Fetch> user agent. There is no Punk wrapper around it: the
object you get back is a Fetch, so its own documentation is the API, and
anything Fetch can do - HTTP/2, streaming bodies, WebSockets, redirect
following, per-request timeouts - is available from a handler.

What Punk contributes is the lifetime and the loop.

=head2 One agent per worker

The agent is B<not> per request. It owns a keep-alive connection pool and its
DNS state, and building a fresh one for every request would throw both away and
pay a new TCP and TLS handshake each time, which is the opposite of the reason
to reach for Fetch. So one agent is built per worker, on first use, and every
request that worker serves shares it. C<< $c->ua >> is a lazy accessor onto
that; the context only memoises the lookup for the request it belongs to.

Nothing is built at C<to_app>. An agent constructed before the server forks
would leave every worker driving one set of sockets, so construction waits
until a worker actually asks. The pid is stored beside the agent and checked on
every use - a worker that finds a foreign one builds its own rather than
inherit the parent's connections.

=head2 On the worker's loop

Inside a L<Hyperman> worker the agent is bound to the same event loop that
serves inbound requests. Returning its future from a handler therefore parks
the request and lets the worker answer others while the call is in flight; a
handler waiting on an upstream costs no capacity.

Outside a worker - a test, a script, C<punk console> - there is no loop to
join. Fetch falls back to its own, and C<< ->get >> blocks. That is the same
degradation C<< $c->timer >> documents: slower, never broken.

Punk awaits any future-shaped return (C<then> / C<on_ready> / C<get>), and
L<Fetch::Future> is one, so nothing has to be declared for the async form to
work.

=head1 THE KEYWORD

    ua timeout => 10, agent => 'myapp/1.0';
    ua \%opts;

Options for the agent. Every key is handed to C<< Fetch->new >> as given, so
this is Fetch's own constructor surface rather than a second vocabulary for it;
see L<Fetch/new(%args)> for the full list. The event loop is supplied by Punk
and cannot be set here.

The keyword is optional. An application that never uses it still gets a default
agent the first time a handler asks for one.

=head2 More than one agent

Two upstreams rarely want the same timeout, the same default headers or the
same cookie policy. Name a second the way L<Punk/database> names a second
database - a name and an options hashref - and ask for it by name:

    ua timeout => 10;                                  # the default
    ua partner => { timeout => 2, agent => 'myapp-partner/1' };
    ua billing => { headers => { Authorization => secret('billing.token') },
                    cookie_jar => 1 };

    my $res = $c->ua('partner')->get($url)->get;

Each name gets its own agent, so they share neither a connection pool nor a set
of defaults, and each is built once per worker on first use. Every option
described here, C<cookie_jar> included, is per agent: one upstream can keep a
shared session cookie while another isolates per request.

Asking for a name that was never declared croaks, and says which name. An
undeclared B<default> is not an error - an application is entitled never to
configure one - but a typo'd name is always a mistake.

=head2 From punk.yml

C<ua> is also a C<punk.yml> block, like the other keywords that mirror one,
which is what lets an upstream timeout be deployment configuration and a token
arrive as a secret rather than a literal:

    ua:
      timeout: 10
      headers:
        X-Api-Key: { $env: API_KEY }
      partner:                          # a nested mapping names an agent
        timeout: 2
        headers:
          Authorization: { $env: PARTNER_TOKEN }

A key that is one of Fetch's own options is an option on the default agent; any
other key whose value is a mapping names one. That is why C<headers> stays an
option rather than becoming an agent called "headers".

=head1 COOKIES

C<cookie_jar> is the one option that changes the agent's lifetime, because a
jar belongs to the agent. A jar on the worker-shared agent would be shared by
every request that worker serves, and that is a cross-request data leak the
moment the cookies identify an end user rather than the application itself. So
the setting decides which agent a request gets.

=head2 Off (the default)

    ua;                     # or no ua keyword at all

One shared agent, no jar. Nothing is stored, nothing can cross.

=head2 cookie_jar => 1

    ua cookie_jar => 1;

Each request gets its own jar, so cookies cannot outlive the request that
collected them. This is a L<Fetch/clone(%overrides)> of the shared agent: the
jar is private, while the connection pool and the loop are still shared. The
isolation is not paid for with the connection.

Use this whenever the cookies belong to the end user - anything where you are
acting on behalf of whoever made the inbound request.

=head2 cookie_jar => 'shared'

    ua cookie_jar => 'shared';

One jar on the shared agent, persisting across every request that worker
serves. This is correct when the upstream authenticates B<the application
itself> and a session cookie is the point: log in once per worker, reuse the
cookie for every call.

It is spelled out in full rather than reached by passing a true value, because
for anything carrying a user's identity it is exactly the leak the other mode
exists to prevent. If you are unsure which you want, you want C<< 1 >>.

=head1 WHAT IS NOT FORWARDED

Nothing about the inbound request is copied onto an outbound one. Not headers,
not cookies, not the request id. An agent that quietly forwarded an inbound
C<Authorization> header to whatever host a handler names would be a
credential-forwarding bug waiting for the first handler that takes a URL from
user input.

Add what you want, explicitly:

    my $res = $c->ua->get($url, headers => {
        'X-Request-Id' => $c->req->header('x-request-id'),
    })->get;

or, for something every call should carry, through the keyword's C<headers>.

=head1 CONTEXT METHODS

=head2 ua

    $c->ua              # the default agent
    $c->ua('partner')   # a named one

The agent for this request: the worker's shared one, or a per-request clone of
it when a jar was asked for. Memoised per name, so naming the same agent twice
in one request gets one agent and one jar.

Croaks if the name was never declared with the L</THE KEYWORD> keyword.

=head1 SEE ALSO

L<Punk>, L<Punk::Context>, L<Fetch>, L<Fetch::Future>, L<Fetch::CookieJar>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
