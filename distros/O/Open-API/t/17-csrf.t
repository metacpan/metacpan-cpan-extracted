#!perl
use 5.008003;
use strict;
use warnings;
use FindBin ();
use Test::More;
use Open::API;
use Open::API::Plack;

# CSRF protection on to_app: safe methods bypass; Origin/Referer checking
# (same-origin default and explicit allowlist) on state-changing methods; the
# app-owned token via the check callback (verify, stash, rotate, single-use);
# and the after hook running on a 403.

my $api = Open::API->new(spec => "$FindBin::Bin/spec/petstore.json");

sub req {
    my ($app, %o) = @_;
    my $body = defined $o{body} ? $o{body} : '';
    open my $in, '<', \$body or die;
    return $app->({
        REQUEST_METHOD => $o{method} || 'GET',
        PATH_INFO      => $o{path}   || '/',
        QUERY_STRING   => $o{query}  || '',
        CONTENT_LENGTH => length $body,
        'psgi.input'   => $in,
        %{ $o{env} || {} },
    });
}

my %handlers = (
    listPets  => sub { [ 200, ['Content-Type' => 'application/json'], ['[]'] ] },
    getPet    => sub { [ 200, ['Content-Type' => 'application/json'], ['{}'] ] },
    createPet => sub { [ 201, ['Content-Type' => 'application/json'], ['{}'] ] },
    deletePet => sub { [ 200, ['Content-Type' => 'application/json'], ['{}'] ] },
);

my $HOST = 'api.example.com';

# ---- same-origin default --------------------------------------------------------
{
    my $app = Open::API::Plack->new(api => $api, handlers => \%handlers, csrf => {})->to_app;

    is(req($app, path => '/pets',
           env => { HTTP_HOST => $HOST })->[0], 200,
       'safe GET bypasses CSRF even with no Origin');

    is(req($app, method => 'DELETE', path => '/pets/5',
           env => { HTTP_HOST => $HOST, HTTP_COOKIE => 'session=s',
                    HTTP_ORIGIN => "https://$HOST" })->[0], 200,
       'same-origin DELETE passes');

    is(req($app, method => 'DELETE', path => '/pets/5',
           env => { HTTP_HOST => $HOST,
                    HTTP_ORIGIN => 'https://evil.example.net' })->[0], 403,
       'cross-origin DELETE is blocked');

    is(req($app, method => 'DELETE', path => '/pets/5',
           env => { HTTP_HOST => $HOST })->[0], 403,
       'unsafe request with no Origin/Referer is blocked');

    is(req($app, method => 'DELETE', path => '/pets/5',
           env => { HTTP_HOST => $HOST, HTTP_COOKIE => 'session=s',
                    HTTP_REFERER => "https://$HOST/pets" })->[0], 200,
       'Referer is used when Origin is absent');
}

# ---- explicit origin allowlist --------------------------------------------------
{
    my $app = Open::API::Plack->new(api => $api, handlers => \%handlers,
        csrf => { origins => [ 'https://app.example.com' ] })->to_app;

    is(req($app, method => 'DELETE', path => '/pets/5',
           env => { HTTP_HOST => $HOST, HTTP_COOKIE => 'session=s',
                    HTTP_ORIGIN => 'https://app.example.com' })->[0], 200,
       'allowlisted origin passes');

    is(req($app, method => 'DELETE', path => '/pets/5',
           env => { HTTP_HOST => $HOST, HTTP_COOKIE => 'session=s',
                    HTTP_ORIGIN => "https://$HOST" })->[0], 403,
       'same-origin is NOT trusted once an allowlist is given');

    is(req($app, method => 'DELETE', path => '/pets/5',
           env => { HTTP_HOST => $HOST, HTTP_COOKIE => 'session=s',
                    HTTP_ORIGIN => 'https://app.example.com/some/path' })->[0], 200,
       'a trailing path on the Origin is ignored (authority compared)');
}

