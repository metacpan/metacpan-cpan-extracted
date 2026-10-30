package Punk::MCP;

use 5.010;
use strict;
use warnings;
use Punk::Plugin::MCP ();

our $VERSION = '0.01';

1;

__END__

=head1 NAME

Punk::MCP - any Punk application as a Model Context Protocol server

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    package MyApp;
    use Punk;
    use Punk::Plugin::MCP;

    plugin 'MCP' => { path => '/mcp', name => 'acme' };

    mcp tool => search_books => {
        description => 'Full-text search over the catalogue.',
        input       => { type => 'object',
                         properties => { q => { type => 'string' } },
                         required   => ['q'] },
    } => 'Books#search';

=head1 DESCRIPTION

Punk::MCP lets a Punk application answer the Model Context Protocol, so MCP
clients can call its tools, read its resources and fetch its prompts. A tool
call runs the same controller action a web route runs, so guards, validation,
models, logging and observers apply to it as they already do.

This is the documentation module of the Punk-MCP distribution. The plugin is
L<Punk::Plugin::MCP>, and the C<punk mcp> command is L<Punk::Command::Mcp>.

=head2 The example

F<example/> in the distribution is a small bookshop: web routes, and the
same actions as tools, resources and a prompt. Its C<add_book> tool runs an
action an admin guard protects on the web, so it declares that guard too
(see L</The guard rule>).

    plackup -s Hyperman example/app.psgi
    claude mcp add --transport http bookshop http://localhost:5000/mcp

    claude mcp add bookshop -- punk mcp --dir example   # over stdio

C<add_book> wants the admin key in C<X-Admin-Key>: C<BOOKSHOP_ADMIN_KEY> in
the environment, C<change-me> without it.

=head1 OPTIONS

C<plugin 'MCP' =E<gt> { ... }> takes these, and an unknown one is a boot
croak naming the ones it accepts.

=over 4

=item path

The endpoint, default C</mcp>.

=item name, title, version, description, website, icons, instructions

What C<initialize> says about the server. C<name> defaults to the
application's class and C<version> to its C<$VERSION>, else C<0>.
C<website> is an http or https URL, C<icons> a list of
C<{ src, mimeType, sizes, theme }>, and C<instructions> is the text a client
may hand its model.

=item auth, oauth, principal

Who may call. See L</Who may call>.

=item openapi, ops

Tools from an OpenAPI mount. See L</TOOLS FROM AN OPENAPI MOUNT>.

=item session, session_ttl, max_sessions

C<session> is C<0> (the default, stateless) or the name of a shared
L<Punk::Cache> store. C<session_ttl> is in seconds, default 3600.
C<max_sessions> bounds how many are made in one C<session_ttl>, default
10000. See L</Sessions>.

=item stream

C<auto> (the default), C<json> or C<always>. See L</Streaming>.

=item origins

The origins a browser client may call from. See L</Origin>.

=item page_size

How many tools, resources or prompts a list answers with before
C<nextCursor>, default 50, at most 1000.

=item max_body

The largest request body in bytes, default 1048576. A larger one is 413.

=item logging

True to advertise the C<logging> capability, so C<< $c->mcp_log >> sends.
It needs a session, or stdio.

=item timeout

The default for every declaration, in seconds. Without one a call may run
as long as its action does.

=item stdio_trust

True to skip C<auth> and C<oauth> over C<punk mcp>. See
L<Punk::Command::Mcp>.

=back

=head1 DECLARING

    mcp tool     => $name => \%spec => $target;
    mcp resource => $uri  => \%spec => $target;
    mcp prompt   => $name => \%spec => $target;

C<%spec> may be left out. C<$target> is a code ref or a
C<'Controller#method'> string, as a route's is, and the action gets a
context of its own whose C<param> holds the arguments (a tool's), the
template's variables (a resource's) or the arguments (a prompt's). The
declarations are fixed when the application compiles: none are added or
removed while it runs, so no C<listChanged> is claimed.

A tool's C<%spec>: C<title>, C<description>, C<input> and C<output> (JSON
Schemas), C<annotations> (C<title>, C<readOnlyHint>, C<destructiveHint>,
C<idempotentHint>, C<openWorldHint>), C<stream>, C<guard>, C<icons>,
C<timeout>. A name is 1 to 128 of C<A-Z a-z 0-9 _ - .>.

