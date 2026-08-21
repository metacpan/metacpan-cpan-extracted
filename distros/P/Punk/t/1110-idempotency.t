#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp ();
use File::Find ();
use Punk ();

# Punk::Plugin::Idempotency: an Idempotency-Key on an unsafe method replays
# the first response instead of executing the work again.
#
# The assertions that matter most here are the counters. "The response came
# back the same" is not the claim - the claim is that the handler DID NOT RUN,
# and that is the only way a second order does not exist.

my $dir = File::Temp->newdir;
my $ran = 0;
my $seq = 0;

{
    package Idem;
    use Punk;
    cache 'file', dir => "$dir";
    plugin 'Idempotency' => { scope => sub { $_[0]->env->{HTTP_X_USER} } };

    post '/orders' => sub {
        my ($c) = @_;
        $ran++;
        $c->header('X-From-Handler' => 'yes');
        $c->json({ order => ++$seq }, 201);
    }, { idempotent => 1 };

    put '/thing' => sub { $ran++; $_[0]->text('put') }, { idempotent => 1 };

    post '/plain' => sub { $ran++; $_[0]->text('plain') };

    post '/broken' => sub { $ran++; $_[0]->json({ oops => 1 }, 500) },
        { idempotent => 1 };
    post '/refused' => sub { $ran++; $_[0]->json({ bad => 1 }, 422) },
        { idempotent => 1 };
    post '/moved' => sub { $ran++; $_[0]->redirect('/elsewhere') },
        { idempotent => 1 };
    post '/cookie' => sub {
        my ($c) = @_;
        $ran++;
        $c->cookie(sid => 'abc');
        $c->text('with-cookie');
    }, { idempotent => 1 };

    my $guarded = under '/admin' => sub {
        my ($c) = @_;
        return $c->text('denied', 403) unless $c->env->{HTTP_X_AUTHED};
        return;
    };
    $guarded->post('/act' => sub { $ran++; $_[0]->text('acted') },
        { idempotent => 1 });
}
my $app = Idem->to_app;