# ---- custom header / cookie names (check reads the header, rotates the cookie) --
{
    my $app = Open::API::Plack->new(api => $api, handlers => \%handlers, csrf => {
        origins => [ "https://$HOST" ],
        header  => 'X-XSRF',      # submitted token comes from here
        cookie  => 'xsrf',        # rotation Set-Cookie uses this name
        check   => sub {
            my ($submitted) = @_;
            return 0 unless defined $submitted && $submitted eq 'good';
            return 'next';        # rotate
        },
    })->to_app;
    my $r = req($app, method => 'DELETE', path => '/pets/5', env => {
        HTTP_HOST => $HOST, HTTP_ORIGIN => "https://$HOST",
        HTTP_COOKIE => 'session=s', 'HTTP_X_XSRF' => 'good',
    });
    is($r->[0], 200, 'custom header name honoured for the submitted token');
    my %h = @{ $r->[1] };
    is($h{'Set-Cookie'}, 'xsrf=next; Path=/; SameSite=Strict',
       'custom cookie name honoured for rotation');
}

# ---- after hook runs on a CSRF 403 ----------------------------------------------
{
    my $app = Open::API::Plack->new(api => $api, handlers => \%handlers, csrf => {},
        after => sub {
            my ($resp) = @_;
            push @{ $resp->[1] }, 'X-Blocked' => 'csrf';
            return;
        })->to_app;
    my $r = req($app, method => 'DELETE', path => '/pets/5',
                env => { HTTP_HOST => $HOST,
                         HTTP_ORIGIN => 'https://evil.example.net' });
    is($r->[0], 403, 'blocked');
    my %h = @{ $r->[1] };
    is($h{'X-Blocked'}, 'csrf', 'after hook still runs on the 403');
}

# ---- session/DB backed token via a check callback -------------------------------
{
    # the "session store": a session id in a cookie maps to the token we issued
    my %session = ( 'sess-abc' => 'stored-token-xyz' );

    my @seen;
    my $app = Open::API::Plack->new(api => $api, handlers => \%handlers, csrf => {
        origins => [ "https://$HOST" ],
        check   => sub {
            my ($submitted, $env, $op_id) = @_;
            push @seen, $op_id;
            my ($sid) = ($env->{HTTP_COOKIE} || '') =~ /\bsid=([^;]+)/;
            my $stored = defined $sid ? $session{$sid} : undef;
            return defined $stored && defined $submitted && $stored eq $submitted;
        },
    })->to_app;
    my %ok_origin = (HTTP_HOST => $HOST, HTTP_ORIGIN => "https://$HOST");

    is(req($app, method => 'DELETE', path => '/pets/5', env => {
           %ok_origin,
           HTTP_COOKIE => 'session=s; sid=sess-abc',
           'HTTP_X_CSRF_TOKEN' => 'stored-token-xyz',
       })->[0], 200, 'check callback: token matching the session store passes');

    is(req($app, method => 'DELETE', path => '/pets/5', env => {
           %ok_origin,
           HTTP_COOKIE => 'session=s; sid=sess-abc',
           'HTTP_X_CSRF_TOKEN' => 'wrong-token',
       })->[0], 403, 'check callback: a token not in the store is rejected');

    is(req($app, method => 'DELETE', path => '/pets/5', env => {
           %ok_origin, HTTP_COOKIE => 'session=s; sid=sess-abc',
       })->[0], 403, 'check callback: a missing token is rejected');

    is($seen[0], 'deletePet', 'check callback receives the operationId');

    # safe methods never invoke the callback
    @seen = ();
    req($app, path => '/pets', env => { HTTP_HOST => $HOST });
    is(scalar(@seen), 0, 'check callback is not run for safe methods');
}

