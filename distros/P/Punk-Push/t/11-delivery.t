#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use MIME::Base64 qw/encode_base64url decode_base64url/;
use Crypt::PK::ECC;
use VAPID ();
use Punk ();
use Punk::Plugin::Push ();

BEGIN {
    plan skip_all => 'DBD::SQLite is needed to exercise the storage'
        unless eval { require DBD::SQLite; 1 };
}

# ---- a push service that never touches the network ------------------------
#
# Fetch's shape, as far as this plugin uses it: ->post returns something with
# ->get, and that yields a response with ->status.

{
    package TFake::Res;
    sub new    { my ($c, %a) = @_; bless {%a}, $c }
    sub status { $_[0]{status} }

    package TFake::Future;
    sub new { my ($c, %a) = @_; bless {%a}, $c }
    sub get {
        my ($self) = @_;
        die $self->{die} if $self->{die};
        return TFake::Res->new(status => $self->{status});
    }

    package TFake::UA;
    sub new { my ($c, %a) = @_; bless { calls => [], %a }, $c }
    sub post {
        my ($self, $url, %opt) = @_;
        push @{ $self->{calls} }, { url => $url, %opt };
        my $next = shift @{ $self->{plan} || [] };
        $next = { status => 201 } unless $next;
        return TFake::Future->new(%$next);
    }
    sub calls { @{ $_[0]{calls} } }
    sub last_call { $_[0]{calls}[-1] }
}

my ($PUB, $PRIV) = VAPID::generate_vapid_keys();
my $tmp = File::Temp->newdir;
our $DSN = "dbi:SQLite:dbname=$tmp/push.db";

{
    my $dir = Punk::Plugin::Push->shipped_dir;
    open my $fh, '<', "$dir/sqlite/deploy/push_subscriptions.sql" or die $!;
    my $sql = do { local $/; <$fh> };
    $sql =~ s/^\s*--.*$//mg;
    require DBI;
    my $dbh = DBI->connect($DSN, '', '', { RaiseError => 1, AutoCommit => 1 });
    for my $stmt (split /;/, $sql) {
        $stmt =~ s/\A\s+|\s+\z//g;
        next unless length $stmt;
        next if $stmt =~ /\A(?:BEGIN|COMMIT)\z/i;
        $dbh->do($stmt);
    }
    $dbh->disconnect;
}

our %OPTS = (subject => 'mailto:ops@example.com',
             public_key => $PUB, private_key => $PRIV,
             guard => sub { 1 });

eval <<'PERL' or die $@;
package PushSend;
use Punk;
host 'https://example.com';
database dsn => $main::DSN;
plugin 'Push' => { %main::OPTS };
1;
PERL

my $app = PushSend->punk_app;
PushSend->to_app;

# A real subscription: the receiver key has to be a genuine P-256 point, since
# the body is genuinely encrypted before the fake service ever sees it.
sub real_sub {
    my ($n, $host) = @_;
    $host ||= 'push.example.net';
    my $k = Crypt::PK::ECC->new;
    $k->generate_key('prime256v1');
    return {
        endpoint => "https://$host/p/$n",
        keys => { p256dh => encode_base64url($k->export_key_raw('public')),
                  auth   => encode_base64url(join '', map { chr rand 256 } 1..16) },
    };
}

sub fake {
    my (@plan) = @_;
    my $ua = TFake::UA->new(plan => [@plan]);
    Punk::Plugin::Push->config_for($app)->{ua} = $ua;
    return $ua;
}

# ---- what a send actually puts on the wire --------------------------------

{
    my $ua = fake({ status => 201 });
    Punk::Plugin::Push->store($app, 1, real_sub('a'));
    my ($r) = Punk::Plugin::Push->send($app, 1, { title => 'Hi', body => 'there' });

    ok($r->delivered, 'a 201 is delivered');
    is($r->status, 201, '  with the status reported');
    ok(!$r->pruned, '  and nothing pruned');

    my $call = $ua->last_call;
    is($call->{url}, 'https://push.example.net/p/a', 'posted to the endpoint');
    my $h = $call->{headers};
    like($h->{Authorization}, qr/^vapid t=\S+, k=\S+$/,
        'the RFC 8292 single-header Authorization');
    is($h->{'Content-Encoding'}, 'aes128gcm', 'aes128gcm');
    is($h->{'Content-Type'}, 'application/octet-stream', 'octet-stream');
    is($h->{TTL}, 2419200, 'the configured TTL');
    ok(!exists $h->{Urgency},
        'no Urgency header when it is normal - a header restating a default '
      . 'is noise on every request');
    ok(!exists $h->{Topic}, 'and no Topic unless one was given');

    # the body is the RFC 8188 record: 86-byte header, then the sealed record
    my $body = $call->{body};
    cmp_ok(length($body), '>', 86, 'the body is a full aes128gcm record');
    is(unpack('N', substr($body, 16, 4)), 4096, '  with the record size');
    is(unpack('C', substr($body, 20, 1)), 65,   '  and the key id length');
}

