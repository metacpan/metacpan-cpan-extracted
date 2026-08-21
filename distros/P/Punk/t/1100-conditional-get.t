#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest;
use Punk::Test;

# Punk::Plugin::ConditionalGet, phase 1: the strong validator. The
# application names something it knows cheaply, and an unchanged resource
# answers 304 WITHOUT THE HANDLER RUNNING - which is the whole point, and
# the assertion that matters most in this file is the one counting how many
# times the handler was entered.

my $ran = 0;
my $ver = 'v1';

{
    package CG;
    use Punk;
    plugin 'ConditionalGet';

    get '/orders' => sub { $ran++; $_[0]->text('orders') },
        { etag => sub { $ver } };
    get '/quoted' => sub { $ran++; $_[0]->text('quoted') },
        { etag => sub { '"already"' } };
    get '/dunno'  => sub { $ran++; $_[0]->text('dunno') },
        { etag => sub { undef } };
    get '/boom'   => sub { $ran++; $_[0]->text('never') },
        { etag => sub { die "validator broke\n" } };
    get '/plain'  => sub { $ran++; $_[0]->text('plain') };
    any '/any'    => sub { $ran++; $_[0]->text('any') },
        { etag => sub { 'v1' } };
    get '/ctx'    => sub { $ran++; $_[0]->text('ctx') },
        { etag => sub { $_[0]->req->path eq '/ctx' ? 'ctx-v1' : 'wrong' } };
}
my $app = CG->to_app;

