package PAGI::Middleware::Session;
$PAGI::Middleware::Session::VERSION = '0.002002';
use strict;
use warnings;
use parent 'PAGI::Middleware';
use Future::AsyncAwait;
use Digest::SHA qw(sha256_hex);
use JSON::MaybeXS;
use PAGI::Utils::Random qw(secure_random_bytes);

=head1 NAME

PAGI::Middleware::Session - Session management middleware with pluggable State/Store

=head1 SYNOPSIS

    use PAGI::Middleware::Builder;

    # Default (cookie-based, in-memory store)
    my $app = builder {
        enable 'Session', secret => 'your-secret-key';
        $my_app;
    };

    # Explicit state and store
    use PAGI::Middleware::Session::State::Header;
    use PAGI::Middleware::Session::Store::Memory;

    my $app = builder {
        enable 'Session',
            secret => 'your-secret-key',
            state  => PAGI::Middleware::Session::State::Header->new(
                header_name => 'X-Session-ID',
            ),
            store  => PAGI::Middleware::Session::Store::Memory->new;
        $my_app;
    };

    # In your app:
    async sub app {
        my ($scope, $receive, $send) = @_;

        # Raw hashref access
        my $session = $scope->{'pagi.session'};
        $session->{user_id} = 123;

        # Or use the PAGI::Session helper
        use PAGI::Session;
        my $s = PAGI::Session->new($scope);
        $s->set('user_id', 123);
        my $uid = $s->get('user_id');  # dies if key missing
    }

=head1 DESCRIPTION

PAGI::Middleware::Session provides server-side session management with a
pluggable architecture for session ID transport (State) and session data
storage (Store).

The B<State> layer controls how the session ID travels between client and
server (cookies, headers, bearer tokens, or custom logic). The B<Store>
layer controls where session data is persisted (memory, Redis, database).

By default, sessions use cookie-based IDs and in-memory storage.

B<Warning:> The default in-memory store is suitable for development and
single-process deployments only. Sessions are not shared between workers
and are lost on restart. For production multi-worker deployments, provide
a C<store> object backed by Redis, a database, or another shared storage.

=head1 CONFIGURATION

=over 4

=item * secret (required)

Secret key used for session ID generation.

=item * expire (default: 3600)

Session expiration time in seconds.

=item * state (optional)

A L<PAGI::Middleware::Session::State> object that implements C<extract($scope)>
and C<inject(\@headers, $id, \%options)>. If not provided, a
L<PAGI::Middleware::Session::State::Cookie> instance is created using
C<cookie_name>, C<cookie_options>, and C<expire>.

=item * store (optional)

A L<PAGI::Middleware::Session::Store> object that implements async C<get($id)>,
C<set($id, $data)>, and C<delete($id)>. If not provided, a
L<PAGI::Middleware::Session::Store::Memory> instance is created.

=item * cookie_name (default: 'pagi_session')

Name of the session cookie. Only used when C<state> defaults to
L<PAGI::Middleware::Session::State::Cookie>.

=item * cookie_options (default: { httponly => 1, path => '/', samesite => 'Lax' })

Options for the session cookie. Only used when C<state> defaults to
L<PAGI::Middleware::Session::State::Cookie>. For production HTTPS
deployments, add C<< secure => 1 >>.

=back

=head1 STATE CLASSES

State classes control how the session ID is extracted from requests and
injected into responses. All implement the L<PAGI::Middleware::Session::State>
interface.

=over 4

=item L<PAGI::Middleware::Session::State::Cookie>

Default. Reads the session ID from a request cookie and sets it via
C<Set-Cookie> on the response. Suitable for browser-based web applications.

=item L<PAGI::Middleware::Session::State::Header>

Reads the session ID from a custom HTTP header. Requires C<header_name>;
accepts an optional C<pattern> regex with a capture group. Injection is a
no-op (the client manages header-based transport).

    PAGI::Middleware::Session::State::Header->new(
        header_name => 'X-Session-ID',
    );

=item L<PAGI::Middleware::Session::State::Bearer>

