package Mojolicious::Plugin::Buffer::Lock::Redis;

use strict;
use warnings;
use autodie qw(:all);

use Mojo::Base -base;

use Carp qw(croak);
use Mojo::Util qw(encode md5_sum trim);
use Mojolicious::Plugin::Buffer::I18N qw(i18n);
use Params::Get qw(get_params);
use Params::Validate::Strict qw(validate_strict);
use Readonly;
use Scalar::Util qw(blessed refaddr);
use Sub::Private { mode => 'enforce' };
use Sub::Protected;
use Time::HiRes ();

use version; our $VERSION = version->declare('0.001.0');

Readonly::Scalar my $DEFAULT_NAMESPACE => 'buffer:lock:';
Readonly::Scalar my $DEFAULT_TTL => 60;

# Redis takes PX in milliseconds; a TTL that rounds below 1ms would be
# rejected by the server, so it is clamped to this
Readonly::Scalar my $MS_PER_SECOND => 1000;
Readonly::Scalar my $MIN_TTL_MS => 1;

# Constructor arguments.  The client is checked separately, because CPAN Redis
# dispatches commands through AUTOLOAD and has no eval() for can() to find.
Readonly::Hash my %NEW_SCHEMA => (
	namespace => {type => 'string', min => 1},
	ttl => {type => 'number', matches => qr/^\d+(?:\.\d+)?$/, callback => sub { defined($_[0]) && ($_[0] > 0) }},
);

has redis     => undef;
has namespace => $DEFAULT_NAMESPACE;
has ttl       => $DEFAULT_TTL;
has messages  => undef;

# Makes each token unique within a process even within one clock tick
my $TOKEN_COUNTER = 0;

# SET NX PX is atomic, so only one worker can create the key.  The token lets
# the owner release exactly its own lock.
Readonly::Scalar my $ACQUIRE_SCRIPT => <<'LUA';
if redis.call('set', KEYS[1], ARGV[1], 'NX', 'PX', ARGV[2]) then
    return 1
end
return 0
LUA

# Compare and delete in one script, so a lock that expired and was taken by
# another worker is never removed by the previous owner.
Readonly::Scalar my $RELEASE_SCRIPT => <<'LUA';
if redis.call('get', KEYS[1]) == ARGV[1] then
    return redis.call('del', KEYS[1])
end
return 0
LUA

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Buffer::Lock::Redis - Redis-backed lock backend

=head1 VERSION

Version 0.001.0

=head1 SYNOPSIS

Workers on several machines, sharing one Redis server and one cache:

    use Mojolicious::Lite;
    use CHI;
    use Redis;
    use Mojolicious::Plugin::Buffer::Lock::Redis;

    plugin 'Buffer' => {
	cache => CHI->new(driver => 'Memcached', servers => ['cache.internal:11211']),
	cache_lock => Mojolicious::Plugin::Buffer::Lock::Redis->new(
	    # A code reference: each worker makes its own connection
	    redis => sub {
		Redis->new(
		    server        => 'redis.internal:6379',
		    cnx_timeout   => 1,
		    read_timeout  => 1,
		    write_timeout => 1,
		);
	    },
	    namespace => 'myapp:buffer:',
	    ttl       => 60,
	),
    };

The same with L<Redis::Fast>, which has the same interface:

    use Redis::Fast;

    my $lock = Mojolicious::Plugin::Buffer::Lock::Redis->new(
	redis => sub { Redis::Fast->new(server => 'redis.internal:6379') },
    );

Use it on its own, for example so that only one machine runs a job:

    my ($guard, $error) = $lock->acquire('nightly-report');
    if ($guard) {
	build_report();
	$lock->release($guard);
    } elsif (defined $error) {
	warn "Redis problem: $error\n";
    }    # else another machine is already doing it