A resource's C<%spec>: C<name>, C<title>, C<description>, C<mime>, C<size>,
C<annotations> (C<audience>, C<priority>, C<lastModified>), C<guard>,
C<icons>, C<timeout>. A URI with C<{var}> in it is a template (level 1 of
RFC 6570: no operators). Two templates that could match one URI are a boot
croak.

A prompt's C<%spec>: C<title>, C<description>, C<arguments> (a list of
C<{ name, description, required }>), C<guard>, C<icons>, C<timeout>. A
required argument that is missing is C<-32602> before the action runs.

=head2 Template values are not to be trusted

A template's variables come from the URI the client sent. They are
decoded, never hold a raw C</>, C<?> or C<#>, and are otherwise whatever
the client chose. Treat them as you would a route's captures: look the
record up, never build a path or a query from one.

=head2 The guard rule

A tool calls its action directly, not through the route that serves it on
the web. So a declaration whose action sits behind a guarded route must say
how it is guarded, or C<to_app> croaks naming the route:

    mcp tool => delete_book => { guard => 'Auth#admin' } => 'Books#delete';
    mcp tool => list_books  => { guard => 'none' } => 'Books#list';

C<guard> takes what C<auth> takes, and C<'none'> exposes the action to
anyone past the endpoint's own C<auth>. A caller a tool's guard refuses does not see
the tool in C<tools/list>, and calling it anyway is a tool error. A
resource's or prompt's guard makes the thing look absent.

=head1 WHAT AN ACTION RETURNS

=head2 A tool

=over 4

=item * a string: one text content block

=item * undef: no content

=item * a hash with C<content>: a tool result as is, C<isError> made a
boolean

=item * any other hash: C<structuredContent>, with its JSON as text too.
With an C<output> schema it must match, and a mismatch is a tool error
whose text names what failed

=item * an array: its JSON as text

=item * a PSGI triplet (what C<< $c->json >> and C<< $c->render >> give): a
JSON object body is structured, anything else is text, a status of 400 or
more is C<isError>, and the status is in C<_meta.status>

=item * a L<Punk::Future>: awaited, then any of the above. With a
C<timeout> it races a timer, and losing is a tool error. A blocking action
cannot be interrupted

=item * a die: a tool error with the message

=back

A tool with an C<output> schema must return a hash or a triplet. Arguments
that fail C<input> are a tool error on 2025-11-25 and C<-32602> before it.

=head2 A resource

A string is one content entry: text when C<mime> is textual or the bytes
are UTF-8, else base64 C<blob>. A hash or an array is its JSON, as
C<application/json>. A hash with C<contents> is the answer as is. A triplet
gives its body, and a 404 is C<-32002>. undef is C<-32002> too, and a die
is C<-32603>.

=head2 A prompt

A string is one user message. An array of C<{ role, content }> is the
messages, and a hash with C<messages> may add a C<description>. C<role> is
C<user> or C<assistant>, and C<content> a string or a content block.

=head1 CONTEXT HELPERS

Inside a tool, resource or prompt:

=over 4

=item C<< $c->mcp >>

The call: C<method>, C<name>, C<arguments>, C<protocol>, C<progress_token>,
C<session>, C<client> and C<cancelled>.

=item C<< $c->mcp_user >>

What C<principal> returned, else C<< $c->current_user >>.

=item C<< $c->mcp_progress($done, $total, $message) >>

=item C<< $c->mcp_log($level, $data, $logger) >>

See L</Streaming>.

=item C<< $c->mcp_resource_updated($uri) >>

See L</The server stream and subscriptions>.

=back

=head1 OPENTELEMETRY

With L<Punk::Plugin::OpenTelemetry> registered, each MCP request gets a
span of its own under the request's C<POST /mcp> span, named as the
OpenTelemetry MCP conventions name it: C<tools/call search_books>,
C<prompts/get greet>, C<resources/read>. It carries C<mcp.method.name>,
C<gen_ai.tool.name> or C<gen_ai.prompt.name>, C<mcp.resource.uri>,
C<jsonrpc.request.id>, C<mcp.session.id> and C<mcp.protocol.version>. A
JSON-RPC error sets C<error.type> to its code and the status to error. A
tool error sets C<error.type> to C<tool_error> and leaves the status alone,
since the call itself worked. A request that was not sampled, a
notification and a message over stdio make none.