Convenience subclass of State::Header that reads an opaque bearer token from
the C<Authorization: Bearer E<lt>tokenE<gt>> header. Intended for opaque
session tokens, B<not> JWTs. For JWT authentication, use
L<PAGI::Middleware::Auth::Bearer> instead.

    PAGI::Middleware::Session::State::Bearer->new();

=item L<PAGI::Middleware::Session::State::Callback>

Custom session ID transport using coderefs. Requires an C<extract> coderef;
accepts an optional C<inject> coderef (defaults to no-op).

    PAGI::Middleware::Session::State::Callback->new(
        extract => sub { my ($scope) = @_; ... },
        inject  => sub { my ($headers, $id, $options) = @_; ... },
    );

=back

=head1 STORE CLASSES

Store classes control where session data is persisted. All implement the
L<PAGI::Middleware::Session::Store> interface; methods return L<Future>
objects for async compatibility.

=over 4

=item L<PAGI::Middleware::Session::Store::Memory>

Default. In-memory hash storage. Not shared across workers or restarts.
Suitable for development and testing only.

=item External stores

Redis, database, and other shared stores are available as separate CPAN
distributions. Any object implementing C<get($id)>, C<set($id, $data)>,
and C<delete($id)> (returning Futures) can be used.

=back

=head1 PAGI::Session HELPER

L<PAGI::Session> is a standalone helper object that wraps the session
data with a clean accessor interface.

    use PAGI::Session;
    my $session = PAGI::Session->new($scope);

Key methods:

=over 4

=item * C<get($key)> - Dies if the key does not exist (catches typos).

=item * C<get($key, $default)> - Returns C<$default> for missing keys.

=item * C<set($key, $value)> - Sets a session value.

=item * C<exists($key)> - Checks key existence.

=item * C<delete($key)> - Removes a key.

=item * C<keys> - Lists user keys (excludes internal C<_>-prefixed keys).

=item * C<id> - Returns the session ID.

=item * C<regenerate> - Requests session ID regeneration on next response.

=item * C<destroy> - Marks the session for deletion.

=back

The helper stores a reference to the underlying hash, so mutations are
visible to the middleware.

=head1 IDEMPOTENCY

The middleware skips processing if C<< $scope-E<gt>{'pagi.session'} >>
already exists. This prevents double-initialization when the middleware
appears more than once in a stack.

For mixed auth patterns (e.g. web cookies for browsers, bearer tokens for
APIs), use L<PAGI::Middleware::Session::State::Callback> with fallback
logic instead of stacking multiple Session middleware instances:

    use PAGI::Middleware::Session::State::Callback;
    use PAGI::Middleware::Session::State::Cookie;
    use PAGI::Middleware::Session::State::Bearer;

    my $cookie_state = PAGI::Middleware::Session::State::Cookie->new(
        cookie_name => 'pagi_session',
        expire      => 3600,
    );
    my $bearer_state = PAGI::Middleware::Session::State::Bearer->new();

    enable 'Session',
        secret => $ENV{SESSION_SECRET},
        state  => PAGI::Middleware::Session::State::Callback->new(
            extract => sub {
                my ($scope) = @_;
                return $bearer_state->extract($scope)
                    // $cookie_state->extract($scope);
            },
            inject => sub {
                my ($headers, $id, $options) = @_;
                $cookie_state->inject($headers, $id, $options);
            },
        );

=head1 NON-HTTP SCOPES (WebSocket, SSE, ...)

If there is a session, WebSocket and SSE connections see it too: a scope
whose C<type> is not C<'http'> but which still carries a C<headers> key --
both a WebSocket upgrade request and an SSE request are typed this way (see
L<PAGI::Context>'s C<is_websocket>/C<is_sse>; SSE is its own distinct scope
C<type>, not C<'http'> plus a flag) -- gets a B<read-only> session: the
same C<state-E<gt>extract> + C<store-E<gt>get> lookup the C<'http'> path
uses, populating C<< $scope->{'pagi.session'} >> (and
C<< $scope->{'pagi.session_id'} >>, when a real session was found) before
calling the wrapped app. This is store-agnostic -- it works with whatever
C<store>/C<state> pair the middleware was configured with, not just
cookie-backed setups -- and scope-type-agnostic: any current or future
scope type with a C<headers> key gets the same treatment, WebSocket and SSE
are simply the two named, tested cases today.