sub req {
    my (%o) = @_;
    my $body = $o{body} // '';
    open my $in, '<', \$body;
    my $r = $app->({
        REQUEST_METHOD => $o{method} // 'POST',
        PATH_INFO      => $o{path},
        QUERY_STRING   => '',
        CONTENT_TYPE   => 'application/json',
        CONTENT_LENGTH => length $body,
        'psgi.input'   => $in,
        %{ $o{env} // {} },
    });
    my %h = @{ $r->[1] };
    my $b = ref $r->[2] eq 'ARRAY' ? join('', @{ $r->[2] }) : '';
    return ($r->[0], \%h, $b);
}

sub alice { (HTTP_X_USER => 'alice', HTTP_IDEMPOTENCY_KEY => $_[0]) }

# ---- the whole point ----------------------------------------------------------

{
    $ran = 0;
    my ($s1, $h1, $b1) = req(path => '/orders', body => '{"item":1}',
                             env => { alice('k1') });
    is $s1, 201, 'the first request is executed';
    is $ran, 1, '...by the handler';
    ok !exists $h1->{'Idempotency-Replayed'}, '...and is not marked a replay';

    my ($s2, $h2, $b2) = req(path => '/orders', body => '{"item":1}',
                             env => { alice('k1') });
    is $s2, 201, 'the retry gets the same status';
    is $b2, $b1, '...the same body, down to the order id';
    is $ran, 1, 'THE HANDLER DID NOT RUN - which is the only reason there is '
              . 'not a second order';
    is $h2->{'Idempotency-Replayed'}, 'true',
       '...and the replay says so, because a client that cannot tell cannot '
       . 'debug anything';
    is $h2->{'X-From-Handler'}, 'yes',
       '...while a header the handler set is still there';
}

# ---- a key belongs to an account ----------------------------------------------

{
    $ran = 0;
    my (undef, undef, $mine) = req(path => '/orders', body => '{"item":1}',
                                   env => { alice('shared-key') });
    my ($s, $h, $theirs) = req(path => '/orders', body => '{"item":1}',
        env => { HTTP_X_USER => 'bob', HTTP_IDEMPOTENCY_KEY => 'shared-key' });
    is $ran, 2, 'the same key from another account executes rather than replays';
    isnt $theirs, $mine,
       'AND BOB DOES NOT RECEIVE ALICE ORDER - the stored value is a whole '
       . 'response, so an unscoped key would be a way to read one by guessing';
    ok !exists $h->{'Idempotency-Replayed'}, '...it was a fresh execution';
}

# ---- a key belongs to a route -------------------------------------------------

{
    $ran = 0;
    req(path => '/orders', body => '{"item":1}', env => { alice('cross') });
    my ($s, undef, $b) = req(path => '/thing', method => 'PUT',
                             body => '{"item":1}', env => { alice('cross') });
    is $b, 'put', 'the same key against another route runs that route';
    is $ran, 2, '...rather than replaying the first one answer';
}

# ---- a key belongs to a request -----------------------------------------------

{
    $ran = 0;
    req(path => '/orders', body => '{"item":1}', env => { alice('fp') });
    my ($s, undef, $b) = req(path => '/orders', body => '{"item":999}',
                             env => { alice('fp') });
    is $s, 422, 'the same key with a different body is a 422';
    like $b, qr/different request/, '...saying what happened';
    is $ran, 1, '...and the handler did not run - a silent replay here would '
              . 'tell the client its second, different order had succeeded';
}

{
    # the same request, a different unrelated header: still the same request
    $ran = 0;
    req(path => '/orders', body => '{"item":1}', env => { alice('hdr') });
    my ($s, $h) = req(path => '/orders', body => '{"item":1}',
                      env => { alice('hdr'), HTTP_X_TRACE => 'abc' });
    is $s, 201, 'an unrelated header does not change the fingerprint';
    is $h->{'Idempotency-Replayed'}, 'true', '...it replays';
    is $ran, 1, '...without the handler';
}

# ---- the key is request bytes -------------------------------------------------

for my $bad ("has space", "line\nfeed", "carriage\rreturn", "nul\0byte",
             "tab\there", "../../etc/passwd\n", "\x{e9}high", '') {
    my $label = $bad eq '' ? '(empty)' : join '', map {
        $_ lt ' ' || $_ gt '~' ? sprintf('\\x%02x', ord $_) : $_
    } split //, $bad;
    my ($s) = req(path => '/orders', body => '{}',
                  env => { HTTP_X_USER => 'alice',
                           ($bad eq '' ? () : (HTTP_IDEMPOTENCY_KEY => $bad)) });
    if ($bad eq '') {
        is $s, 201, 'no key at all: the request proceeds normally';
    }
    else {
        is $s, 400, "a key containing $label is refused";
    }
}

{
    my ($ok) = req(path => '/orders', body => '{}',
                   env => { alice('x' x 255) });
    is $ok, 201, 'a 255-byte key is accepted';
    my ($no) = req(path => '/orders', body => '{}',
                   env => { alice('x' x 256) });
    is $no, 400, '...and a 256-byte one is not';
}

{
    # the traversal case, end to end: nothing outside the cache directory
    req(path => '/orders', body => '{}',
        env => { alice('../../../../tmp/punk-idem-escape') });
    ok !-e '/tmp/punk-idem-escape',
       'a key shaped like a path creates nothing outside the cache directory';
    my $outside = 0;
    File::Find::find(sub { $outside++ if -f && $File::Find::name !~ /\Q$dir\E/ },
                     "$dir");
    is $outside, 0, '...and every file the store wrote is inside it';
}

# ---- method --------------------------------------------------------------------

{
    $ran = 0;
    my ($s) = req(path => '/plain', body => '{}', env => { alice('plain') });
    is $ran, 1, 'a route that did not opt in is untouched';
    my ($s2) = req(path => '/plain', body => '{}', env => { alice('plain') });
    is $ran, 2, '...and executes every time';
}

# ---- which responses are recorded ----------------------------------------------

{
    $ran = 0;
    my ($s1) = req(path => '/broken', body => '{}', env => { alice('e1') });
    my ($s2) = req(path => '/broken', body => '{}', env => { alice('e1') });
    is $s1, 500, 'a 500 is answered';
    is $ran, 2, '...and NOT recorded: replaying it would turn one transient '
              . 'failure into a permanent one for the life of the TTL';
}

{
    $ran = 0;
    my ($s1) = req(path => '/refused', body => '{}', env => { alice('r1') });
    my ($s2, $h2) = req(path => '/refused', body => '{}', env => { alice('r1') });
    is $s2, 422, 'a 4xx from the handler IS recorded';
    is $h2->{'Idempotency-Replayed'}, 'true', '...and replayed';
    is $ran, 1, '...it is a real answer about that request';
}

{
    $ran = 0;
    my ($s1, $h1) = req(path => '/moved', body => '{}', env => { alice('m1') });
    my ($s2, $h2) = req(path => '/moved', body => '{}', env => { alice('m1') });
    is $s2, $s1, 'a redirect is replayed';
    is $h2->{Location}, $h1->{Location}, '...with its Location';
    is $ran, 1, '...and no second execution';
}

# ---- the Set-Cookie exception ---------------------------------------------------

{
    $ran = 0;
    my (undef, $h1) = req(path => '/cookie', body => '{}', env => { alice('c1') });
    ok $h1->{'Set-Cookie'}, 'the first response sets its cookie';
    my (undef, $h2) = req(path => '/cookie', body => '{}', env => { alice('c1') });
    is $h2->{'Idempotency-Replayed'}, 'true', 'the retry is a replay';
    ok !exists $h2->{'Set-Cookie'},
       '...and does NOT carry the stored Set-Cookie: that cookie is the first '
       . 'request session state, and replaying it writes back a stale one';
    is $ran, 1, '...the handler still did not run';
}

# ---- guards run first -----------------------------------------------------------

{
    $ran = 0;
    my ($ok) = req(path => '/admin/act', body => '{}',
                   env => { alice('g1'), HTTP_X_AUTHED => 1 });
    is $ok, 200, 'an authorised request is executed and recorded';

    my ($denied, $h, $b) = req(path => '/admin/act', body => '{}',
                               env => { alice('g1') });
    is $denied, 403,
       'AN UNAUTHORISED RETRY CARRYING A VALID KEY IS REFUSED BY THE GUARD - '
       . 'a replay returns a stored response BODY, so answering before the '
       . 'guard would hand it to somebody the guard was about to refuse';
    unlike $b, qr/acted/, '...and never sees the stored body';
    is $ran, 1, '...and nothing ran twice';
}

# ---- inert without the plugin -----------------------------------------------------

{
    package NoPlugin;
    use Punk;
    cache 'file', dir => "$dir";
    my $n = 0;
    post '/orders' => sub { $n++; $_[0]->text("ran $n") }, { idempotent => 1 };
}
{
    my $napp = NoPlugin->to_app;
    my @out;
    for (1 .. 2) {
        open my $in, '<', \'';
        my $r = $napp->({ REQUEST_METHOD => 'POST', PATH_INFO => '/orders',
                          QUERY_STRING => '', CONTENT_LENGTH => 0,
                          'psgi.input' => $in,
                          HTTP_IDEMPOTENCY_KEY => 'k', HTTP_X_USER => 'a' });
        push @out, join '', @{ $r->[2] };
    }
    is $out[1], 'ran 2',
       'the idempotent option is inert unless the plugin is registered';
}

# ---- what fails at boot -----------------------------------------------------------

{
    my $err = do {
        local $@;
        eval q{ package NoScope; use Punk; plugin 'Idempotency'; 1 };
        $@;
    };
    like $err, qr/`scope` is required/,
       'the plugin refuses to start without a scope';
    like $err, qr/read somebody\s+else/,
       '...and the message says why, not just what';
}

{
    my $err = do {
        local $@;
        eval q{ package BadOpt; use Punk;
                plugin 'Idempotency' => { scope => sub { 1 }, nonsense => 1 }; 1 };
        $@;
    };
    like $err, qr/unknown option 'nonsense'/, 'a mistyped option croaks';
}

{
    my $err = do {
        local $@;
        eval q{ package BadRoute; use Punk;
                post '/x' => sub { 1 }, { idempotant => 1 }; 1 };
        $@;
    };
    like $err, qr/unknown route option 'idempotant'/,
       'and so does a mistyped route option';
}

done_testing;
