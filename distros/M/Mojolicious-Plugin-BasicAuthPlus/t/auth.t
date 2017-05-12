use Mojo::IOLoop;
use Test::More;
use Test::Mojo;
use Mojo::ByteStream 'b';

# Make sure sockets are working
my $id = Mojo::IOLoop->server({address => '127.0.0.1'} => sub { });
plan skip_all => 'working sockets required for this test!'
    unless Mojo::IOLoop->acceptor($id)->handle->sockport;    # Test server

plan tests => 81;

# Lite app
use Mojolicious::Lite;

# Silence
app->log->level('error');

plugin 'basic_auth_plus';

get '/user-pass' => sub {
    my $self = shift;

    return $self->render(text => 'authorized')
      if $self->basic_auth(realm => username => 'password');

    $self->render(text => 'denied');
};

get '/user-pass-with-hash' => sub {
    my $self = shift;

    my ($hash_ref, $auth_ok)
        = $self->basic_auth(realm => 'philip' => 'fry');
    return $self->render(text => $hash_ref->{username})
      if $auth_ok;

    $self->render(text => 'denied');
};

get '/user-pass-with-hash-return' => sub {
    my $self = shift;

    my ($hash_ref, $auth_ok)
        = $self->basic_auth(realm => {username => 'philip',
                password => 'fry'});
    return $self->render(text => $hash_ref->{username})
      if $auth_ok;

    $self->render(text => 'denied');
};

get '/user-pass-with-colon-password' => sub {
    my $self = shift;

    return $self->render(text => 'authorized')
      if $self->basic_auth(realm => username => 'pass:word');

    $self->render(text => 'denied');
};

get '/user-pass-with-colon-password-with-hash' => sub {
    my $self = shift;

    my ($hash_ref, $auth_ok)
        = $self->basic_auth(realm => 'turanga' => 'lee:la');
    return $self->render(text => $hash_ref->{username})
      if $auth_ok;

    $self->render(text => 'denied');
};

get '/pass' => sub {
    my $self = shift;

    return $self->render(text => 'denied')
      unless $self->basic_auth(realm => 'password');

    $self->render(text => 'authorized');
};

get '/pass-with-hash' => sub {
    my $self = shift;

    my ($hash_ref, $auth_ok)
        = $self->basic_auth(realm => 'rodriguez');
    return $self->render(text => 'denied')
      unless $auth_ok;

    $self->render(text => 'authorized');
};

# Entered user/pass supplied to callback
get '/get-auth-callback' => sub {
    my $self = shift;

    return $self->render(text => 'authorized')
      if $self->basic_auth(
        realm => sub { return "@_" eq 'username password' });

    $self->render(text => 'denied');
};

# Entered user/pass supplied to callback, with return data hash.
get '/get-auth-callback-with-hash' => sub {
    my $self = shift;

    my ($hash_ref, $auth_ok) = $self->basic_auth(
        realm => sub { return "@_" eq 'amy wong' });

    return $self->render(text => 'authorized')
      if $auth_ok;

    $self->render(text => 'denied');
};

# Callback with colon in password
get '/get-auth-callback-with-colon-password' => sub {
    my $self = shift;

    return $self->render(text => 'authorized')
      if $self->basic_auth(
        realm => sub { return "@_" eq 'username pass:word' });

    return $self->render(text => 'denied');
};

# Callback with colon in password and return data hash.
get '/get-auth-callback-with-colon-password-with-hash' => sub {
    my $self = shift;

    my ($hash_ref, $auth_ok) = $self->basic_auth(
        realm => sub { return "@_" eq 'hermes con:rad' });

    return $self->render(text => 'authorized')
      if $auth_ok;

    return $self->render(text => 'denied');
};

# Explicit username and password
get '/get-auth-with-explicit-creds' => sub {
    my $self = shift;

    return $self->render(text => 'authorized')
        if $self->basic_auth(
            realm => {
                username => 'username',
                password => 'password'
            }
        );

    $self->render(text => 'denied');
};