B<Nothing is ever saved.> There is no C<http.response.start>-shaped event on
a protocol upgrade to hook a save onto, so C<< store->set >> is never called
and no transport (e.g. C<Set-Cookie>) is ever injected for one of these
scopes. Any mutation an application makes to the session hashref during a
WebSocket/SSE connection is visible for the lifetime of that connection and
then silently discarded -- it never reaches the store and is never seen
again, by this connection or any other. Establish or change session state
(login, logout, regeneration) over a regular C<'http'> request; treat a
non-http scope's session as read-only.

A session id that resolves to nothing (absent, malformed, or expired)
populates C<< $scope->{'pagi.session'} >> with an explicit empty hashref
C<{}> rather than leaving the key missing -- every C<'http'> request is
guaranteed a usable session (even a brand new, never-before-seen one falls
through to a freshly created hashref), so application code written against
that guarantee (e.g. anything that unconditionally builds a
L<PAGI::Session> from the scope) sees the same guarantee here instead of
having to special-case "no session key at all" for non-http scopes.
C<< $scope->{'pagi.session_id'} >> is left unset in this case -- there is no
real session id to report, and fabricating one for a hashref that was never
loaded from (or will ever be saved to) the store would be misleading.

A scope with no C<headers> key at all (a C<lifespan> scope, which carries
no request to extract a session id from) is passed through completely
unmodified, exactly as every scope type other than C<'http'> always was
before this feature existed.

=cut

sub _init {
    my ($self, $config) = @_;

    $self->{secret} = $config->{secret}
        // die "Session middleware requires 'secret' option";
    $self->{expire} = $config->{expire} // 3600;
    $self->{_json}  = JSON::MaybeXS->new(canonical => 1);

    # State: pluggable session ID transport
    if ($config->{state}) {
        $self->{state} = $config->{state};
    } else {
        require PAGI::Middleware::Session::State::Cookie;
        $self->{state} = PAGI::Middleware::Session::State::Cookie->new(
            cookie_name    => $config->{cookie_name} // 'pagi_session',
            cookie_options => $config->{cookie_options} // {
                httponly => 1,
                path     => '/',
                samesite => 'Lax',
            },
            expire => $self->{expire},
        );
    }

    # Store: pluggable async session storage
    if ($config->{store}) {
        $self->{store} = $config->{store};
    } else {
        require PAGI::Middleware::Session::Store::Memory;
        $self->{store} = PAGI::Middleware::Session::Store::Memory->new();
    }
}