Add a Redis Cluster hash tag by overriding the protected C<_key> method, so
every lock lands in one slot:

    package MyApp::Lock;
    use Mojo::Base 'Mojolicious::Plugin::Buffer::Lock::Redis';
    use Mojo::Util qw(encode md5_sum);

    sub _key {
	my ($self, $key) = @_;
	return '{' . $self->namespace . '}' . md5_sum(encode('UTF-8', $key));
    }

=head1 DESCRIPTION

This is a lock backend for
L<cache_lock|Mojolicious::Plugin::Buffer/cache_lock>.  It lets workers on
I<different machines> agree that only one of them builds a missing cache
entry.  The cache itself must also be shared between those workers.

=head2 How it works, in plain words

=over 4

=item 1. Each cache key is turned into a Redis key: L</namespace> followed by
the MD5 digest of the cache key.

=item 2. To take the lock, the backend writes a random I<token> into that
Redis key, but only if the key does not exist yet (Redis C<SET ... NX PX>).
Redis does this in one step, so two workers can never both succeed.

=item 3. The Redis key expires by itself after L</ttl> seconds.  So if a
worker crashes while it holds a lock, the lock disappears later on its own.

=item 4. To release the lock, a small Lua script deletes the Redis key, but
only if it still holds I<our> token.  If our lock already expired and another
worker took it, we do not delete theirs.

=back

The Redis client is called I<synchronously>: the worker waits for Redis to
answer before the request goes on.  So set short connect, read and write
timeouts on the client, and do not use a non-blocking client.  Redis 2.6.12
or newer is needed for C<SET ... NX PX>.

=head2 Words used in this document

=over 4

=item token

A random 32-character string made for each successful L</acquire>.  It
proves which worker owns a lock.

=item TTL

"Time to live": how long Redis keeps the lock before it deletes it by
itself.

=item guard

The value L</acquire> returns when you get the lock.  It holds the Redis key
and the token.  Give it back to L</release>.

=back

=head1 ATTRIBUTES

Attributes are set with L</new>, which checks them.  Each one also has an
accessor method with the same name, made by L<Mojo::Base>.  Changing a value
through the accessor after L</new> skips those checks.

=head2 redis

Required.  Either a Redis client object with the same
C<eval($script, $numkeys, @args)> method as L<Redis> and L<Redis::Fast>, or
a code reference that returns such an object.

Prefer the code reference.  It is called the first time this backend is
used in each process, so with a pre-forking server such as L<hypnotoad>
every worker gets its own connection.  A client object made in C<startup>
is copied into every worker by C<fork>, and the workers would then share
one network connection, which corrupts the replies.

=head3 API SPECIFICATION

=head4 Input

    # An object is accepted when it can('eval') or has an AUTOLOAD, as the
    # CPAN Redis client dispatches its commands through AUTOLOAD
    { redis => { type => ['coderef', 'object'], optional => 1 } }

=head4 Output

    # Return::Set schema: the value when reading, the object when writing
    { type => ['coderef', 'object'] }

=head2 namespace

The prefix for every Redis key this backend makes.  Defaults to
C<'buffer:lock:'>.  Use a different namespace for each application that
shares a Redis database.

=head3 API SPECIFICATION

=head4 Input

    { namespace => { type => 'string', min => 1, optional => 1 } }

=head4 Output

    # Return::Set schema: the value when reading, the object when writing
    { type => 'string', min => 1 }

=head2 ttl

How long a lock lives, in seconds.  Defaults to 60.  Fractions such as
C<0.5> are allowed; the value is sent to Redis in whole milliseconds, and
never less than 1 millisecond.  Choose a value longer than
L<cache_lock_timeout|Mojolicious::Plugin::Buffer/cache_lock_timeout> and
longer than your slowest cached action.

=head3 API SPECIFICATION

=head4 Input

    { ttl => { type => 'number', min => 0, optional => 1,
               matches => qr/^\d+(?:\.\d+)?$/ } }   # and > 0

