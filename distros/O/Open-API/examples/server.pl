#!/usr/bin/env perl
use strict;
use warnings;

# An authenticated, CSRF-protected Open::API server on Hyperman.
#
#   perl examples/server.pl [port]        # default 5000
#
# The spec (examples/petstore.json) is routed and validated in C. On top of
# that to_app enables:
#
#   * secure response headers   - on by default (nosniff, CSP, X-Frame-Options,
#                                 Referrer-Policy), stamped on every response
#   * authentication            - the spec's `session` apiKey-in-cookie scheme,
#                                 required document-wide, verified by a checker
#                                 (login opts out with `security: []`)
#   * an Origin allowlist       - unsafe methods must come from a known origin
#   * a server-side CSRF token  - held in a per-session store, verified by the
#                                 `check` callback, consumed and rotated on use
#
# Auth answers "is there a valid session?"; CSRF answers "did this come from
# our app?". A cookie-session API needs both. There is no stateless
# "double-submit" token: the token lives here, on the server, and is
# single-use. See `perldoc Open::API` (the SECURITY and CSRF sections).

use FindBin ();
use Hyperman;
use Open::API;
use Open::API::Plack;

my $port   = shift || 5000;
my $origin = "http://127.0.0.1:$port";
my $spec   = "$FindBin::Bin/petstore.json";

my $api = Open::API->new(spec => $spec);

# a toy in-memory "session store": sid => { user, csrf }. A real app would key
# this off its login session and keep it in Redis / a database.
my %SESSION;
my ($sid_seq, $tok_seq) = (0, 0);
sub new_token { 'csrf-' . (++$tok_seq) }

my $app = Open::API::Plack->new(api => $api,
    ui => 1,
    handlers => {
        # POST /login: authenticate (toy), then establish a session and hand
        # out the first CSRF token. This is where a client "gets in".
        login => sub {
            my ($params) = @_;
            my $user = $params->{body}{username};
            my $sid  = 'sess-' . (++$sid_seq);
            my $tok  = new_token();
            $SESSION{$sid} = { user => $user, csrf => $tok };
            [ 200,
              [ 'Content-Type' => 'application/json',
                'Set-Cookie'   => "sid=$sid; Path=/; HttpOnly",
                'Set-Cookie'   => "csrf=$tok; Path=/; SameSite=Strict" ],
              [ qq({"user":"$user"}) ] ];
        },
        listPets  => sub {
            my ($params, $env) = @_;
            my $user = $env->{'openapi.auth'}{session}{user};   # from the checker
            [ 200, ['Content-Type' => 'application/json'],
              [ qq({"user":"$user","pets":[]}) ] ];
        },
        createPet => sub {
            my ($params) = @_;                 # body already typed + validated
            [ 201, ['Content-Type' => 'application/json'],
              [ '{"id":' . $params->{body}{id} . ',"name":"' .
                $params->{body}{name} . '"}' ] ];
        },
        deletePet => sub { [ 204, [], [''] ] },
    },

    # authentication: the spec declares a `session` apiKey-in-cookie scheme and
    # requires it document-wide (login opts out with `security: []`). The
    # checker validates the sid cookie against the session store and returns
    # the user, which lands in $env->{'openapi.auth'}{session}.
    security => {
        session => sub {
            my ($sid, $env, $operationId) = @_;   # $sid = the cookie value
            my $sess = $SESSION{$sid} or return 0;
            return { user => $sess->{user} };
        },
    },

    csrf => {
        origins => [ $origin ],
        check => sub {
            my ($submitted, $env, $operationId) = @_;
            # login cannot require a token yet - it is how you get one - but
            # the Origin check above still guards it against cross-site abuse.
            return 1 if $operationId eq 'login';
            # every other unsafe call: verify against this session's token,
            # then consume + rotate. Returning the fresh token has the
            # framework set it as the new csrf cookie (single-use).
            my ($sid) = ($env->{HTTP_COOKIE} || '') =~ /\bsid=([^;]+)/;
            my $sess = $sid && $SESSION{$sid};
            return 0 unless $sess;
            return 0 unless defined $submitted && $submitted eq $sess->{csrf};
            my $fresh = new_token();
            $sess->{csrf} = $fresh;
            return $fresh;
        },
    },
)->to_app;

print "Petstore listening on $origin (workers=2)\n";
Hyperman->run(app => $app, host => '127.0.0.1', port => $port, workers => 2, access_log => \*STDERR);
