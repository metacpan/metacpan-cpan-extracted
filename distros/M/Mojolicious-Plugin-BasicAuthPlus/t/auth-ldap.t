use Mojo::IOLoop;
use Test::More;
use Test::Mojo;
use Mojo::ByteStream 'b';

# Make sure sockets are working
my $id = Mojo::IOLoop->server({address => '127.0.0.1'} => sub { });
plan skip_all => 'working sockets required for this test!'
    unless Mojo::IOLoop->acceptor($id)->handle->sockport;    # Test server

# We need access to a test LDAP server, set some environment variables for
# yours, e.g.
# setenv MOJO_TEST_LDAP_HOST ldap.someplace.com
# setenv MOJO_TEST_LDAP_BASEDN "dc=MYDOMAIN,dc=com"
# setenv MOJO_TEST_LDAP_USERPASS user:pass

plan skip_all => 'SKIPPING LDAP TESTS, TEST ENVIRONMENT VARIABLES NOT SET'
  unless $ENV{MOJO_TEST_LDAP_HOST} && $ENV{MOJO_TEST_LDAP_BASEDN} && $ENV{MOJO_TEST_LDAP_USERPASS};

# Lite app
use Mojolicious::Lite;

# Silence
app->log->level('error');

plugin 'basic_auth_plus';

# Explicit username and password
get '/ldap-auth' => sub {
    my $self = shift;

    return $self->render(text => 'authorized')
        if $self->basic_auth(
            realm => {
              # Anonymous bind. on some less-standard ldap configs you might
              # need more parameters, but this should usually work
              host   => $ENV{MOJO_TEST_LDAP_HOST} || 'MISSINGLDAPSERVER',
              basedn => $ENV{MOJO_TEST_LDAP_BASEDN} || 'dc=MYDOMAIN,dc=com'
            }
        );

    $self->render(text => 'denied');
};

under sub {
    my $self = shift;
    return $self->basic_auth(
        realm =>  {
              host   => $ENV{MOJO_TEST_LDAP_HOST} || 'MISSINGLDAPSERVER',
              basedn => $ENV{MOJO_TEST_LDAP_BASEDN} || 'dc=MYDOMAIN,dc=com'
        });
};

get '/under-ldap-bridge' => sub {
    shift->render(text => 'authorized');
};


# Tests
my $t = Test::Mojo->new;
my $encoded;

# Fails #

# Under bridge fail
diag "ldap-auth";
$encoded = b("bad:auth")->b64_encode->to_string;
chop $encoded;
$t->get_ok('/ldap-auth', {Authorization => "Basic $encoded"}, 'bad credentials')
   ->status_is(401)->content_is('denied');
diag "ldap bridge";
$t->get_ok('/under-ldap-bridge', {Authorization => "Basic $encoded"}, 'bad credentials')
   ->status_is(401)->content_is('');

# blank password
$encoded = b("bad:")->b64_encode->to_string;
chop $encoded;
$t->get_ok('/ldap-auth', {Authorization => "Basic $encoded"}, 'blank password')
  ->status_is(401)->content_is('denied');

# Successes #

# Under bridge

$encoded = b($ENV{MOJO_TEST_LDAP_USERPASS})->b64_encode->to_string;
chop $encoded;
diag '/ldap-auth';
$t->get_ok('/ldap-auth', {Authorization => "Basic $encoded"})
  ->status_is(200)->content_is('authorized');
diag '/under-ldap-bridge';
$t->get_ok('/under-ldap-bridge', {Authorization => "Basic $encoded"})
  ->status_is(200)->content_is('authorized');

done_testing;