=head4 Output

    # Return::Set schema: the value when reading, the object when writing
    { type => 'number' }

=head2 messages

An optional hash of message overrides.  See
L<Mojolicious::Plugin::Buffer::I18N> for the keys and the text format.

=head3 API SPECIFICATION

=head4 Input

    { messages => { type => 'hashref', optional => 1 } }

=head4 Output

    # Return::Set schema: the hash (or undef) when reading, the object
    # when writing
    { type => 'hashref', optional => 1 }

=head1 METHODS

=head2 new

    my $lock = Mojolicious::Plugin::Buffer::Lock::Redis->new(redis => sub { Redis->new });

=head3 Purpose

Create the backend and check its configuration.  No connection is made.

=head3 Arguments

=over 4

=item C<redis> (named, required)

A client object or a code reference returning one.

=item C<namespace> (named, optional)

A non-empty string, default C<'buffer:lock:'>.

=item C<ttl> (named, optional)

A positive number of seconds, default 60.

=item C<messages> (named, optional)

A hash of message overrides.

=back

=head3 Returns

The new object.

=head3 Side effects

None.

=head3 Example

    my $lock = Mojolicious::Plugin::Buffer::Lock::Redis->new(
	redis     => sub { Redis->new(server => 'redis.internal:6379') },
	namespace => 'shop:buffer:',
	ttl       => 30,
    );

=head3 API SPECIFICATION

=head4 Input

    {
	redis     => { type => ['coderef', 'object'] },   # object: eval() or AUTOLOAD
	namespace => { type => 'string', min => 1, optional => 1 },
	ttl       => { type => 'number', min => 0, optional => 1,
	               matches => qr/^\d+(?:\.\d+)?$/ },   # and > 0
	messages  => { type => 'hashref', optional => 1 },
    }

=head4 Output

    # Return::Set schema
    { type => 'object', isa => 'Mojolicious::Plugin::Buffer::Lock::Redis' }

=head3 MESSAGES

    Key                      Message                                   Resolution
    -----------------------  ----------------------------------------  -------------------------------
    redis_client_invalid     cache_lock redis must be an object with   Pass a Redis/Redis::Fast object
                             an eval() method or a code reference      or, better, a factory sub
                             returning one
    redis_namespace_invalid  cache_lock namespace must be a non-empty  Pass e.g. 'myapp:buffer:'
                             string
    redis_ttl_invalid        cache_lock ttl must be a positive number  Pass e.g. 60
                             of seconds

All three croak.

=cut

