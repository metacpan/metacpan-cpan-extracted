#!perl
use 5.008003;
use strict;
use warnings;
use FindBin ();
use IO::Socket::INET;
use Test::More;

# OpenAPI securitySchemes: server-side enforcement (extract + checker, 401 /
# 500 / OR / AND, apiKey in header/query/cookie, basic decode, per-op empty
# security disabling auth) and the client's automatic credential attachment.

plan skip_all => 'Hyperman not installed' unless eval { require Hyperman; 1 };
plan skip_all => 'Fetch not installed'    unless eval { require Fetch; 1 };
require Open::API;
require Open::API::Client;

my $SPEC = {
    openapi => '3.1.0', info => { title => 'sec', version => '1' },
    components => { securitySchemes => {
        ApiKey => { type => 'apiKey', in => 'header', name => 'X-API-Key' },
        QKey   => { type => 'apiKey', in => 'query',  name => 'api_key' },
        CKey   => { type => 'apiKey', in => 'cookie', name => 'sid' },
        Bearer => { type => 'http',   scheme => 'bearer' },
        Basic  => { type => 'http',   scheme => 'basic'  },
    } },
    security => [ { ApiKey => [] } ],           # document default
    paths => {
        '/key'    => { get => { operationId => 'keyOp',
            responses => { 200 => { description => 'ok' } } } },
        '/query'  => { get => { operationId => 'queryOp',
            security => [ { QKey => [] } ],
            responses => { 200 => { description => 'ok' } } } },
        '/cookie' => { get => { operationId => 'cookieOp',
            security => [ { CKey => [] } ],
            responses => { 200 => { description => 'ok' } } } },
        '/bearer' => { get => { operationId => 'bearerOp',
            security => [ { Bearer => [] } ],
            responses => { 200 => { description => 'ok' } } } },
        '/basic'  => { get => { operationId => 'basicOp',
            security => [ { Basic => [] } ],
            responses => { 200 => { description => 'ok' } } } },
        '/either' => { get => { operationId => 'eitherOp',
            security => [ { ApiKey => [] }, { Bearer => [] } ],   # OR
            responses => { 200 => { description => 'ok' } } } },
        '/both'   => { get => { operationId => 'bothOp',
            security => [ { ApiKey => [], Bearer => [] } ],       # AND
            responses => { 200 => { description => 'ok' } } } },
        '/open'   => { get => { operationId => 'openOp',
            security => [],                                        # disables
            responses => { 200 => { description => 'ok' } } } },
    },
};

my $port = do {
    my $s = IO::Socket::INET->new(LocalHost => '127.0.0.1', LocalPort => 0,
        Listen => 1, ReuseAddr => 1) or die $!;
    my $p = $s->sockport; close $s; $p;
};
my $pid = fork // die "fork: $!";
if (!$pid) {
    open STDERR, '>', '/dev/null';
    my $api = Open::API->new(spec => $SPEC);
    my $ok = sub {
        my ($cred, $env, $op) = @_;
        [ 200, ['Content-Type' => 'application/json'],
          ['{"user":"' . ($env->{'openapi.auth'} ? 'seen' : '?') . '"}'] ];
    };
    my %h = map { $_ => $ok }
        qw(keyOp queryOp cookieOp bearerOp basicOp eitherOp bothOp openOp);
    my $app = $api->to_app(
        handlers => \%h,
        security => {
            ApiKey => sub { $_[0] eq 'secret-key'   ? { k => 1 } : 0 },
            QKey   => sub { $_[0] eq 'qsecret'       ? { k => 1 } : 0 },
            CKey   => sub { $_[0] eq 'csecret'       ? { k => 1 } : 0 },
            Bearer => sub { $_[0] eq 'tok'           ? { u => 'a' } : 0 },
            Basic  => sub { $_[0] eq 'alice:pw'      ? { u => 'alice' } : 0 },
        },
    );
    Hyperman->run(app => $app, host => '127.0.0.1', port => $port, workers => 1);
    exit 0;
}
END { local $?; if ($pid) { kill 'TERM', $pid; waitpid $pid, 0 } }
for (1 .. 50) {
    last if IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port");
    select undef, undef, undef, 0.1;
}

my $base = "http://127.0.0.1:$port";
my $ua   = Fetch->new;

# ---- raw requests: header apiKey ------------------------------------------------
is($ua->get("$base/key")->get->status, 401, 'apiKey: missing -> 401');
is($ua->get("$base/key", headers => { 'X-API-Key' => 'wrong' })->get->status,
   401, 'apiKey: bad -> 401');
is($ua->get("$base/key", headers => { 'X-API-Key' => 'secret-key' })->get->status,
   200, 'apiKey: good -> 200');

# ---- apiKey in query and cookie -------------------------------------------------
is($ua->get("$base/query?api_key=qsecret")->get->status, 200, 'apiKey query ok');
is($ua->get("$base/query?api_key=no")->get->status,      401, 'apiKey query bad');
is($ua->get("$base/cookie", headers => { Cookie => 'sid=csecret' })->get->status,
   200, 'apiKey cookie ok');
is($ua->get("$base/cookie")->get->status, 401, 'apiKey cookie missing');

