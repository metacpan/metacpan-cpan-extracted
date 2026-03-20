# $Id$

use strict;
use warnings;

use Test::More tests => 13;
use Test::Exception;
use HTTP::Request;
use HTTP::Response;
use JSON;

# use this until _get_agent behavior is worked out
# and we can subclass it. once that's done, switch
# to using Test::LWP::UserAgent as it avoids bugs that
# can occur when MockObject overrides ISA
use Test::Mock::LWP::Dispatch;

require_ok('Restish::Client');

my $NOC_VERSION = $Restish::Client::VERSION;

# Test creating NOC obj
{
my $client = Restish::Client->new(
    uri_host => 'https://ident.os.example.com');

ok($client, 'Create Restish::Client object');

isa_ok( $client, 'Restish::Client',
        'Object is a Restish::Client object');
}

# Accept header set to JSON
{
my $client = Restish::Client->new(
    uri_host => 'https://ident.os.example.com');

is( $client->_get_agent->default_header('Accept'),
    'application/json',
    'Accept header set to JSON' );
}

# Test creating NOC obj with agent_options
{
my $client = Restish::Client->new(
    uri_host => 'https://ident.os.example.com',
    agent_options => { timeout => 5 });

ok($client, 'Create Restish::Client object with agent_options');

is( $client->_get_agent->timeout,
    5,
    'Create agent with option timeout = 5' );
}

# Create NOC obj with invalid URI
{
throws_ok( sub { my $client = Restish::Client->new(
                 uri_host => 'http:/broken.com') },
           qr/Invalid value for parameter/,
           'Creating NOC obj with invalid URI dies' );
}

# Test creating NOC obj with head_params_default set
{
my $client = Restish::Client->new(
    uri_host => 'https://ident.os.example.com',
    head_params_default => { test_param => 'test' });

ok($client, 'Create Restish::Client object with head_params_default');

is($client->head_params_default->{test_param},
   'test',
   'Set head_params_default');
}

# Test creating NOC obj with non-hashref head_params_default
{
throws_ok( sub { Restish::Client->new(
    uri_host => 'https://ident.os.example.com',
    head_params_default => 'internet') },
    qr/Invalid/,
    'non-hashref head_params_default dies');
}

# Specify user agent string
{
my $client = Restish::Client->new(
    uri_host => 'https://ident.os.example.com',
    agent_options => { agent => 'test' });

is($client->_get_agent->agent,
   'test',
   'Specify user agent string');
}

# Default user agent string
{
my $client = Restish::Client->new(
    uri_host => 'https://ident.os.example.com'
);

is($client->_get_agent->agent,
   "Restish::Client/$NOC_VERSION",
   'Default user agent string');
}

# invalid require_https throws error
{
throws_ok( sub { Restish::Client->new(
    uri_host      => 'https://ident.os.example.com',
    require_https => '') },
    qr/Invalid value/,
    'invalid require_https value throws error');
}

done_testing();