sub new {
	my ($class, @args) = @_;

	my $self = $class->SUPER::new(get_params(undef, @args) // {});

	croak $self->i18n('redis_client_invalid') unless _valid_client($self->redis);
	croak $self->i18n('redis_namespace_invalid') unless _valid($self, 'namespace');
	croak $self->i18n('redis_ttl_invalid') unless _valid($self, 'ttl');

	return $self;
}

=head2 acquire

    my ($guard, $error) = $lock->acquire($key);

=head3 Purpose

Try, without waiting, to become the only worker building C<$key>.

=head3 Arguments

=over 4

=item C<$key> (positional, required)

The cache key: any defined string, in any language, emoji included.  Only
its MD5 digest is sent to Redis.

=back

=head3 Returns

C<($guard, undef)> when the lock was acquired, C<(undef, undef)> when
another worker holds it, and C<(undef, $error)> when Redis is unavailable.
The plugin logs an error and continues without a cross-worker lock in the
last case.  Call it in list context; see L</COMMON PITFALLS>.

=head3 Side effects

Connects to Redis on first use (through the factory) and sets a key that
expires after L</ttl>.

=head3 Example

    my ($guard, $error) = $lock->acquire('buffer:0123abcd');
    $lock->release($guard) if $guard;

=head3 API SPECIFICATION

=head4 Input

    { key => { type => 'string', position => 0 } }

=head4 Output

    # Return::Set schema (list of two)
    {
	type => 'arrayref',
	schema => [
	    { type => 'hashref', optional => 1 },   # guard: {key, token}
	    { type => 'string',  optional => 1 },   # error
	],
    }

=head3 MESSAGES

    Key                 Message                                   Resolution
    ------------------  ----------------------------------------  ---------------------------
    lock_key_undefined  cache key is not defined                  Pass a defined key
    redis_lock_failed   Redis lock failed: ERROR                  Check the server and client
    redis_no_client     Redis client factory returned no client   Make the factory return one
    redis_no_result     Redis lock command returned no result     Check the client library

These are returned, not thrown.

=head3 PSEUDOCODE

    reject an undefined key
    derive the Redis key and a fresh token
    convert the TTL to milliseconds, at least 1
    run SET NX PX through the Lua script
    if the call failed, return the error
    if it returned nothing, return "no result"
    if it returned 1, return the guard
    otherwise return (undef, undef): someone else holds it

=cut

sub acquire {
	my ($self, @args) = @_;

	# get_params() confesses on an empty list; no key is a returned error
	my $key = @args ? get_params('key', @args)->{key} : undef;
	return (undef, $self->i18n('lock_key_undefined')) unless defined($key);

	my $lock_key = $self->_key($key);
	my $token = $self->_token;
	my $ttl = int($self->ttl * $MS_PER_SECOND);
	$ttl = $MIN_TTL_MS if $ttl < $MIN_TTL_MS;

	my $outcome = $self->_run_script($ACQUIRE_SCRIPT, $lock_key, $token, $ttl);
	return (undef, $self->i18n('redis_lock_failed', {error => $outcome->{error}})) if defined($outcome->{error});
	return (undef, $self->i18n('redis_no_result')) unless defined($outcome->{result});

	return $outcome->{result} ? ({key => $lock_key, token => $token}, undef) : (undef, undef);
}

=head2 release

    my ($ok, $error) = $lock->release($guard);

=head3 Purpose

Delete the lock, but only if it still holds this guard's token.

=head3 Arguments

=over 4

=item C<$guard> (positional, required)

A guard returned by L</acquire>.

=back

=head3 Returns

C<(1, undef)> on success, including when the lock had already expired, and
C<(0, $error)> on failure.  A failed release is not fatal because the lock
expires after L</ttl>.

=head3 Side effects

Deletes the Redis key if it still holds the token.

=head3 Example

    my ($ok, $error) = $lock->release($guard);
    warn $error unless $ok;

=head3 API SPECIFICATION

=head4 Input

    { guard => { type => 'hashref', position => 0 } }   # {key, token}

=head4 Output

    # Return::Set schema (list of two)
    {
	type => 'arrayref',
	schema => [
	    { type => 'boolean' },
	    { type => 'string', optional => 1 },
	],
    }

=head3 MESSAGES

    Key                  Message                       Resolution
    -------------------  ----------------------------  ------------------------------
    redis_invalid_guard  invalid lock guard            Pass the guard acquire returned
    redis_unlock_failed  Redis unlock failed: ERROR    None needed; the TTL expires it

=cut

sub release {
	my ($self, $guard) = @_;

	my $valid = (ref($guard) eq 'HASH') && defined($guard->{key}) && defined($guard->{token});
	my $outcome = $valid ? $self->_run_script($RELEASE_SCRIPT, $guard->{key}, $guard->{token}) : {};

	# An expired lock (script result 0) is still a successful release
	return !$valid ? (0, $self->i18n('redis_invalid_guard'))
		: defined($outcome->{error}) ? (0, $self->i18n('redis_unlock_failed', {error => $outcome->{error}}))
		: (1, undef);
}

# Purpose:        Run one of the Lua scripts against a single key.
# Entry criteria: $script is Lua; $key and @argv are strings.
# Exit status:    {result => $value} on success, {error => $text} when the
#                 factory returned nothing or the client died.
# Side effects:   Network round trip; may create the per-worker client.
sub _run_script :Private {
	my ($self, $script, $key, @argv) = @_;

	my $redis = eval { $self->_client };
	my $error = $@;
	$error = $self->i18n('redis_no_client') if !$error && !$redis;

	my $result = $error ? undef : eval { $redis->eval($script, 1, $key, @argv) };
	$error ||= $@;

	return $error ? {error => trim("$error")} : {result => $result};
}

# Purpose:        Return the Redis client, calling the factory once.
# Entry criteria: redis is an object or a code reference.
# Exit status:    The client, or whatever the factory returned.
# Side effects:   Caches the factory result for this object; may die if
#                 the factory dies.  Protected so a subclass can supply a
#                 pooled or sentinel-aware client.
sub _client :Protected {
	my $self = shift;

	my $redis = $self->redis;

	# Called lazily, so a pre-forking server gets one connection per worker
	return ref($redis) eq 'CODE' ? ($self->{client} //= $redis->()) : $redis;
}

# Purpose:        Map a cache key to its Redis key.
# Entry criteria: $key is a defined string.
# Exit status:    namespace followed by the MD5 of the key.
# Side effects:   None.  Protected so a subclass can add e.g. a hash tag
#                 for Redis Cluster slot placement.
sub _key :Protected {
	my ($self, $key) = @_;

	# md5_sum dies on characters above 255, so hash the UTF-8 bytes
	return $self->namespace . md5_sum(encode('UTF-8', $key));
}

# Purpose:        Produce a token that no other acquisition will share.
# Entry criteria: None.
# Exit status:    A 32-character hex string.
# Side effects:   Increments the per-process counter.
sub _token :Protected {
	my $self = shift;

	return md5_sum(join "\0", $$, Time::HiRes::time(), ++$TOKEN_COUNTER, rand(), refaddr($self));
}

# Purpose:        Check a client value without connecting.
# Entry criteria: Any scalar.
# Exit status:    True for a code reference, or an object with eval() or an
#                 AUTOLOAD that will provide it.
# Side effects:   None.
sub _valid_client :Private {
	my $redis = shift;

	return (ref($redis) eq 'CODE')
		|| (blessed($redis) && ($redis->can('eval') || $redis->can('AUTOLOAD')));
}

# Purpose:        Validate one attribute against %NEW_SCHEMA.
# Entry criteria: $self is constructed; $name is a key of %NEW_SCHEMA.
# Exit status:    True if the attribute's value is acceptable.
# Side effects:   None.
sub _valid :Private {
	my ($self, $name) = @_;

	my $value = $self->$name;
	return !ref($value) && eval { validate_strict(schema => {$name => $NEW_SCHEMA{$name}}, input => {$name => $value}); 1 };
}

1;

=head1 COMMON PITFALLS

=over 4

=item * B<Always take both return values.>  L</acquire> returns a list of
two values.  In scalar context Perl gives you only the I<last> one, the
error slot:

    my $guard = $lock->acquire($key);           # WRONG: $guard is undef
    my ($guard, $error) = $lock->acquire($key); # right

Here the mistake is costly.  The lock I<was> taken in Redis, but you have
lost the token, so you cannot release it.  Every worker then sees "busy" for
that key until the L</ttl> runs out.

=item * B<The TTL is too short.>  If the builder is still working when the
lock expires, a second worker can take the lock and build the same entry.
Make L</ttl> longer than the slowest action that uses the cache.

=item * B<A client object made before the fork.>  Pass a code reference as
L</redis>, not an object made in C<startup>.  Also, do not call L</acquire>
in C<startup>: the first call stores the client, and C<fork> would then copy
it into every worker.

=item * B<A slow Redis server slows every cached request.>  The call waits
for Redis.  Set C<cnx_timeout>, C<read_timeout> and C<write_timeout> on the
client.

=item * B<Changing attributes after C<new>.>  C<< $lock->ttl(0) >> is not
checked; Redis is then sent the smallest TTL, 1 millisecond, and the lock
protects nothing.  Set attributes with L</new> only.

=item * B<The lock is not re-entrant.>  A second C<acquire> for a key this
worker already holds returns "busy" C<(undef, undef)>.

=item * B<undef values.>  C<acquire(undef)> returns
C<(undef, 'cache key is not defined')>.  C<release(undef)> returns
C<(0, 'invalid lock guard')>.  A factory that returns C<undef> gives
C<(undef, 'Redis lock failed: Redis client factory returned no client')>,
and is asked again on the next call.  C<< new(ttl =E<gt> undef) >> and
C<< new(namespace =E<gt> undef) >> croak.

=back

=head1 ENCODING

=over 4

=item Keys

Any Perl string is safe, including accented letters, other non-ASCII text
and emoji.  The key is encoded as UTF-8 bytes and hashed, so only an ASCII
digest is sent to Redis.  A subclass that overrides C<_key> must encode
before calling C<md5_sum>, which dies on a character above U+00FF.

=item namespace

Sent to Redis as part of the key.  Keep it ASCII.  Redis keys are bytes, so
a non-ASCII namespace must be encoded to bytes by you first.

=item messages

Override texts may hold any characters, including emoji.  The messages this
module returns are Perl character strings; print them through an encoding
layer such as C<:encoding(UTF-8)>, or Perl warns "Wide character".
L<Mojo::Log> encodes to UTF-8 by itself.  The text after C<ERROR> comes from
the Redis client and is passed on unchanged.

=back

=head1 LIMITATIONS

=over 4

=item * The client is called synchronously inside a request.  A slow or
partitioned Redis server stalls that worker for as long as the client's own
timeouts allow; there is no circuit breaker.

=item * This is a single-instance lock, not Redlock.  With Redis replication,
a fail-over can lose a lock that was just set, and two builders may run.  For
a cache that is acceptable: the cost is one duplicated build, not corrupted
data.

=item * A lock that outlives L</ttl> is silently lost, and a second builder
can start.  Choose a TTL longer than the slowest cached action.

=back

=head1 SEE ALSO

L<Mojolicious::Plugin::Buffer>,
L<Mojolicious::Plugin::Buffer::Lock::File>,
L<Mojolicious::Plugin::Buffer::I18N>.

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 FORMAL SPECIFICATION

This section describes the backend in the Z notation, for readers who want
an exact model.  You do not need it to use the module.  C<store> is the part
of the Redis database that this backend uses, C<expiry> says when each of
its keys disappears, and C<now> is the current time.

    [KEY, TEXT, TOKEN, Client]

    rkey : KEY → TEXT
    ∀ k : KEY • rkey k = namespace ⁀ md5(utf8(k))

    Guard == TEXT × TOKEN

    ┌─ Redis ─────────────────────────────────────
    │ namespace : seq₁ CHAR
    │ ttl : ℝ
    │ client : Client ∪ {⊥}
    │ store : TEXT ⇸ TOKEN
    │ expiry : TEXT ⇸ ℝ
    ├─────────────────────────────────────────────
    │ ttl > 0
    │ dom expiry = dom store
    └─────────────────────────────────────────────

    ┌─ Expire ────────────────────────────────────
    │ ΔRedis
    ├─────────────────────────────────────────────
    │ store′ = { r : dom store | expiry r ≤ now } ⩤ store
    │ expiry′ = { r : dom store | expiry r ≤ now } ⩤ expiry
    └─────────────────────────────────────────────

=head2 new

    ┌─ NewRedisLock ──────────────────────────────
    │ Redis′
    │ redis? : Client ∪ (seq ARG → Client)
    │ namespace? : seq₁ CHAR ; ttl? : ℝ
    │ result! : Redis
    ├─────────────────────────────────────────────
    │ ttl? > 0
    │ namespace′ = namespace? ∧ ttl′ = ttl?
    │ client′ = ⊥ ⇐ redis? is a code reference
    │ result! = θRedis′
    └─────────────────────────────────────────────
    -- No connection is made.  Any violated predicate: croak.

=head2 acquire

C<reachable> means the client could be made and answered.  C<token> is
fresh: it differs from every token issued before.

    ┌─ AcquireRedis ──────────────────────────────
    │ ΔRedis
    │ key? : KEY ; token : TOKEN
    │ guard! : Guard ∪ {⊥} ; error! : TEXT ∪ {⊥}
    ├─────────────────────────────────────────────
    │ let r == rkey key? •
    │   reachable ∧ r ∉ dom store ⇒
    │       store′ = store ⊕ {r ↦ token}
    │       ∧ expiry′ = expiry ⊕ {r ↦ now + max(ttl, 0.001)}
    │       ∧ guard! = (r, token) ∧ error! = ⊥
    │   reachable ∧ r ∈ dom store ⇒
    │       store′ = store ∧ guard! = ⊥ ∧ error! = ⊥
    │   ¬reachable ⇒
    │       store′ = store ∧ guard! = ⊥ ∧ error! ≠ ⊥
    └─────────────────────────────────────────────

=head2 release

    ┌─ ReleaseRedis ──────────────────────────────
    │ ΔRedis
    │ guard? : Guard ∪ {⊥} ; ok! : 𝔹 ; error! : TEXT ∪ {⊥}
    ├─────────────────────────────────────────────
    │ guard? = ⊥ ⇒ store′ = store ∧ ok! = false ∧ error! ≠ ⊥
    │ guard? = (r, t) ∧ store r = t ⇒
    │     store′ = {r} ⩤ store ∧ ok! = true
    │ guard? = (r, t) ∧ (r ∉ dom store ∨ store r ≠ t) ⇒
    │     store′ = store ∧ ok! = true
    │ ¬reachable ⇒ store′ = store ∧ ok! = false ∧ error! ≠ ⊥
    └─────────────────────────────────────────────

=head1 STATE DIAGRAM

Each cache key's lock, as Redis sees it.  The numbers on the arrows are
explained below the picture.

       +-----------+            (1)              +----------------+
       |   FREE    | --------------------------> |  HELD (token)  |
       |  (key k)  | <-------------------------- |                |
       +-----------+          (2) or (3)         +----------------+
          |     ^                                    |     ^
          +-----+ (4)                                +-----+ (5), (6)

    (1) acquire(k)  [Redis answers and the key is absent]
        / SET key token NX PX ttl; returns ({key, token}, undef)
    (2) release(guard)  [the stored token matches the guard]
        / the Lua script deletes the key; returns (1, undef)
    (3) the TTL runs out
        / Redis deletes the key by itself.  If the holder is still
          building, a second worker can now start building as well.
    (4) acquire(k)  [Redis is unreachable, or the factory gave no client]
        / returns (undef, error); nothing changes
    (5) acquire(k)  [the key is present], from any worker, the holder too
        / returns (undef, undef); nothing changes
    (6) release(old guard)  [the token differs: this lock expired and
        another worker took the key]
        / nothing is deleted; returns (1, undef)

The backend object itself has one more state, for its client:

       +----------------+   first acquire() or release() in this process
       | NO CLIENT YET  |   [redis is a code reference]          +---------+
       | (after new)    | -------------------------------------> | CLIENT  |
       +----------------+   / call the factory once; keep result | READY   |
              |   ^                                              +---------+
              +---+  the factory returned undef or died
                     / the call returns (undef, error); try again next time

When L</redis> is an object rather than a code reference, the backend
starts in CLIENT READY.

The plugin's own use of these states is drawn in
L<Mojolicious::Plugin::Buffer/STATE DIAGRAM>.

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.

=cut