# Explicit username and password, with return data hash.
get '/get-auth-with-explicit-creds-with-hash' => sub {
    my $self = shift;

    my ($hash_ref, $auth_ok) = $self->basic_auth(
        realm => {
            username => 'hubert',
            password => 'farnsworth'
        }
    );
    return $self->render(text => 'authorized') if $auth_ok;

    $self->render(text => 'denied');
};

# Explicit username and encrypted password string
get '/get-auth-with-encrypted-pass' => sub {
    my $self = shift;

    return $self->render(text => 'authorized')
        if $self->basic_auth(
            realm => {
                username => 'username',
                password => 'MlQ8OC3xHPIi.'
            }
        );

    $self->render(text => 'denied');
};

# Explicit username and encrypted password string, with return data hash.
get '/get-auth-with-encrypted-pass-with-hash' => sub {
    my $self = shift;

    my ($hash_ref, $auth_ok) = $self->basic_auth(
        realm => {
            username => 'john',
            password => 'kFoPqtnBtuI3Q'
        }
    );
    return $self->render(text => 'authorized') if $auth_ok;

    $self->render(text => 'denied');
};

# Passwd file authentication
get '/passwd-file' => sub {
    my $self = shift;

    return $self->render(text => 'authorized')
        if $self->basic_auth(
            realm => {
                path => 'test.passwd'
            }
        );

    $self->render(text => 'denied');
};

