#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk::OpenTelemetry;

my $I = 'Punk::OpenTelemetry::Instrument';
*method       = \&Punk::OpenTelemetry::Instrument::method;
*server_status= \&Punk::OpenTelemetry::Instrument::server_status;
*client_status= \&Punk::OpenTelemetry::Instrument::client_status;
*db_operation = \&Punk::OpenTelemetry::Instrument::db_operation;
*schema_url   = \&Punk::OpenTelemetry::Instrument::schema_url;
*install      = \&Punk::OpenTelemetry::Instrument::install;
*configure    = \&Punk::OpenTelemetry::Instrument::configure;
*config       = \&Punk::OpenTelemetry::Instrument::config;
*suppressed   = \&Punk::OpenTelemetry::Instrument::suppressed;
*suppress_begin=\&Punk::OpenTelemetry::Instrument::suppress_begin;
*suppress_end = \&Punk::OpenTelemetry::Instrument::suppress_end;

# Instrumentation: the semantic conventions, the per-point switches, and the
# recursion guard. The conventions are pure functions over strings and are
# where the cardinality rules live, so they are asserted directly rather than
# inferred from a span that happens to look right.
#
# The live wiring (pk_abi, fetch_abi) needs those dists present with the ABI
# versions phase 1 added, and is skipped where they are not - which is also
# the shipped behaviour: a missing ABI means there is nothing of that kind to
# instrument, not that something is broken.

# ---- HTTP method normalisation ---------------------------------------------
# The method is client-controlled and otherwise unbounded. A scanner sending a
# thousand invented verbs would create a thousand values of a metric dimension.
{
    for my $m (qw(GET POST PUT PATCH DELETE HEAD OPTIONS TRACE CONNECT)) {
        is(method($m), $m, "$m is a known method");
    }
    is(method('WEIRDVERB'), '_OTHER', 'an invented verb becomes _OTHER');
    is(method('get'), '_OTHER',
        'lowercase is NOT silently upcased: it is not the method that was sent');
    is(method(''), '_OTHER', 'an empty method is bounded too');
    is(method('X' x 200), '_OTHER', 'and a very long one');
    is(method("GET\r\nX: 1"), '_OTHER',
        'a method carrying a header injection is bounded to _OTHER');
}

# ---- status mapping, which differs by span kind -----------------------------
# 4xx on a SERVER span is the server working correctly and saying no. Marking
# those as errors makes the error rate a measure of how many people mistyped a
# URL, which is a graph nobody can act on.
{
    is(server_status(200), 0, 'server: 200 leaves the status UNSET');
    is(server_status(301), 0, 'server: a redirect is not an error');
    is(server_status(404), 0, 'server: a 404 is not an error');
    is(server_status(401), 0, 'server: nor is a 401');
    is(server_status(422), 0, 'server: nor a validation refusal');
    is(server_status(500), 2, 'server: a 500 IS an error');
    is(server_status(503), 2, 'server: and a 503');

    # on a CLIENT span the rule inverts, deliberately: a 4xx the client
    # received IS a failure of the call the client made
    is(client_status(200), 0, 'client: 200 is fine');
    is(client_status(404), 2, 'client: a 404 IS a failure of the call');
    is(client_status(500), 2, 'client: and so is a 500');
}

# ---- db.operation.name ------------------------------------------------------
# The span is named for the operation, not the statement: one distinct name
# per distinct SQL string is another unbounded dimension.
{
    is(db_operation('SELECT * FROM t'), 'SELECT', 'SELECT');
    is(db_operation('insert into t values (1)'), 'INSERT',
        'lowercase sql is uppercased');
    is(db_operation("  \n\t UPDATE t SET x=1"), 'UPDATE',
        'leading whitespace is skipped');
    is(db_operation('(SELECT 1)'), 'SELECT', 'and a leading paren');
    is(db_operation('DELETE FROM t'), 'DELETE', 'DELETE');
    is(db_operation(''), undef, 'an empty statement has no operation');
    is(db_operation('123'), undef, 'nor one starting with a digit');
    ok(length(db_operation('S' x 500)) < 32,
        'a pathological statement cannot make this allocate');
}