sub req {
    my ($path, %o) = @_;
    my $r = hit($app, path => $path, method => $o{method} // 'GET',
                env => $o{env} // {});
    my %h = @{ $r->[1] };
    my $body = ref $r->[2] eq 'ARRAY' ? join('', @{ $r->[2] }) : '';
    return ($r->[0], \%h, $body);
}

# ---- the tag on the 200, so there is something to send back ------------------

{
    $ran = 0;
    my ($st, $h, $b) = req('/orders');
    is $st, 200, 'a cold request is served';
    is $h->{ETag}, '"v1"', '...carrying the validator as a strong ETag';
    is $b, 'orders', '...with the handler output';
    is $ran, 1, '...and the handler ran';
}

# ---- the 304, and the handler that did not run ------------------------------

{
    $ran = 0;
    my ($st, $h, $b) = req('/orders', env => { HTTP_IF_NONE_MATCH => '"v1"' });
    is $st, 304, 'the same tag back is a 304';
    is $ran, 0, 'THE HANDLER DID NOT RUN - the point of the whole feature';
    is $b, '', '...and a 304 carries no body';
    is $h->{ETag}, '"v1"', '...but does carry the tag, to refresh the entry';
    ok !exists $h->{'Content-Length'},
       '...and claims no length for a body it is not sending';
}

# ---- a changed validator is a fresh response --------------------------------

{
    $ran = 0;
    $ver = 'v2';
    my ($st, $h) = req('/orders', env => { HTTP_IF_NONE_MATCH => '"v1"' });
    is $st, 200, 'a changed validator serves the resource again';
    is $h->{ETag}, '"v2"', '...with the new tag';
    is $ran, 1, '...through the handler';
    $ver = 'v1';
}

# ---- quoting is done once, so one entity has one tag ------------------------

is +(req('/quoted'))[1]->{ETag}, '"already"',
   'a validator that quoted its own tag is not quoted twice';
is +(req('/quoted', env => { HTTP_IF_NONE_MATCH => '"already"' }))[0], 304,
   '...and matches on the way back';

# ---- undef means "I do not know" --------------------------------------------

{
    $ran = 0;
    my ($st, $h) = req('/dunno', env => { HTTP_IF_NONE_MATCH => '"v1"' });
    is $st, 200, 'a validator returning undef cannot produce a 304';
    ok !exists $h->{ETag}, '...and sends no tag it would not stand behind';
    is $ran, 1, '...the handler ran normally';
}

# ---- the If-None-Match list, as RFC 9110 describes it -----------------------

is +(req('/orders', env => { HTTP_IF_NONE_MATCH => '"a", "b", "v1"' }))[0], 304,
   'a tag anywhere in the list matches';
is +(req('/orders', env => { HTTP_IF_NONE_MATCH => '*' }))[0], 304,
   'a bare * matches anything that exists';
is +(req('/orders', env => { HTTP_IF_NONE_MATCH => 'W/"v1"' }))[0], 304,
   'weak comparison: a W/ prefix on the way in still matches';
is +(req('/orders', env => { HTTP_IF_NONE_MATCH => '"v1x"' }))[0], 200,
   'a near miss is a miss';

# If-Modified-Since alone finds nothing to compare against - this half has no
# Last-Modified to offer - so the request proceeds rather than guessing.
is +(req('/orders', env => { HTTP_IF_MODIFIED_SINCE =>
        'Wed, 20 Aug 2036 00:00:00 GMT' }))[0], 200,
   'a date alone cannot produce a 304 from a validator that is not a date';

# ---- method ------------------------------------------------------------------

{
    $ran = 0;
    my ($st, $h, $b) = req('/orders', method => 'HEAD',
                           env => { HTTP_IF_NONE_MATCH => '"v1"' });
    is $st, 304, 'HEAD gets the 304 too';
    is $ran, 0, '...without running the handler';

    my ($st2, $h2) = req('/orders', method => 'HEAD');
    is $st2, 200, 'and an unconditional HEAD is a 200';
    is $h2->{ETag}, '"v1"',
       '...carrying the same tag a GET would, or the cheap probe is useless';
}

{
    $ran = 0;
    my ($st, undef, $b) = req('/any', method => 'POST',
                              env => { HTTP_IF_NONE_MATCH => '"v1"' });
    is $st, 200, 'a conditional POST is not a 304 - that is If-Match, elsewhere';
    is $b, 'any', '...the handler answered';
    is $ran, 1, '...having actually run';
}

# ---- the validator is application code --------------------------------------

{
    $ran = 0;
    my ($st, undef, $b) = req('/boom');
    is $st, 500, 'a croaking validator is the app 500';
    like $b, qr/validator broke/, '...naming what went wrong';
    is $ran, 0, '...and the handler did not run behind it';
}

is +(req('/ctx'))[1]->{ETag}, '"ctx-v1"',
   'the validator receives the context';

# ---- a route that said nothing is untouched ---------------------------------

{
    my ($st, $h) = req('/plain');
    is $st, 200, 'a route without the option still serves';
    ok !exists $h->{ETag}, '...and gets no tag';
    is +(req('/plain', env => { HTTP_IF_NONE_MATCH => '*' }))[0], 200,
       '...and cannot be 304ed by a client that asks for it';
}

# ---- guards run FIRST, which is the security half ---------------------------
#
# before_dispatch runs ahead of a route's guards, so a validator there would
# answer 304 to a request an authentication guard was about to refuse: a user
# who logged out, still holding a tag from when they had not, would get a 304
# and their browser would render the private page it still had. The check
# lives after the guards for exactly this.

my $guard_ran = 0;
my $secret_ran = 0;
{
    package Guarded;
    use Punk;
    plugin 'ConditionalGet';
    my $admin = under '/admin' => sub {
        $guard_ran++;
        my ($c) = @_;
        return $c->text('denied', 403) unless $c->env->{HTTP_X_AUTHED};
        return;
    };
    $admin->get('/secret' => sub { $secret_ran++; $_[0]->text('secret') },
        { etag => sub { 'admin-v1' } });
}
my $gapp = Guarded->to_app;

{
    my $r = hit($gapp, path => '/admin/secret',
                env => { HTTP_IF_NONE_MATCH => '"admin-v1"' });
    is $r->[0], 403,
       'a guard still refuses a request holding a matching tag - NOT a 304';
    is $secret_ran, 0, '...and the handler did not run either way';

    my $ok = hit($gapp, path => '/admin/secret',
                 env => { HTTP_X_AUTHED => 1, HTTP_IF_NONE_MATCH => '"admin-v1"' });
    is $ok->[0], 304, 'an authorised request with the tag does get its 304';
    is $secret_ran, 0, '...still without the handler';
    ok $guard_ran >= 2, 'the guard ran on both';
}

# ---- what a 304 must not eat -------------------------------------------------
#
# The handler is skipped; nothing else is. A 304 goes back through the same
# finishing path as any response, so the session write-back still runs - and
# flash, which is consumed lazily on first read, is left alone by a request
# whose handler never read it.

{
    package Stateful;
    use Punk;
    plugin 'ConditionalGet';
    session secret => 'conditional-get-test-key';

    get '/set' => sub {
        my ($c) = @_;
        $c->session->{seen} = 'yes';
        $c->flash(notice => 'Saved.');
        $c->text('set');
    };
    get '/board' => sub {
        my ($c) = @_;
        $c->text('board');
    }, { etag => sub { 'board-v1' } };
    get '/read' => sub {
        my ($c) = @_;
        $c->text(($c->flash('notice') // '-') . '/' .
                 ($c->session->{seen} // '-'));
    };
}

{
    my $t = Punk::Test->new('Stateful');
    $t->get_ok('/set')->content_is('set');

    # the tag, then the 304 in between
    $t->get_ok('/board')->status_is(200)->header_is(ETag => '"board-v1"');
    $t->get_ok('/board', headers => { 'If-None-Match' => '"board-v1"' })
      ->status_is(304, 'the intervening request is a 304');

    $t->get_ok('/read')->content_is('Saved./yes',
        'the flash survived the 304, and so did the session');
    $t->get_ok('/read')->content_is('-/yes',
        'and the read consumed it, so the 304 was not what kept it alive');
}

# ---- inert without the plugin ------------------------------------------------

{
    package NoPlugin;
    use Punk;
    get '/orders' => sub { $_[0]->text('orders') }, { etag => sub { 'v1' } };
}
{
    my $napp = NoPlugin->to_app;
    my $r = hit($napp, path => '/orders', env => { HTTP_IF_NONE_MATCH => '*' });
    is $r->[0], 200, 'the etag option is inert unless the plugin is registered';
    my %h = @{ $r->[1] };
    ok !exists $h{ETag}, '...and sends no tag';
}

# ---- what fails at boot ------------------------------------------------------

{
    my $err = do {
        local $@;
        eval q{ package BadEtag; use Punk;
                get '/x' => sub { 1 }, { etag => [] }; 1 };
        $@;
    };
    like $err, qr/takes a coderef .* or 1/,
       'etag takes a coderef or 1, and says so';
    like $err, qr{GET /x}, '...naming the route';
}

{
    # the sse keyword has its own closed option list and refuses it there,
    # which is the message a user writing `sse` actually meets
    my $err = do {
        local $@;
        eval q{ package StreamEtag; use Punk;
                sse '/feed' => sub { 1 }, { etag => 1 }; 1 };
        $@;
    };
    like $err, qr/unknown sse option/,
       'etag is not an sse option, and sse says so itself';
}

{
    my $err = do {
        local $@;
        eval q{ package WsEtag; use Punk;
                websocket '/chat' => sub { 1 }, { etag => 1 }; 1 };
        $@;
    };
    like $err, qr/unknown websocket option/,
       'nor a websocket option - a stream has no entity to validate, and both '
       . 'keywords refuse it at the point of writing rather than at to_app';
}

{
    my $err = do {
        local $@;
        eval q{ package BadOpt; use Punk;
                get '/x' => sub { 1 }, { etagg => sub { 1 } }; 1 };
        $@;
    };
    like $err, qr/unknown route option 'etagg'/,
       'a mistyped option still croaks at boot';
}

{
    my $err = do {
        local $@;
        eval q{ package BadPlugin; use Punk;
                plugin 'ConditionalGet' => { ttl => 60 }; 1 };
        $@;
    };
    like $err, qr/unknown option 'ttl'/,
       'the plugin has nothing to configure, and says so';
}

# ---- phase 2: the body ETag --------------------------------------------------
#
# etag => 1 hashes the rendered bytes. It saves the wire and the client's
# parse; it saves the server nothing, because the response was produced
# before it could be hashed. The tests that matter are the ones about which
# bodies it refuses to touch.

my $bran = 0;
my $bodyv = 'one';
{
    package Body;
    use Punk;
    plugin 'ConditionalGet';

    get '/page'   => sub { $bran++; $_[0]->text($bodyv) },    { etag => 1 };
    get '/split'  => sub { $bran++; [ 200, [ 'Content-Type' => 'text/plain' ],
                                     [ 'one', 'two', 'three' ] ] },
        { etag => 1 };
    get '/whole'  => sub { $bran++; [ 200, [ 'Content-Type' => 'text/plain' ],
                                     [ 'onetwothree' ] ] },
        { etag => 1 };
    get '/boom2'  => sub { $bran++; die "handler broke\n" },  { etag => 1 };
    get '/missing'=> sub { $bran++; $_[0]->not_found },       { etag => 1 };
    get '/off'    => sub { $bran++; $_[0]->text('off') },     { etag => 0 };
    get '/both'   => sub { $bran++; $_[0]->text('both') },
        { etag => sub { 'strong-v1' } };
    get '/cookie' => sub {
        my ($c) = @_;
        $bran++;
        $c->cookie(seen => 'yes');
        $c->text('cookie');
    }, { etag => 1 };
}
my $bapp = Body->to_app;

sub breq {
    my ($path, %o) = @_;
    my $r = hit($bapp, path => $path, method => $o{method} // 'GET',
                env => $o{env} // {});
    my %h = @{ $r->[1] };
    my $body = ref $r->[2] eq 'ARRAY' ? join('', @{ $r->[2] }) : '';
    return ($r->[0], \%h, $body);
}

{
    $bran = 0;
    my ($st, $h, $b) = breq('/page');
    is $st, 200, 'a body-ETag route serves';
    like $h->{ETag}, qr/^W\/"[0-9a-f]{16}"$/,
       '...with a weak tag - nothing here can promise byte-equality across a '
       . 'Vary axis it does not control';
    is $b, 'one', '...and the body';

    my ($st2, $h2, $b2) = breq('/page', env => { HTTP_IF_NONE_MATCH => $h->{ETag} });
    is $st2, 304, 'an identical render is a 304';
    is $b2, '', '...with no body';
    is $h2->{ETag}, $h->{ETag}, '...and the tag';
    ok !exists $h2->{'Content-Length'}, '...and no length for the missing body';
    ok !exists $h2->{'Content-Type'},
       '...and no type: a 304 describes the resource, not a representation';
    is $bran, 2, 'the handler ran BOTH times - this half never saves the server';
}

{
    $bodyv = 'two';
    my ($st, $h) = breq('/page', env => { HTTP_IF_NONE_MATCH =>
        (breq('/page'))[1]->{ETag} });
    $bodyv = 'one';
    is $st, 304, 'the tag follows the bytes';
}

{
    my (undef, $h1) = breq('/split');
    my (undef, $h2) = breq('/whole');
    is $h1->{ETag}, $h2->{ETag},
       'the body is hashed as one stream, so how the handler split it does '
       . 'not change the tag';
}

{
    my ($st, $h) = breq('/missing');
    is $st, 404, 'an error response still answers';
    ok !exists $h->{ETag},
       '...and carries no ETag: a 404 body is not the resource';
}

{
    my ($st, $h) = breq('/boom2');
    is $st, 500, 'a croaking handler is still a 500';
    ok !exists $h->{ETag}, '...with no tag over the error page';
}

{
    my ($st, $h) = breq('/off', env => { HTTP_IF_NONE_MATCH => '*' });
    is $st, 200, 'etag => 0 is the same as saying nothing';
    ok !exists $h->{ETag}, '...no tag';
}

{
    # the strong validator already tagged it; the body hash must not replace
    # a validator produced by something that knew more than the bytes
    my (undef, $h) = breq('/both');
    is $h->{ETag}, '"strong-v1"',
       'a response that already carries a tag keeps it';
}

{
    $bran = 0;
    my ($st, $h) = breq('/page', method => 'HEAD');
    my (undef, $g) = breq('/page');
    is $h->{ETag}, $g->{ETag},
       'HEAD produces the same tag as GET - the body is hashed before it is '
       . 'blanked';
    is +(breq('/page', method => 'HEAD',
              env => { HTTP_IF_NONE_MATCH => $g->{ETag} }))[0], 304,
       '...and a conditional HEAD gets its 304';
}

{
    # the hook runs last, after the session write-back, so the 304 must keep
    # what the response had gathered rather than building a fresh header set
    my (undef, $h) = breq('/cookie');
    ok $h->{'Set-Cookie'}, 'the 200 sets its cookie';
    my (undef, $h2) = breq('/cookie', env => { HTTP_IF_NONE_MATCH => $h->{ETag} });
    ok $h2->{'Set-Cookie'},
       'and the 304 still carries it - a 304 that dropped a Set-Cookie the '
       . 'write-back had just added would log the user out';
}

{
    # a send_file response is a filehandle and already has a strong validator
    package Sent;
    use Punk;
    plugin 'ConditionalGet';
    get '/file' => sub {
        $_[0]->send_file(__FILE__, type => 'text/plain');
    }, { etag => 1 };
}
{
    my $sapp = Sent->to_app;
    my $r = hit($sapp, path => '/file');
    my %h = @{ $r->[1] };
    is $r->[0], 200, 'a send_file response through a body-ETag route serves';
    like $h{ETag}, qr/^"[0-9a-f]+-[0-9a-f]+"$/,
       '...keeping send_file own strong validator, not a weak hash of it';
    isnt ref $r->[2], 'ARRAY',
       '...and its filehandle body was not consumed to hash it';
}

# ---- phase 3: the 304 as an HTTP message ------------------------------------
#
# A 304 is a response whose correctness is mostly about what is ABSENT.
# Getting it wrong gives the worst failure this feature has - a client
# waiting for a body that will never arrive, or a cache holding an entry it
# can never validate again - and neither is caught by asserting the status.

{
    package Decorated;
    use Punk;
    plugin 'ConditionalGet';

    # a hook that runs before the check, the way a real app sets policy
    hook before_dispatch => sub {
        my ($c) = @_;
        $c->header('Cache-Control' => 'private, max-age=30');
        $c->header(Vary => 'Accept-Encoding');
        return;
    };

    get '/strong' => sub { $_[0]->text('strong') },
        { etag => sub { 'dv1' } };
    get '/weak'   => sub {
        my ($c) = @_;
        $c->header('X-From-Handler' => 'yes');
        $c->text('weak');
    }, { etag => 1 };
}
my $dapp = Decorated->to_app;

sub dreq {
    my ($path, %o) = @_;
    my $r = hit($dapp, path => $path, method => $o{method} // 'GET',
                env => $o{env} // {});
    my %h = @{ $r->[1] };
    return ($r->[0], \%h, ref $r->[2] eq 'ARRAY' ? join('', @{ $r->[2] }) : '');
}

{
    my ($st, $h) = dreq('/strong', env => { HTTP_IF_NONE_MATCH => '"dv1"' });
    is $st, 304, 'the strong half answers';
    is $h->{'Cache-Control'}, 'private, max-age=30',
       '...carrying the Cache-Control the 200 would have had - without it the '
       . 'stored copy keeps a lifetime that has just run out';
    is $h->{Vary}, 'Accept-Encoding', '...and the Vary';
    is $h->{ETag}, '"dv1"', '...and the tag';
    is scalar(grep { $_ eq 'ETag' } @{[ %$h ]}), 1, '...exactly one ETag';
}

{
    my (undef, $h200) = dreq('/weak');
    my ($st, $h) = dreq('/weak', env => { HTTP_IF_NONE_MATCH => $h200->{ETag} });
    is $st, 304, 'and so does the body half';
    is $h->{'Cache-Control'}, 'private, max-age=30', '...with the same policy';
    is $h->{'X-From-Handler'}, 'yes',
       '...and a header the handler set, since the handler did run';
}

# the absences, on both
for my $case ([ '/strong', '"dv1"' ], [ '/weak', undef ]) {
    my ($path, $tag) = @$case;
    $tag //= (dreq($path))[1]->{ETag};
    my ($st, $h, $b) = dreq($path, env => { HTTP_IF_NONE_MATCH => $tag });
    is $st, 304, "$path: 304";
    ok !exists $h->{'Content-Length'}, "$path: no Content-Length on a 304";
    ok !exists $h->{'Content-Type'},   "$path: no Content-Type";
    ok !exists $h->{'Content-Encoding'}, "$path: no Content-Encoding";
    is $b, '', "$path: no body";
}

# ---- the framework has one answer, not three --------------------------------
#
# punk_sendfile.h produces a 304 for files, and this plugin produces one for
# routes. Two answers to "what does a 304 look like" inside one framework is
# a bug waiting for somebody to compare them, so this compares them.

{
    package Both;
    use Punk;
    plugin 'ConditionalGet';
    # The policy is set BEFORE the handler on purpose: the strong validator
    # answers without running one, so a Cache-Control written inside the
    # handler was never written at all. See the test below.
    hook before_dispatch => sub {
        $_[0]->header('Cache-Control' => 'private, max-age=30');
        return;
    };
    get '/file' => sub {
        $_[0]->send_file(__FILE__, type => 'text/plain',
                         etag => 'file-v1',
                         cache_control => 'private, max-age=30');
    };
    get '/route' => sub { $_[0]->text('route') },
        { etag => sub { 'route-v1' } };
}
{
    my $bothapp = Both->to_app;
    my %got;
    for my $case ([ file => '/file', '"file-v1"' ],
                  [ route => '/route', '"route-v1"' ]) {
        my ($name, $path, $tag) = @$case;
        my $r = hit($bothapp, path => $path,
                    env => { HTTP_IF_NONE_MATCH => $tag });
        my %h = @{ $r->[1] };
        is $r->[0], 304, "$name: 304";
        $got{$name} = \%h;
    }
    for my $name (qw(file route)) {
        ok exists $got{$name}{ETag}, "$name: a 304 carries its ETag";
        is $got{$name}{'Cache-Control'}, 'private, max-age=30',
           "$name: ...and the freshness lifetime the 200 would have carried";
        ok !exists $got{$name}{'Content-Length'},
           "$name: ...and claims no length";
        ok !exists $got{$name}{'Content-Type'},
           "$name: ...and describes no representation";
    }
}

# ---- the limit that falls out of answering early ----------------------------

{
    package LateHeader;
    use Punk;
    plugin 'ConditionalGet';
    get '/late' => sub {
        my ($c) = @_;
        $c->header('X-Late' => 'yes');
        $c->text('late');
    }, { etag => sub { 'late-v1' } };
}
{
    my $lapp = LateHeader->to_app;
    my $r200 = hit($lapp, path => '/late');
    my %h200 = @{ $r200->[1] };
    is $h200{'X-Late'}, 'yes', 'the 200 has the header its handler set';

    my $r = hit($lapp, path => '/late',
                env => { HTTP_IF_NONE_MATCH => '"late-v1"' });
    my %h = @{ $r->[1] };
    is $r->[0], 304, 'the 304 answers';
    ok !exists $h{'X-Late'},
       'a header set INSIDE the handler is not on the strong half 304 - the '
       . 'handler never ran, so it was never set. Policy that must survive a '
       . '304 belongs in a hook.';
}

# ---- precedence, once more, on both halves ----------------------------------

is +(dreq('/strong', env => { HTTP_IF_NONE_MATCH => '"wrong"',
        HTTP_IF_MODIFIED_SINCE => 'Wed, 20 Aug 2036 00:00:00 GMT' }))[0], 200,
   'If-None-Match wins: a mismatched tag is not rescued by a future date';

is +(dreq('/strong', method => 'POST',
          env => { HTTP_IF_NONE_MATCH => '"dv1"' }))[0], 405,
   'and a method that is not GET or HEAD never reaches the check';

# ---- phase 4: what a validator does to a shared cache -----------------------
#
# An ETag is a storage instruction. A response that is per-user or
# per-encoding, carrying a validator with nothing saying what it depends on,
# can be stored by an intermediary and handed to the next request for that
# URL - and now confidently revalidated, because there is a tag to do it
# with. Every rule here resolves ambiguity by saying MORE.

{
    package Shared;
    use Punk;
    plugin 'ConditionalGet';
    session secret => 'conditional-get-vary-key';

    get '/pub'    => sub { $_[0]->text('pub') },  { etag => sub { 'pv1' } };
    get '/pubw'   => sub { $_[0]->text('pubw') }, { etag => 1 };
    get '/me'     => sub {
        my ($c) = @_;
        $c->session->{who} = 'alice';        # dirties: a Set-Cookie follows
        $c->text('me');
    }, { etag => 1 };
    get '/stated' => sub {
        my ($c) = @_;
        $c->session->{who} = 'bob';
        $c->header('Cache-Control' => 'public, max-age=60');
        $c->text('stated');
    }, { etag => 1 };
    get '/own-vary' => sub {
        my ($c) = @_;
        $c->header(Vary => 'Accept-Language');
        $c->text('own');
    }, { etag => 1 };
    get '/negotiated' => sub {
        my ($c) = @_;
        $c->respond_to(
            json => sub { $_[0]->json({ ok => 1 }) },
            html => sub { $_[0]->html('<p>ok</p>') },
        );
    }, { etag => 1 };
}
my $sapp2 = Shared->to_app;

sub sreq {
    my ($path, %o) = @_;
    my $r = hit($sapp2, path => $path, env => $o{env} // {});
    my %h = @{ $r->[1] };
    return ($r->[0], \%h, ref $r->[2] eq 'ARRAY' ? join('', @{ $r->[2] }) : '');
}

# ---- Vary: Accept-Encoding, on anything tagged ------------------------------

{
    my (undef, $h) = sreq('/pub');
    is $h->{Vary}, 'Accept-Encoding',
       'a tagged response says it varies on the encoding - Punk does not '
       . 'compress, Hyperman does, so the same entity goes out as different '
       . 'bytes and a shared cache has to be told';
    my (undef, $hw) = sreq('/pubw');
    is $hw->{Vary}, 'Accept-Encoding', '...both halves';

    my (undef, $h304) = sreq('/pub', env => { HTTP_IF_NONE_MATCH => '"pv1"' });
    is $h304->{Vary}, 'Accept-Encoding',
       '...and the 304 carries it too, or the cache stores an entry keyed on '
       . 'nothing';
}

{
    my (undef, $h) = sreq('/own-vary');
    like $h->{Vary}, qr/\bAccept-Language\b/,
       'an application that declared its own Vary keeps it';
    like $h->{Vary}, qr/\bAccept-Encoding\b/, '...with ours merged in';
    is scalar(grep { $_ eq 'Vary' } @{[ %$h ]}), 1, '...as one header';
}

{
    # same entity, two clients: one tag, and the response says why bytes
    # might differ. This is the shape a shared cache needs to store one
    # entry and serve both correctly.
    my (undef, $plain) = sreq('/pubw');
    my (undef, $gzip)  = sreq('/pubw', env => { HTTP_ACCEPT_ENCODING => 'gzip' });
    is $plain->{ETag}, $gzip->{ETag},
       'a gzip client and an identity client get the SAME tag - the entity is '
       . 'the same entity whether or not it was compressed on the wire';
    is $gzip->{Vary}, 'Accept-Encoding', '...and both are told what varies';
}

# ---- private, for a response about one person -------------------------------

{
    my (undef, $h) = sreq('/me');
    ok $h->{'Set-Cookie'}, 'the session response sets a cookie';
    is $h->{'Cache-Control'}, 'private',
       'a response carrying a Set-Cookie is about a particular person, so it '
       . 'is not stored in a shared cache and replayed to the next one';
}

{
    my (undef, $h) = sreq('/stated');
    is $h->{'Cache-Control'}, 'public, max-age=60',
       'an application that stated its own policy is never overruled - it may '
       . 'have meant public and known why';
    is scalar(grep { $_ eq 'Cache-Control' } @{[ %$h ]}), 1,
       '...and gets one Cache-Control, not two contradicting each other';
}

{
    my (undef, $h) = sreq('/pub');
    ok !exists $h->{'Cache-Control'},
       'a response about nobody in particular is left alone';
}

{
    # The case a Set-Cookie test would miss, and the one that matters: a
    # signed-in user reading a page that changes nothing gets no write-back
    # and no Set-Cookie - and that is exactly the per-user response somebody
    # put an ETag on. The request's own Cookie is the signal.
    my (undef, $h) = sreq('/pub', env => { HTTP_COOKIE => 'punk.session=abc' });
    ok !exists $h->{'Set-Cookie'},
       'the response sets no cookie of its own';
    is $h->{'Cache-Control'}, 'private',
       '...but a request that carried one still gets private - a signed-in '
       . 'read is per-user even when nothing was written back';

    my (undef, $ha) = sreq('/pub', env => { HTTP_AUTHORIZATION => 'Bearer x' });
    is $ha->{'Cache-Control'}, 'private',
       'and so does an authorised request';

    my (undef, $h304) = sreq('/pub', env => { HTTP_COOKIE => 'punk.session=abc',
                                              HTTP_IF_NONE_MATCH => '"pv1"' });
    is $h304->{'Cache-Control'}, 'private',
       '...and the 304 says it too, or the cache learns the opposite on the '
       . 'revalidation';
}

# ---- content negotiation -----------------------------------------------------

{
    my (undef, $hj) = sreq('/negotiated', env => { HTTP_ACCEPT => 'application/json' });
    my (undef, $hh) = sreq('/negotiated', env => { HTTP_ACCEPT => 'text/html' });
    isnt $hj->{ETag}, $hh->{ETag},
       'two variants, two tags - the body ETag distinguishes them because it '
       . 'is a hash of the body that was actually produced';
    like $hj->{Vary}, qr/\bAccept\b/,
       'respond_to declared Accept...';
    like $hj->{Vary}, qr/\bAccept-Encoding\b/, '...and we added the encoding';

    # the cross check: the json variant tag must not 304 the html request
    my ($st) = sreq('/negotiated', env => { HTTP_ACCEPT => 'text/html',
                                            HTTP_IF_NONE_MATCH => $hj->{ETag} });
    is $st, 200,
       'a tag from one variant cannot 304 a request for the other';
}

# ---- the canary --------------------------------------------------------------
#
# The tag is computed over the body as the application produced it, before
# any compression, because compression is Hyperman's and happens after Punk
# has stopped looking. If that ever moves ahead of the hash, this fails.

SKIP: {
    eval { require Digest::SHA; 1 } or skip 'Digest::SHA not available', 1;
    my (undef, $h, $b) = sreq('/pubw');
    my $expect = 'W/"' . substr(Digest::SHA::sha256_hex('pubw'), 0, 16) . '"';
    is $h->{ETag}, $expect,
       'the tag is SHA-256 of the UNCOMPRESSED body, truncated - asserted '
       . 'against an independent hash so a compression move fails here';
}

done_testing;