sub wrap {
    my ($self, $app) = @_;

    return async sub  {
        my ($scope, $receive, $send) = @_;

        # Idempotency: skip if session already exists in scope. Checked
        # before the type/headers branch below, so it now applies uniformly
        # regardless of scope type -- NOT "same as it always did": before
        # the non-http read-only support this file added, a non-'http'
        # scope returned (pass-through, no session at all) before this
        # check was ever reached, so it was unreachable code for any
        # non-http scope. This move is what MAKES it apply uniformly.
        if (exists $scope->{'pagi.session'}) {
            warn "Session middleware: pagi.session already in scope, skipping\n"
                if $ENV{PAGI_DEBUG};
            await $app->($scope, $receive, $send);
            return;
        }

        if ($scope->{type} ne 'http') {
            return await $self->_wrap_non_http($scope, $receive, $send, $app);
        }

        # Extract session ID via state handler
        my $session_id = $self->{state}->extract($scope);

        # Validate and load session
        my ($session, $is_new, $snapshot) = await $self->_load_or_create_session($session_id);
        $session_id = $session->{_id};

        # Add session to scope
        my $new_scope = $self->modify_scope($scope, {
            'pagi.session'    => $session,
            'pagi.session_id' => $session_id,
        });

        # Wrap send to save session and inject state
        my $wrapped_send = async sub {
            my ($event) = @_;
            if ($event->{type} eq 'http.response.start') {
                my @headers = @{$event->{headers} // []};

                if ($session->{_destroyed}) {
                    # Destroy: delete from store, clear client state
                    await $self->{store}->delete($session_id);
                    $self->{state}->clear(\@headers);
                }
                elsif ($session->{_regenerated}) {
                    # Regenerate: new ID, delete old, save under new
                    my $old_id = $session_id;
                    $session_id = $self->_generate_session_id();
                    $session->{_id} = $session_id;
                    delete $session->{_regenerated};
                    await $self->{store}->delete($old_id);
                    my $transport = await $self->_save_session($session_id, $session);
                    $self->{state}->inject(\@headers, $transport, {});
                }
                else {
                    # Normal: save always; inject if new or the session's
                    # data changed since it was loaded (the transport for
                    # cookie-backed stores IS the data, so a stale client
                    # copy after mutation is a correctness bug, not just
                    # a missed refresh).
                    my $dirty = $is_new
                        || !defined($snapshot)
                        || $self->{_json}->encode($session) ne $snapshot;
                    my $transport = await $self->_save_session($session_id, $session);
                    if ($dirty) {
                        $self->{state}->inject(\@headers, $transport, {});
                    }
                }

                await $send->({ %$event, headers => \@headers });
                return;
            }
            await $send->($event);
        };

        await $app->($new_scope, $receive, $wrapped_send);
    };
}

# READ-ONLY session support for a non-'http' scope (websocket, sse, ...):
# store-agnostic, using the SAME state->extract + store->get path the http
# branch above uses -- never the store->set/state->inject halves, since
# there is no http.response.start-shaped channel on a protocol upgrade to
# hook a save onto. A scope with no 'headers' key at all (lifespan -- there
# is no request to extract a session id FROM) gets the original unconditional
# pass-through, preserved exactly.
#
# A found, unexpired session is loaded as-is (real 'pagi.session_id'
# included) so a consumer sees precisely what an HTTP request presenting
# the same cookie/header would have seen. A miss (no id presented, or an
# id that doesn't resolve/has expired) gets an EXPLICIT EMPTY hashref, not
# a missing key and not a freshly minted real session -- see this method's
# own POD-documented rationale: every 'http' request is guaranteed a usable
# $scope->{'pagi.session'} (even brand new, unauthenticated ones fall
# through to _load_or_create_session's own "create new" branch), so a
# consumer written against that guarantee (e.g. code that unconditionally
# calls PAGI::Session->new($scope)) must see the same guarantee here rather
# than an absent key it was never taught to check for. Fabricating a real
# session identity for a connection that presented none would be actively
# misleading, so the miss case gets {} with no '_id'/'_created' metadata,
# and 'pagi.session_id' is simply never added to scope in that case.
#
# Mutations an app makes to either the loaded or empty hashref during the
# connection are NEVER persisted anywhere: nothing here ever calls
# store->set, and there is no response event to carry a fresh transport
# even if there were. See this method's own SCOPE EXTENSIONS POD note.
async sub _wrap_non_http {
    my ($self, $scope, $receive, $send, $app) = @_;

    unless (exists $scope->{headers}) {
        await $app->($scope, $receive, $send);
        return;
    }

    my $session_id = $self->{state}->extract($scope);
    my $session;
    if (defined $session_id && length $session_id) {
        my $loaded = await $self->_get_session($session_id);
        $session = $loaded if $loaded && !$self->_is_expired($loaded);
    }
    $session //= {};

    my $new_scope = $self->modify_scope($scope, {
        'pagi.session' => $session,
        (exists $session->{_id} ? ('pagi.session_id' => $session->{_id}) : ()),
    });

    await $app->($new_scope, $receive, $send);
    return;
}

async sub _load_or_create_session {
    my ($self, $session_id) = @_;

    # Try to load existing session. The store handles validation —
    # server-side stores return undef for unknown IDs, cookie stores
    # return undef if decoding/verification fails.
    if (defined $session_id && length $session_id) {
        my $session = await $self->_get_session($session_id);
        if ($session && !$self->_is_expired($session)) {
            $session->{_last_access} = time();
            return ($session, 0, $self->{_json}->encode($session));
        }
    }

    # Create new session
    $session_id = $self->_generate_session_id();
    my $session = {
        _id          => $session_id,
        _created     => time(),
        _last_access => time(),
    };

    return ($session, 1, undef);
}

sub _generate_session_id {
    my ($self) = @_;

    # Use cryptographically secure random bytes
    my $random = unpack('H*', secure_random_bytes(16));
    my $time = time();
    return sha256_hex("$random-$time-$self->{secret}");
}

async sub _get_session {
    my ($self, $id) = @_;
    return await $self->{store}->get($id);
}

async sub _save_session {
    my ($self, $id, $session) = @_;
    return await $self->{store}->set($id, $session);
}

sub _is_expired {
    my ($self, $session) = @_;

    my $last_access = $session->{_last_access} // $session->{_created} // 0;
    return (time() - $last_access) > $self->{expire};
}

# Class method to clear all sessions (useful for testing)
sub clear_sessions {
    require PAGI::Middleware::Session::Store::Memory;
    PAGI::Middleware::Session::Store::Memory::clear_all();
}

1;

__END__

=head1 SCOPE EXTENSIONS

This middleware adds the following to C<$scope>:

=over 4

=item * pagi.session

Hashref of session data. Modify this directly to update the session,
or wrap it with L<PAGI::Session> for strict accessor methods.
Keys starting with C<_> are reserved for internal use.

=item * pagi.session_id

The session ID string. Absent (not merely undef) for a non-'http' scope
whose session id didn't resolve to anything -- see L</NON-HTTP SCOPES
(WebSocket, SSE, ...)>.

=back

This applies to a non-C<'http'> scope too, as long as it carries a
C<headers> key -- see L</NON-HTTP SCOPES (WebSocket, SSE, ...)> for the
read-only, never-saved semantics that applies there instead of the full
load/mutate/save cycle described below.

=head1 SESSION DATA

Keys starting with C<_> are B<reserved> for internal use by the session
middleware. Do not use underscore-prefixed keys for application data.

=head2 Reserved keys (read-only metadata)

=over 4

=item * C<_id> - Session ID

=item * C<_created> - Unix timestamp when session was created

=item * C<_last_access> - Unix timestamp of last access (updated each request)

=back

=head2 Reserved keys (middleware-consumed flags)

These flags are set by the application and consumed by the middleware
during response handling. They are deleted after processing.

=over 4

=item * C<_regenerated> - Set to 1 to regenerate the session ID on this
response. The old session is deleted from the store and a new ID is
issued. B<Always do this after authentication> to prevent session
fixation attacks.

=item * C<_destroyed> - Set to 1 to destroy the session entirely. The
session data is deleted from the store and the client-side state
(cookie) is cleared. Use this for logout.

=back

=head1 WHEN THE SESSION TRANSPORT IS EMITTED

On each response, the middleware saves the session unconditionally, but
only emits the transport (e.g. C<Set-Cookie>) via C<< $state->inject >>
when the session is B<new>, B<regenerated>, or its data has B<changed
since it was loaded> at the start of the request. A pure-read request
against an existing, unmodified session emits no transport.

"Changed" is determined by comparing the session's data at load time
against its data immediately before saving, regardless of how the
mutation happened: C<< $session->set(...) >>, C<< $session->data->{...}
= ... >>, or direct hashref mutation via C<< $scope->{'pagi.session'} >>
all count. This matters most for transport-is-data stores (e.g.
L<PAGI::Middleware::Session::Store::Cookie>), where a discarded transport
after a mutation would leave the client holding stale, incorrect data.

This entire section describes the C<'http'> scope path only. A non-http
scope (see L</NON-HTTP SCOPES (WebSocket, SSE, ...)>) never saves and never
emits a transport, regardless of whether its session was mutated.

=head1 SEE ALSO

L<PAGI::Session> - Standalone session helper object

L<PAGI::Middleware::Session::State> - Base class for session ID transport

L<PAGI::Middleware::Session::Store> - Base class for session storage

L<PAGI::Middleware> - Base class for middleware

L<PAGI::Middleware::Cookie> - Cookie parsing

=cut