# ---- ttl, urgency and topic ------------------------------------------------

{
    my $ua = fake({ status => 201 });
    Punk::Plugin::Push->send($app, 1, { t => 1 },
        ttl => 60, urgency => 'high', topic => 'reports');
    my $h = $ua->last_call->{headers};
    is($h->{TTL}, 60,          'ttl overrides per send');
    is($h->{Urgency}, 'high',  'urgency is sent when it is not normal');
    is($h->{Topic}, 'reports', 'and a topic when given');
}

# ---- one audience per endpoint --------------------------------------------
#
# A token minted for one push service is not valid at another. Caching one
# across a fan-out is the bug that makes Firefox work and Chrome fail.

{
    Punk::Plugin::Push->store($app, 2, real_sub('b', 'push.example.net'));
    Punk::Plugin::Push->store($app, 2, real_sub('c', 'updates.other.example'));

    my $ua = fake({ status => 201 }, { status => 201 });
    my @r = Punk::Plugin::Push->send($app, 2, { t => 1 });
    is(scalar(@r), 2, 'both devices were sent to');

    my @calls = $ua->calls;
    my %aud;
    for my $c (@calls) {
        my ($t) = $c->{headers}{Authorization} =~ /t=([^,]+)/;
        require Crypt::JWT;
        my $claims = Crypt::JWT::decode_jwt(token => $t, key => \$PUB,
                                            ignore_signature => 1);
        $aud{ $c->{url} } = $claims->{aud};
    }
    is($aud{'https://push.example.net/p/b'}, 'https://push.example.net',
        'the token for one service names that service');
    is($aud{'https://updates.other.example/p/c'}, 'https://updates.other.example',
        '  and the token for the other names the other');
}

# ---- the status table ------------------------------------------------------

my %STATUS = (
    200 => 'delivered', 201 => 'delivered', 202 => 'delivered',
    400 => 'kept', 401 => 'kept', 403 => 'kept',
    404 => 'gone', 410 => 'gone',
    413 => 'kept', 429 => 'kept', 500 => 'kept', 502 => 'kept', 503 => 'kept',
);

for my $status (sort { $a <=> $b } keys %STATUS) {
    my $want = $STATUS{$status};
    my $s = real_sub("s$status");
    Punk::Plugin::Push->store($app, 50, $s);
    fake({ status => $status });
    my ($r) = Punk::Plugin::Push->send($app, 50, { t => 1 });

    if ($want eq 'delivered') {
        ok($r->delivered, "$status is delivered");
        ok(!$r->pruned,   "  and keeps the subscription");
    }
    elsif ($want eq 'gone') {
        ok(!$r->delivered, "$status is not delivered");
        ok($r->pruned,     "  and the subscription is deleted");
    }
    else {
        ok(!$r->delivered, "$status is not delivered");
        ok(!$r->pruned,
            "  and the subscription is KEPT - $status is a fact about the "
          . 'service, not the subscription');
    }
    Punk::Plugin::Push->prune($app, $s->{endpoint});
}

# ---- a transport failure is not a dead subscription -----------------------

{
    my $s = real_sub('boom');
    Punk::Plugin::Push->store($app, 60, $s);
    fake({ die => "connection refused\n" });
    my ($r) = Punk::Plugin::Push->send($app, 60, { t => 1 });
    ok(!$r->delivered, 'a transport failure is not a delivery');
    is($r->status, undef, '  with no status');
    like($r->error, qr/connection refused/, '  and the reason reported');
    ok(!$r->pruned, '  and the subscription is kept');
    is(scalar(Punk::Plugin::Push->for_user($app, 60)), 1, '  it is still there');
}

# ---- one failure does not abort the fan-out -------------------------------

{
    Punk::Plugin::Push->store($app, 70, real_sub('x1'));
    Punk::Plugin::Push->store($app, 70, real_sub('x2'));
    Punk::Plugin::Push->store($app, 70, real_sub('x3'));

    fake({ status => 201 }, { status => 410 }, { status => 201 });
    my @r = Punk::Plugin::Push->send($app, 70, { t => 1 });
    is(scalar(@r), 3, 'every device was attempted');
    is(scalar(grep { $_->delivered } @r), 2, 'two delivered');
    is(scalar(grep { $_->pruned } @r), 1, 'one was pruned mid fan-out');
    is(scalar(Punk::Plugin::Push->for_user($app, 70)), 2,
        '  and the survivors are still stored');
}

# ---- a user with no subscriptions -----------------------------------------

{
    fake();
    my @r = Punk::Plugin::Push->send($app, 999, { t => 1 });
    is(scalar(@r), 0, 'a user with no subscriptions is an empty list');
}

# ---- the size ceiling ------------------------------------------------------