# ---- bearer + basic (base64 decoded for the checker) ----------------------------
is($ua->get("$base/bearer", headers => { Authorization => 'Bearer tok' })->get->status,
   200, 'bearer ok');
is($ua->get("$base/bearer", headers => { Authorization => 'Bearer no' })->get->status,
   401, 'bearer bad');
my $b64 = 'YWxpY2U6cHc=';   # alice:pw
is($ua->get("$base/basic", headers => { Authorization => "Basic $b64" })->get->status,
   200, 'basic decoded + accepted');

# ---- OR / AND -------------------------------------------------------------------
is($ua->get("$base/either", headers => { Authorization => 'Bearer tok' })->get->status,
   200, 'OR: second alternative satisfies');
is($ua->get("$base/either", headers => { 'X-API-Key' => 'secret-key' })->get->status,
   200, 'OR: first alternative satisfies');
is($ua->get("$base/either")->get->status, 401, 'OR: neither -> 401');
is($ua->get("$base/both",
    headers => { 'X-API-Key' => 'secret-key', Authorization => 'Bearer tok' })->get->status,
   200, 'AND: both present -> 200');
is($ua->get("$base/both", headers => { 'X-API-Key' => 'secret-key' })->get->status,
   401, 'AND: one missing -> 401');

# ---- per-op empty security disables auth ----------------------------------------
is($ua->get("$base/open")->get->status, 200, 'empty security disables auth');

# ---- checker die -> 500 ---------------------------------------------------------
{
    my $sspec = {
        openapi => '3.1.0', info => { title => 'die', version => '1' },
        components => { securitySchemes => {
            Boom => { type => 'http', scheme => 'bearer' } } },
        paths => { '/boom' => { get => { operationId => 'boomOp',
            security => [ { Boom => [] } ],
            responses => { 200 => { description => 'ok' } } } } },
    };
    my $sport = do {
        my $s = IO::Socket::INET->new(LocalHost => '127.0.0.1', LocalPort => 0,
            Listen => 1, ReuseAddr => 1) or die $!;
        my $p = $s->sockport; close $s; $p;
    };
    my $spid = fork // die "fork: $!";
    if (!$spid) {
        $pid = 0;   # do not let this child's END reap the main server
        open STDERR, '>', '/dev/null';
        my $api = Open::API->new(spec => $sspec);
        my $app = $api->to_app(
            handlers => { boomOp => sub { [200, [], ['']] } },
            security => { Boom => sub { die "checker exploded\n" } },
        );
        Hyperman->run(app => $app, host => '127.0.0.1', port => $sport, workers => 1);
        exit 0;
    }
    for (1 .. 50) {
        last if IO::Socket::INET->new(PeerAddr => "127.0.0.1:$sport");
        select undef, undef, undef, 0.1;
    }
    is($ua->get("http://127.0.0.1:$sport/boom",
        headers => { Authorization => 'Bearer x' })->get->status,
       500, 'a dying checker becomes a 500, not a crash');
    kill 'TERM', $spid; waitpid $spid, 0;
}

# ---- client auto-attaches credentials -------------------------------------------
{
    my $c = Open::API::Client->new(spec => $SPEC, base_url => $base,
        security => {
            ApiKey => 'secret-key', QKey => 'qsecret', CKey => 'csecret',
            Bearer => 'tok', Basic => [ 'alice', 'pw' ],
        });
    is($c->keyOp->get->{status},    200, 'client attaches header apiKey');
    is($c->queryOp->get->{status},  200, 'client attaches query apiKey');
    is($c->cookieOp->get->{status}, 200, 'client attaches cookie apiKey');
    is($c->bearerOp->get->{status}, 200, 'client attaches bearer token');
    is($c->basicOp->get->{status},  200, 'client builds basic auth from [user,pass]');
    is($c->bothOp->get->{status},   200, 'client satisfies an AND requirement');
}

# ---- client croaks when it cannot satisfy any requirement -----------------------
{
    my $c = Open::API::Client->new(spec => $SPEC, base_url => $base,
        security => { Bearer => 'tok' });   # no ApiKey for keyOp
    my $err;
    eval { $c->keyOp } or $err = $@;
    like($err, qr/no satisfiable security requirement/,
        'client croaks when credentials cannot satisfy the operation');
}

# ---- an apiKey-in-cookie scheme needs no explicit client credential -------------
# (the cookie jar carries a session cookie set at login) - the client must not
# croak, and the server still enforces the scheme.
{
    my $c = Open::API::Client->new(spec => $SPEC, base_url => $base);  # no security
    my ($r, $err);
    my $ok = eval { $r = $c->cookieOp->get; 1 };
    $err = $@ unless $ok;
    ok($ok, 'client does not croak on an unsupplied cookie scheme')
        or diag $err;
    is($r->{status}, 401, 'server still rejects the missing session cookie (401)');
}

# ---- to_app coverage croak ------------------------------------------------------
{
    my $api = Open::API->new(spec => $SPEC);
    my $err;
    eval { $api->to_app(handlers => { keyOp => sub { [200,[],['']] } },
                        security => {}) } or $err = $@;
    like($err, qr/requires securityScheme '\w+' but no checker/,
        'to_app croaks when a required scheme has no checker');
}

done_testing();
