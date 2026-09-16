#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;

BEGIN {
    plan skip_all => 'DBI and DBD::SQLite required for the DBI-backed store'
        unless eval { require DBI; require DBD::SQLite; 1 };
}
use POTest;
use Crypt::JWS qw(b64url random_bytes sha256);
use File::Raw::JSON ();
use Punk::OAuth2::Server::Store;

# RFC 7591 dynamic client registration.
#
# Why it exists: an agent that has never met this authorization server cannot
# be handed a client_id out of band, so it asks for one. That is what lets a
# connector inside somebody else's product talk to a server nobody configured
# it for.
#
# Everything it may register is narrow on purpose, and the tests below are
# mostly about the narrowness rather than the happy path: an open endpoint
# that issued secrets, or confidential-client grants, or accepted a plain http
# redirect, would be a way to mint credentials by asking.

my $dbfile = "/tmp/pox-reg-$$.db";
unlink $dbfile;
my $store = Punk::OAuth2::Server::Store->new(dsn => "dbi:SQLite:dbname=$dbfile");
END { unlink $dbfile if $dbfile }

{
    package IdPApp;
    use Punk;
    use Punk::Plugin::OAuth2;
    plugin 'OAuth2';
    oauth2_server '/oauth' => {
        issuer       => 'https://idp.test',
        store        => $store,
        authenticate => sub { 'user-42' },
    };
}
my $app = IdPApp->to_app;

sub jdec { File::Raw::JSON::file_json_decode($_[0]) }
sub jenc { File::Raw::JSON::file_json_encode($_[0]) }
sub enc  { my $v = defined $_[0] ? $_[0] : '';
           $v =~ s/([^A-Za-z0-9\-._~])/sprintf '%%%02X', ord $1/ge; $v }

sub register {
    my ($meta) = @_;
    my ($s, undef, $b) = POTest::hit($app, POST => '/oauth/register',
        body => jenc($meta), type => 'application/json');
    return ($s, $b ? jdec($b) : undef);
}

# ---- the happy path --------------------------------------------------------

my $client;
{
    my ($s, $r) = register({
        client_name   => 'An Agent',
        redirect_uris => ['https://agent.test/cb'],
        scope         => 'read',
        token_endpoint_auth_method => 'none',
    });
    is $s, 201, 'registration creates a client';
    ok $r->{client_id}, '...with a client_id';
    is $r->{token_endpoint_auth_method}, 'none',
       '...that authenticates with nothing, being public';
    ok !exists $r->{client_secret},
       '...and is issued NO secret, which an open endpoint must never hand out';
    ok $r->{client_id_issued_at}, '...stamped with when it was issued';
    is_deeply $r->{redirect_uris}, ['https://agent.test/cb'],
       '...echoing the redirect it registered';
    is_deeply [sort @{ $r->{grant_types} }],
              ['authorization_code', 'refresh_token'],
       'it gets the code flow and refresh, and nothing else';
    ok !(grep { $_ eq 'client_credentials' } @{ $r->{grant_types} }),
       'client_credentials is never granted to a self-registered client';
    $client = $r->{client_id};
}

# Two registrations are two clients, not one shared identity.
{
    my (undef, $r) = register({ redirect_uris => ['https://agent.test/cb'] });
    isnt $r->{client_id}, $client, 'each registration gets its own client_id';
}

# ---- the refusals ----------------------------------------------------------

{
    my ($s, $r) = register({ client_name => 'No Redirect' });
    is $s, 400, 'no redirect_uris at all is refused';
    is $r->{error}, 'invalid_redirect_uri', '...as invalid_redirect_uri';

    ($s, $r) = register({ redirect_uris => [] });
    is $s, 400, 'an empty redirect_uris list is refused';

    ($s, $r) = register({ redirect_uris => ['http://agent.test/cb'] });
    is $s, 400, 'a plain http redirect is refused, as OAuth 2.1 requires';
    is $r->{error}, 'invalid_redirect_uri', '...as invalid_redirect_uri';

    ($s, $r) = register({ redirect_uris =>
        ['https://agent.test/cb', 'http://elsewhere.test/cb'] });
    is $s, 400, 'one bad redirect among good ones refuses the whole thing';

    my ($bs) = POTest::hit($app, POST => '/oauth/register',
        body => 'not json', type => 'application/json');
    is $bs, 400, 'a body that is not JSON is refused';

    my ($es) = POTest::hit($app, POST => '/oauth/register',
        body => '', type => 'application/json');
    is $es, 400, 'an empty body is refused';
}

# Loopback is allowed, because that is how a native client gets its code.
{
    my ($s) = register({ redirect_uris => ['http://localhost:8080/cb'] });
    is $s, 201, 'http on localhost is allowed for a native client';

    my ($s2) = register({ redirect_uris => ['http://127.0.0.1:9000/cb'] });
    is $s2, 201, '...and on 127.0.0.1';

    my ($s3) = register({ redirect_uris => ['http://localhost.evil.test/cb'] });
    is $s3, 400,
       'but a host merely STARTING with localhost is not loopback';
}

# ---- a registered client can actually be used ------------------------------
#
# The registration is worth nothing if the client it creates cannot complete a
# flow, so this drives one rather than trusting the 201.

{
    my $verifier  = b64url(random_bytes(32));
    my $challenge = b64url(sha256($verifier));
    my ($s, $h) = POTest::hit($app, GET =>
        "/oauth/authorize?response_type=code&client_id=" . enc($client)
      . "&redirect_uri=" . enc('https://agent.test/cb')
      . "&scope=read&state=xyz"
      . "&code_challenge=$challenge&code_challenge_method=S256");
    is $s, 302, 'the registered client can start an authorization';
    my ($code) = ($h->{location} || '') =~ /[?&]code=([^&]+)/;
    ok $code, '...and receives a code';

    my $body = join '&',
        'grant_type=authorization_code',
        'code=' . enc($code),
        'redirect_uri=' . enc('https://agent.test/cb'),
        'code_verifier=' . enc($verifier),
        'client_id=' . enc($client);
    my ($ts, undef, $tb) = POTest::hit($app, POST => '/oauth/token',
        body => $body, type => 'application/x-www-form-urlencoded');
    is $ts, 200, '...and exchanges it with no secret, being public';
    ok jdec($tb)->{access_token}, '...for an access token';
}

# A self-registered client must not be able to mint tokens in its own right.
{
    my ($s) = POTest::hit($app, POST => '/oauth/token',
        body => 'grant_type=client_credentials&client_id=' . enc($client),
        type => 'application/x-www-form-urlencoded');
    isnt $s, 200, 'it cannot use client_credentials';
}

# ---- discovery -------------------------------------------------------------

{
    my (undef, undef, $b) = POTest::hit($app, GET =>
        '/.well-known/oauth-authorization-server');
    is jdec($b)->{registration_endpoint}, 'https://idp.test/oauth/register',
       'the metadata advertises where to register';
}

done_testing;