{
    my $s = real_sub('big');
    fake({ status => 201 });
    local $@;
    eval { Punk::Plugin::Push->send_to($app, $s, { body => 'x' x 5000 }) };
    like($@, qr/encrypted payload is \d+ octets/,
        'an oversize payload croaks before it is sent');
    like($@, qr/Shorten the message by at least \d+/,
        '  saying by how much, which is the only actionable part');
}

# ---- the payload must be encodable ----------------------------------------

{
    my $s = real_sub('enc');
    fake({ status => 201 });
    local $@;
    eval { Punk::Plugin::Push->send_to($app, $s, { t => "caf\x{e9}" }) };
    like($@, qr/not encodable as JSON/,
        'a latin-1 byte string is refused with an explanation');
}

{
    my $s = real_sub('ok');
    fake({ status => 201 });
    my $r = Punk::Plugin::Push->send_to($app, $s, { t => "caf\x{e9}\x{263a}" });
    ok($r->delivered, 'a character string encodes and sends');
}

# ---- queue => 1 hands the send to Punk::Queue -----------------------------
#
# The helper enqueues, because it has a context to enqueue through. The class
# method always sends inline - which is what the worker running the task must
# do, or a job would enqueue itself forever.

{
    package TFake::Ctx;
    sub new { my ($c,%a)=@_; bless { jobs => [], %a }, $c }
    sub app { $_[0]{app} }
    sub enqueue { my ($s,$t,$a)=@_; push @{$s->{jobs}}, [$t,$a]; return 42 }
    sub jobs { @{ $_[0]{jobs} } }
}

{
    my $cfg = Punk::Plugin::Push->config_for($app);
    local $cfg->{queue} = 1;

    Punk::Plugin::Push->store($app, 80, real_sub('q1'));
    my $ctx = TFake::Ctx->new(app => $app);
    my $ua = fake();

    my @r = Punk::Plugin::Push->send_via($ctx, 80, { t => 1 });
    is(scalar(@r), 1, 'queue => 1 still reports one result per subscription');
    is($r[0]->queued, 42, '  carrying the job id');
    is($r[0]->status, undef, '  and no status, because nothing was sent yet');
    is(scalar($ua->calls), 0, '  nothing went on the wire');

    my ($job) = $ctx->jobs;
    is($job->[0], 'punk.push.send', 'the task name');
    ok(defined $job->[1][0], '  and the job carries the subscription id');
}

# A subscription that was never stored has no id for a worker to re-read, so
# it goes inline rather than becoming a job that cannot find its row.
{
    my $cfg = Punk::Plugin::Push->config_for($app);
    local $cfg->{queue} = 1;
    my $ctx = TFake::Ctx->new(app => $app);
    my $ua = fake({ status => 201 });
    my @r = Punk::Plugin::Push->send_via($ctx, real_sub('unstored'), { t => 1 });
    is(scalar($ctx->jobs), 0, 'an unstored subscription is not enqueued');
    ok($r[0]->delivered, '  it is sent inline');
}

# With the queue off, the helper path is the inline path.
{
    Punk::Plugin::Push->store($app, 81, real_sub('q2'));
    my $ctx = TFake::Ctx->new(app => $app);
    my $ua = fake({ status => 201 });
    my @r = Punk::Plugin::Push->send_via($ctx, 81, { t => 1 });
    is(scalar($ctx->jobs), 0, 'queue => 0 does not enqueue');
    ok($r[0]->delivered, '  it sends inline');
    is(scalar($ua->calls), 1, '  one request');
}

# ---- the send uses the worker's agent, not one of its own -----------------
#
# $c->ua is one Fetch agent per worker, bound to the same event loop that
# serves inbound requests. Building our own would get a standalone loop, and
# awaiting a future on it pumps THAT loop - stalling the worker for the whole
# round trip to the push service, which is the opposite of what this plugin
# claims.

{
    package TFake::Ctx2;
    sub new { my ($c,%a)=@_; bless { asked => 0, %a }, $c }
    sub app { $_[0]{app} }
    sub ua  { $_[0]{asked}++; $_[0]{ua} }
}

{
    my $cfg = Punk::Plugin::Push->config_for($app);
    my $ua  = TFake::UA->new(plan => [ { status => 201 } ]);

    # no $cfg->{ua} override, so the context is the only source
    delete $cfg->{ua};
    delete $cfg->{fallback_ua};

    my $ctx = TFake::Ctx2->new(app => $app, ua => $ua);
    my $r = Punk::Plugin::Push->send_to($ctx, real_sub('viactx'), { t => 1 });

    is($ctx->{asked}, 1, 'the send asked the context for its agent');
    is(scalar($ua->calls), 1, '  and posted through it');
    ok($r->delivered, '  and reported the result');

    # and an app on its own still works - a job or the CLI has no context,
    # and there is no worker loop to join there anyway
    my $fallback = TFake::UA->new(plan => [ { status => 201 } ]);
    $cfg->{ua} = $fallback;
    my $r2 = Punk::Plugin::Push->send_to($app, real_sub('viaapp'), { t => 1 });
    ok($r2->delivered, 'sending with only the application still works');
}

done_testing;
