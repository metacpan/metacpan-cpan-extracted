#!perl -T

use Test::More tests => 22;

use URI;

use Plack::App::PubSubHubbub::Subscriber::Client;
use Plack::App::PubSubHubbub::Subscriber::Config;

note 'test first with the token in the QS';

my $conf = Plack::App::PubSubHubbub::Subscriber::Config->new(
    callback => 'http://example.tld:8081/callback?arg1=v1',
    token_in_path => 0,
);

my $client = Plack::App::PubSubHubbub::Subscriber::Client->new(
    config => $conf,
);

isa_ok $client, 'Plack::App::PubSubHubbub::Subscriber::Client';

note 'subscribe';
{
    my $request = $client->subscribe_request(
        "http://hub.tld/",
        "http://feed.tld/atom.xml",
        "mytoken",
    );

    isa_ok $request, 'HTTP::Request';
    is $request->method, 'POST', 'method';
    is $request->uri, 'http://hub.tld/', 'uri';
    my $uri = URI->new('http:');
    $uri->query($request->content);
    my %args = $uri->query_form;
    my $expected = {
      'hub.topic' => 'http://feed.tld/atom.xml',
      'hub.mode' => 'subscribe',
      'hub.callback' => 'http://example.tld:8081/callback?arg1=v1',
      'hub.verify' => 'sync',
      'hub.verify_token' => 'mytoken'
    };
    is_deeply(\%args, $expected, 'request content');
}

note 'unsubscribe';
{
    my $request = $client->unsubscribe_request(
        "http://hub.tld/",
        "http://feed.tld/atom.xml",
        "mytoken",
    );

    isa_ok $request, 'HTTP::Request';
    is $request->method, 'POST', 'method';
    is $request->uri, 'http://hub.tld/', 'uri';
    my $uri = URI->new('http:');
    $uri->query($request->content);
    my %args = $uri->query_form;
    my $expected = {
      'hub.topic' => 'http://feed.tld/atom.xml',
      'hub.mode' => 'unsubscribe',
      'hub.callback' => 'http://example.tld:8081/callback?arg1=v1',
      'hub.verify' => 'sync',
      'hub.verify_token' => 'mytoken'
    };
    is_deeply(\%args, $expected, 'request content');
}

note 'with token in path';

$client->config->{token_in_path} = 1;

note 'subscribe';
{
    my $request = $client->subscribe_request(
        "http://hub.tld/",
        "http://feed.tld/atom.xml",
        "mytoken",
    );

    isa_ok $request, 'HTTP::Request';
    is $request->method, 'POST', 'method';
    is $request->uri, 'http://hub.tld/', 'uri';
    my $uri = URI->new('http:');
    $uri->query($request->content);
    my %args = $uri->query_form;
    my $expected = {
      'hub.topic' => 'http://feed.tld/atom.xml',
      'hub.mode' => 'subscribe',
      'hub.callback' => 'http://example.tld:8081/callback/mytoken?arg1=v1',
      'hub.verify' => 'sync',
    };
    is_deeply(\%args, $expected, 'request content');
}

note 'unsubscribe';
{
    my $request = $client->unsubscribe_request(
        "http://hub.tld/",
        "http://feed.tld/atom.xml",
        "mytoken",
    );

    isa_ok $request, 'HTTP::Request';
    is $request->method, 'POST', 'method';
    is $request->uri, 'http://hub.tld/', 'uri';
    my $uri = URI->new('http:');
    $uri->query($request->content);
    my %args = $uri->query_form;
    my $expected = {
      'hub.topic' => 'http://feed.tld/atom.xml',
      'hub.mode' => 'unsubscribe',
      'hub.callback' => 'http://example.tld:8081/callback/mytoken?arg1=v1',
      'hub.verify' => 'sync',
    };
    is_deeply(\%args, $expected, 'request content');
}

note "inject token";

sub test_inject_token {
    my ($base, $token, $expected) = @_;
    cmp_ok(
        Plack::App::PubSubHubbub::Subscriber::Client::_inject_token($base, $token),
        'eq', $expected, "inject token: $expected"
    );
}

test_inject_token( 'http://example.tld', 'token', 'http://example.tld/token' );
test_inject_token( 'http://example.tld/', 'token', 'http://example.tld/token' );
test_inject_token( 'http://example.tld/callback', 'token', 'http://example.tld/callback/token' );
test_inject_token( 'http://example.tld/callback/', 'token', 'http://example.tld/callback/token' );
test_inject_token( 'http://example.tld/callback/?arg1=v1', 'token', 'http://example.tld/callback/token?arg1=v1' );