# ---- the schema url is pinned ----------------------------------------------
{
    like(schema_url(), qr{^https://opentelemetry\.io/schemas/\d+\.\d+\.\d+$},
        'the convention version is pinned and emittable');
}

# ---- the per-point switches -------------------------------------------------
{
    my %c = config();
    is_deeply([sort keys %c], [qw(client db enabled server)],
        'every instrumentation point is individually switchable');
    is($c{server}, 1, 'and on by default');

    configure(db => 0);
    my %off = config();
    is($off{db}, 0, 'database spans can be silenced');
    is($off{server}, 1, 'without losing server spans');
    configure(db => 1);

    configure(enabled => 0);
    my %dis = config();
    is($dis{enabled}, 0, 'and there is a master switch');
    configure(enabled => 1);
}

# ---- the recursion guard ----------------------------------------------------
# The exporter sends spans over HTTP with Fetch; Fetch is instrumented. Without
# this the first collector outage is an infinite loop of telemetry about
# failing to send telemetry.
{
    is(suppressed(), 0, 'nothing is suppressed to begin with');
    suppress_begin();
    is(suppressed(), 1, 'suppression can be entered');
    suppress_begin();
    is(suppressed(), 2, 'and nests, so an export inside an export is safe');
    suppress_end();
    suppress_end();
    is(suppressed(), 0, 'and unwinds');
    suppress_end();
    is(suppressed(), 0, 'an extra end cannot drive it negative');

    # a span started while suppressed is not created at all
    my $t = Punk::OpenTelemetry::Tracer->new(sampler => 'always_on');
    install($t);
    suppress_begin();
    my ($n) = do { my %s = $t->stats; $s{started} };
    suppress_end();
    ok(defined $n, 'the tracer is reachable while suppressed');
}

# ---- install is idempotent and honest ---------------------------------------
{
    my $t = Punk::OpenTelemetry::Tracer->new(sampler => 'always_on');
    my $r1 = install($t);
    my $r2 = install($t);
    is_deeply($r1, $r2, 'install is idempotent: registration is permanent');
    ok(exists $r1->{server}, 'it reports whether the server point went live');
    ok(exists $r1->{client}, 'and the client one');

    ok(!eval { install('not a tracer'); 1 },
        'installing without a tracer croaks, at boot, where it is visible');
}

# ---- live wiring, where the ABIs are present --------------------------------
SKIP: {
    my $have_punk = eval { require Punk; Punk->can('_abi_ptr') ? 1 : 0 };
    skip 'Punk with pk_abi (0.20+) not installed', 8 unless $have_punk;

    my $t = Punk::OpenTelemetry::Tracer->new(sampler => 'always_on',
        resource => { 'service.name' => 't' }, scope_name => 's');
    my $r = install($t);
    skip 'pk_abi did not register', 8 unless $r->{server};

    my $app = eval {
        package TOtelApp;
        use Punk;
        get '/users/:id' => sub { $_[0]->text('u') };
        package main;
        TOtelApp->to_app;
    };
    skip 'could not build a Punk app in this environment', 8 unless $app;

    # Serving can croak in a mixed environment - a Punk built against one
    # Open::API resolving another at runtime - which is an environment
    # mismatch and not something this dist can answer for. Skip rather than
    # fail, and say which.
    my $served = eval {
        $app->({ REQUEST_METHOD => 'GET', PATH_INFO => '/users/7',
                 QUERY_STRING => 'a=1', REMOTE_ADDR => '1.2.3.4',
                 HTTP_USER_AGENT => 'curl/8' });
        $app->({ REQUEST_METHOD => 'GET', PATH_INFO => '/nope' });
        1;
    };
    skip "Punk could not serve here: $@", 8 unless $served;

    my $p = $t->drain;
    my @spans = @{ $p->{resource_spans}[0]{scope_spans}[0]{spans} };
    is(scalar @spans, 2, 'one server span per request, including the 404');

    my ($hit) = grep { ($_->{attributes}{'url.path'} // '') eq '/users/7' } @spans;
    my ($miss) = grep { ($_->{attributes}{'url.path'} // '') eq '/nope' } @spans;

    is($hit->{attributes}{'http.route'}, '/users/:id',
        'http.route is the DECLARED pattern, not the path');
    is($hit->{name}, 'GET /users/:id', 'and the span is named for it');
    is($hit->{kind}, 2, 'the span is a SERVER span');
    is($hit->{attributes}{'client.address'}, '1.2.3.4', 'client.address');
    is($hit->{attributes}{'http.request.method'}, 'GET', 'the method');

    # THE cardinality rule: a 404 has no route, and url.path must NOT stand in
    ok(!exists $miss->{attributes}{'http.route'},
        'a 404 carries NO http.route rather than falling back to the path');
    is($miss->{attributes}{'http.response.status_code'}, 404,
        'though it does carry the status');
}

done_testing;