=head1 TOOLS FROM AN OPENAPI MOUNT

An application that already mounts an OpenAPI document gets its operations
as tools without declaring them again:

    my $api = api 'openapi.json' => { security => { bearer => $checker } };
    plugin 'MCP' => { openapi => $api };          # or '*', the spec, or the prefix
    plugin 'MCP' => { openapi => '*', ops => [qw(listBooks getBook)] };

Each operation is a tool named after its C<operationId>, lowercased, with
anything but letters, digits, C<_> and C<-> made C<_>, and C<_2> and on
when two land on one name. A tool the C<mcp> keyword declares by the same
name is a boot croak. The description is the summary and the description,
the input schema is the parameters with the request body under C<body>,
and the annotations come from the method alone. An operation marked
C<< x-mcp: false >> is left out, and C<< x-mcp: { name, title,
description, annotations } >> overrides those.

A call is a request the application answers: built from the arguments,
marked C<pmcp.inner> and C<pmcp.tool> in its env, and handed to the
application inside its own middleware. The mount's security checker, its
validation and its guards all run on it, and its answer becomes the
tool's result, a 4xx or 5xx being a tool error with the status in
C<_meta.status>. The caller's C<Authorization> goes to this mount and
nowhere else. With C<oauth>, the token was issued for the MCP endpoint,
so the mount's own checker must accept that audience, or every call is
the mount's 401. A cookie parameter is not passed.

=head1 OVER STDIO

C<punk mcp> serves the same declarations to an MCP client that launches its
servers as subprocesses:

    claude mcp add acme -- punk mcp --dir /srv/acme --token "$TOKEN"

See L<Punk::Command::Mcp>.

=head1 THE ENDPOINT

C<plugin 'MCP'> adds one route, C<POST> on C<path> (default C</mcp>). It checks,
in this order: the C<Origin> (403), that C<Accept> allows C<application/json>
(406), that the body is C<application/json> (415), the C<MCP-Protocol-Version>
header (400 when it names a version this server does not speak, and read as
C<2025-03-26> when absent), the body size against C<max_body> (413), and then
the message. Every answer is C<Cache-Control: no-store>. Other methods on the
path are 405, from Punk's router.

=head2 Streaming

A request can be answered with C<text/event-stream>: notifications first
(progress, log messages), then the response as the last event, then the
stream closes. It happens only when the client's C<Accept> lists
C<text/event-stream>, and then under C<< stream => 'auto' >> (the default)
when the tool is declared C<< stream => 1 >> or the request carries a
C<progressToken>, or under C<< stream => 'always' >> for every request.
C<< stream => 'json' >> never streams.

JSON is the default because on HTTP/1.1 a streamed answer ends the
connection, so every streamed call costs the client a reconnect.

Inside a call, C<< $c->mcp_progress($done, $total, $message) >> sends
progress against the request's token, and C<< $c->mcp_log($level, $data,
$logger) >> sends a log message at or above the level the client set with
C<logging/setLevel> (C<info> until it does). Each returns 1 when it sent
and 0 when there was nowhere to send. A progress value not above the last
one is dropped with a warning.

C<mcp_log> also writes the message to the request logger, C<< $c->log >>,
whatever level the client set and whether or not there is a client to send
to, so an action that runs as a web route as well logs there too. The
level is the nearest of Punk's: C<notice> is C<info>, C<warning> is
C<warn>, and C<critical>, C<alert> and C<emergency> are C<fatal>. A plain
hash's keys become the record's fields, a plain array is the C<data> field,
anything else is the message, and C<$logger> is the C<logger> field. C<< $c->mcp->cancelled >> turns true when
the client cancels a call that is streaming on this worker.

A streamed answer does not pass through C<after_dispatch> hooks and gets no
ETag, as any L<Punk::Stream> answer does not.

=head2 Sessions

The endpoint is stateless unless C<session> names a store:

    cache mcp => { backend => 'file', dir => '/var/cache/mcp' };
    plugin 'MCP' => { session => 'mcp' };

The store must be declared with C<cache> and shared across the worker pool
(the C<file> backend is), or C<to_app> croaks naming it. With a session:

=over 4

=item * C<initialize> answers with an C<Mcp-Session-Id>, and every later
request must carry it: none is 400, and one that is unknown, expired or
made with another credential is 404.