# ---- a truthy non-string return authorises without rotating ---------------------
{
    my $ran = 0;
    my $app = Open::API::Plack->new(api => $api, handlers => \%handlers, csrf => {
        origins => [ "https://$HOST" ],
        check   => sub { $ran++; 1 },   # 1 = pass, no cookie rotation
    })->to_app;
    my $r = req($app, method => 'DELETE', path => '/pets/5', env => {
        HTTP_HOST => $HOST, HTTP_ORIGIN => "https://$HOST",
        HTTP_COOKIE => 'session=s',
    });
    is($r->[0], 200, 'check callback authorises');
    is($ran, 1, 'the check callback ran');
    my %h = @{ $r->[1] };
    ok(!exists $h{'Set-Cookie'}, 'a non-string return does not rotate a cookie');
}

# ---- check's truthy return is stashed as $env->{'openapi.csrf'} -----------------
{
    my $seen_stash;
    my $app = Open::API::Plack->new(api => $api, handlers => {
        %handlers,
        deletePet => sub {
            my ($p, $env) = @_;
            $seen_stash = $env->{'openapi.csrf'};   # what check returned
            [ 200, ['Content-Type' => 'application/json'], ['{}'] ];
        },
    }, csrf => {
        origins => [ "https://$HOST" ],
        check   => sub { 'the-stored-token' },      # return the token, not 1
    })->to_app;
    my $r = req($app, method => 'DELETE', path => '/pets/5', env => {
        HTTP_HOST => $HOST, HTTP_ORIGIN => "https://$HOST",
        HTTP_COOKIE => 'session=s', 'HTTP_X_CSRF_TOKEN' => 'x',
    });
    is($r->[0], 200, 'check truthy return authorises');
    is($seen_stash, 'the-stored-token',
       "check's return is available to the handler as openapi.csrf");
}

# ---- check returning a token rotates the cookie (single-use loop) ---------------
{
    # a tiny "session store": one token, consumed and rotated on use
    my %store = (tok => 'token-1');
    my $mint  = 'token-2';
    my $app = Open::API::Plack->new(api => $api, handlers => \%handlers, csrf => {
        origins => [ "https://$HOST" ], cookie => 'csrf',
        check   => sub {
            my ($submitted) = @_;
            my $stored = delete $store{tok};             # consume
            return 0 unless defined $submitted && defined $stored
                         && $submitted eq $stored;
            $store{tok} = $mint;                          # store the next
            return $mint;                                 # framework sets it
        },
    })->to_app;
    my $r = req($app, method => 'DELETE', path => '/pets/5', env => {
        HTTP_HOST => $HOST, HTTP_ORIGIN => "https://$HOST",
        HTTP_COOKIE => 'session=s', 'HTTP_X_CSRF_TOKEN' => 'token-1',
    });
    is($r->[0], 200, 'valid token authorises');
    my %h = @{ $r->[1] };
    is($h{'Set-Cookie'}, 'csrf=token-2; Path=/; SameSite=Strict',
       'the returned token is rotated onto the response as a Set-Cookie');

    # the original token is now spent: a replay is a 403
    is(req($app, method => 'DELETE', path => '/pets/5', env => {
           HTTP_HOST => $HOST, HTTP_ORIGIN => "https://$HOST",
           HTTP_COOKIE => 'session=s', 'HTTP_X_CSRF_TOKEN' => 'token-1',
       })->[0], 403, 'replaying the consumed token is rejected');
}

# ---- a dying check callback becomes a 500 ---------------------------------------
{
    my $app = Open::API::Plack->new(api => $api, handlers => \%handlers, csrf => {
        origins => [ "https://$HOST" ],
        check   => sub { die "session store unavailable\n" },
    })->to_app;
    is(req($app, method => 'DELETE', path => '/pets/5', env => {
           HTTP_HOST => $HOST, HTTP_ORIGIN => "https://$HOST",
           HTTP_COOKIE => 'session=s', 'HTTP_X_CSRF_TOKEN' => 't',
       })->[0], 500, 'a dying check callback becomes a 500');
}


done_testing();