# Passwd file authentication with return data hash.
get '/passwd-file-with-hash' => sub {
    my $self = shift;

    my ($hash_ref, $auth_ok) = $self->basic_auth(
        realm => {
            path => 'test.passwd'
        }
    );
    return $self->render(text => 'authorized for ' . ($hash_ref->{username}//'')) if $auth_ok;

    $self->render(text => 'denied');
};

under sub {
    my $self = shift;
    return $self->basic_auth(
        realm => sub { return "@_" eq 'username password' });
};

get '/under-bridge' => sub {
    shift->render(text => 'authorized');
};

# Tests
my $t = Test::Mojo->new;
my $encoded;


# Failures #

foreach (
    qw(
    /user-pass
    /pass
    /get-auth-callback
    )
  )
{

    # No user/pass
    $t->get_ok($_)->status_is(401)
      ->header_is('WWW-Authenticate' => 'Basic realm="realm"')
      ->content_is('denied');

    # Incorrect user/pass
    $encoded = b('bad:auth')->b64_encode->to_string;
    chop $encoded;
    $t->get_ok($_, {Authorization => "Basic $encoded"})->status_is(401)
      ->header_is('WWW-Authenticate' => 'Basic realm="realm"')
      ->content_is('denied');
}

# Under bridge fail
diag "\n/under-bridge";
$encoded = b("bad:auth")->b64_encode->to_string;
chop $encoded;
$t->get_ok('/under-bridge', {Authorization => "Basic $encoded"})
  ->status_is(401)->content_is('');

# Successes #

# Username, password
diag '/user-pass';
$encoded = b("username:password")->b64_encode->to_string;
chop $encoded;
$t->get_ok('/user-pass', {Authorization => "Basic $encoded"})->status_is(200)
  ->content_is('authorized');

# Username, password, with return data hash.
diag '/user-pass-with-hash';
$encoded = b("philip:fry")->b64_encode->to_string;
chop $encoded;
$t->get_ok('/user-pass-with-hash', {Authorization => "Basic $encoded"})->status_is(200)->content_is('philip');

# Username, password, with return data hash.
diag '/user-pass-with-hash-return';
$encoded = b("philip:fry")->b64_encode->to_string;
chop $encoded;
$t->get_ok('/user-pass-with-hash-return', {Authorization => "Basic $encoded"})->status_is(200)->content_is('philip');

# Username, password with colon in password
diag '/user-pass-with-colon-password';
$encoded = b("username:pass:word")->b64_encode->to_string;
chop $encoded;
$t->get_ok('/user-pass-with-colon-password', {Authorization => "Basic $encoded"})->status_is(200)
  ->content_is('authorized');

# Username, password with colon in password, with return data hash.
diag '/user-pass-with-colon-password-with-hash';
$encoded = b("turanga:lee:la")->b64_encode->to_string;
chop $encoded;
$t->get_ok('/user-pass-with-colon-password-with-hash', {Authorization => "Basic $encoded"})->status_is(200)
  ->content_is('turanga');

# Password only
diag '/pass';
$encoded = b(":password")->b64_encode->to_string;
chop $encoded;
$t->get_ok('/pass', {Authorization => "Basic $encoded"})->status_is(200)
  ->content_is('authorized');

# Password only, with return data hash.
diag '/pass-with-hash';
$encoded = b(":rodriguez")->b64_encode->to_string;
chop $encoded;
$t->get_ok('/pass-with-hash', {Authorization => "Basic $encoded"})
  ->status_is(200)->content_is('authorized');

# With callback
diag '/get-auth-callback';
$encoded = b("username:password")->b64_encode->to_string;
chop $encoded;
$t->get_ok('/get-auth-callback', {Authorization => "Basic $encoded"})
  ->status_is(200)->content_is('authorized');

# With callback and return data hash.
diag '/get-auth-callback-with-hash';
$encoded = b("amy:wong")->b64_encode->to_string;
chop $encoded;
$t->get_ok('/get-auth-callback-with-hash', {Authorization => "Basic $encoded"})
  ->status_is(200)->content_is('authorized');

# With callback and colon in password
diag '/get-auth-callback-with-colon-password';
$encoded = b("username:pass:word")->b64_encode->to_string;
chop $encoded;
$t->get_ok('/get-auth-callback-with-colon-password', {Authorization => "Basic $encoded"})
  ->status_is(200)->content_is('authorized');

# With callback and colon in password, and return data hash.
diag '/get-auth-callback-with-colon-password-with-hash';
$encoded = b("hermes:con:rad")->b64_encode->to_string;
chop $encoded;
$t->get_ok('/get-auth-callback-with-colon-password-with-hash', {Authorization => "Basic $encoded"})
  ->status_is(200)->content_is('authorized');

# Under bridge
diag '/under-bridge';
$encoded = b("username:password")->b64_encode->to_string;
chop $encoded;
$t->get_ok('/under-bridge', {Authorization => "Basic $encoded"})
  ->status_is(200)->content_is('authorized');

# Explicit username and password
diag '/get-auth-with-explicit-creds';
$encoded = b("username:password")->b64_encode->to_string;
chop $encoded;
$t->get_ok('/get-auth-with-explicit-creds', {Authorization => "Basic $encoded"})
  ->status_is(200)->content_is('authorized');

# Explicit username and password, and return data hash.
diag '/get-auth-with-explicit-creds-with-hash';
$encoded = b("hubert:farnsworth")->b64_encode->to_string;
chop $encoded;
$t->get_ok('/get-auth-with-explicit-creds-with-hash', {Authorization => "Basic $encoded"})
  ->status_is(200)->content_is('authorized');

# Explicit username and encrypted password string
diag '/get-auth-with-encrypted-pass';
$encoded = b("username:password")->b64_encode->to_string;
chop $encoded;
$t->get_ok('/get-auth-with-encrypted-pass', {Authorization => "Basic $encoded"})
  ->status_is(200)->content_is('authorized');

# Explicit username and encrypted password string, with return data hash.
diag '/get-auth-with-encrypted-pass-with-hash';
$encoded = b("john:zoidberg")->b64_encode->to_string;
chop $encoded;
$t->get_ok('/get-auth-with-encrypted-pass-with-hash', {Authorization => "Basic $encoded"})->status_is(200)->content_is('authorized');

# Passwd file authentication
diag '/passwd-file';
$encoded = b("username:password")->b64_encode->to_string;
chop $encoded;
$t->get_ok('/passwd-file', {Authorization => "Basic $encoded"})
  ->status_is(200)->content_is('authorized');

# Passwd file authentication with return data hash.
diag '/passwd-file-with-hash';
$encoded = b("lord:nibbler")->b64_encode->to_string;
chop $encoded;
$t->get_ok('/passwd-file-with-hash', {Authorization => "Basic $encoded"})
  ->status_is(200)->content_is('authorized for lord');