=item * The session keeps the negotiated protocol version, so a request
without C<MCP-Protocol-Version> uses it, and one naming another is 400.
C<logging/setLevel> applies to the session alone.

=item * A session lives C<session_ttl> seconds from its last use (the
expiry moves at most once a minute, so most requests only read).
C<DELETE> ends it with 204.

=item * C<initialize> is bounded: at most C<max_sessions> made in one
C<session_ttl> (503 with C<Retry-After> beyond it), and 30 a minute from
one address (429).

=back

Logging, resource subscriptions and anything else the server sends
unasked need a session, so without one they are not advertised.

=head2 The server stream and subscriptions

With sessions, C<GET> on the path (with C<Accept: text/event-stream> and the
session id) opens the session's server stream. A session has one: a second
C<GET> closes the first, on whichever worker held it, and C<DELETE> closes it
too.

A client subscribes with C<resources/subscribe> to a URI the application
declares (a template's match counts) and may see. When the resource changes,
say so:

    $c->mcp_resource_updated('books://7');                    # in a request
    Punk::Plugin::MCP->resource_updated('MyApp', 'books://7');  # anywhere

Every session subscribed to that URI gets
C<notifications/resources/updated> on its stream, on whichever worker
holds it: this worker's streams directly, the others over Punk's bus. Each
returns what the bus said: 1 when the pool will see it, 0 when there is no
pool (no Hyperman) and only this worker did, -1 when the URI is too long
for a bus slot (2KB), which is also warned.

=head2 Who may call

C<auth> is any Punk guard, or a list of them: a code ref, a
C<'Controller#method'> target, or a core guard such as
C<api_key_guard(scope =E<gt> 'mcp')>. Every one must pass. The same list
guards C<POST>, C<GET> and C<DELETE>, and it runs before the body is read. A
refusal goes out as the guard made it.

C<oauth> makes the endpoint an OAuth 2.1 resource server, the kind the
Claude.ai and ChatGPT connectors discover:

    host 'https://acme.test';
    plugin 'MCP' => { oauth => {
        issuer   => 'https://id.acme.test',
        jwks_url => 'https://id.acme.test/jwks',       # or key, or introspect
        scopes   => ['mcp'],
    } };

It needs L<Punk::OAuth2> 0.08 and the application's C<host>, since a
token's audience is this endpoint's URL (C<host> and C<path>), and a token
issued for any other resource is refused. C<audience> overrides it, and
may be a list. With C<introspect> the introspection answer must name the
audience. A request without a good token gets 401 with an RFC 6750
challenge naming the scopes and the C<resource_metadata> document, and
one short of a scope gets 403 C<insufficient_scope>. The claims are in
C<< $c->stash->{auth}{oauth} >>, and the RFC 9728 document is served at
C</.well-known/oauth-protected-resource> and the same with C<path> after
it. The client's token is never sent anywhere.

C<principal> runs once a request is let in, and what it returns is
C<< $c->mcp_user >> in every tool, resource and prompt. A bearer caller
has no C<< $c->current_user >>, so this is how a tool learns who called:

    principal => sub { my ($c) = @_; $c->stash->{auth}{oauth}{sub} },

=head2 Origin

A request with no C<Origin> is a client that is not a browser, and passes.
With C<origins> the C<Origin> must be one of them. Without, it must be the
server's own: the request's scheme and C<Host>. C<Origin: null> never passes.

=head2 CSRF

Punk's C<csrf> check spares a request that carries a Bearer-style
C<Authorization>, and nothing else. An application with C<csrf> on whose MCP
clients authenticate any other way gets Punk's 403 before the plugin runs.
The endpoint is not a CSRF target (it requires C<application/json>, which a
cross-site form cannot send, and it checks C<Origin>), so exempt it:

    csrf exempt => ['/mcp'];

=head2 CORS

A browser client needs the application's C<cors> to cover the path. The
plugin exposes C<Mcp-Session-Id>, C<MCP-Protocol-Version> and
C<WWW-Authenticate> on its own answers, so C<expose> need not list them. A
C<cors> C<headers> list must allow C<Authorization>, C<Content-Type>,
C<Mcp-Session-Id>, C<MCP-Protocol-Version> and C<Last-Event-ID>, and the
plugin warns at C<to_app> when one the first of C<origins> would send is
missing. With no C<headers> list Punk allows what the preflight asks for.

    cors origins => ['https://app.acme.test'];

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
