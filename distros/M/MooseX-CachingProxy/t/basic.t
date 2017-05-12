use LWP::UserAgent;
use MooseX::CachingProxy;
use MooseX::Test::Role;
use Test::Most;
use lib 't/lib';
use t::Server;

requires_ok('MooseX::CachingProxy', qw/url/);

my $server = t::Server->new();   # start a web server
my $uri = $server->uri . "boop"; # uri to use in tests

# - create a mock object called $mock
# - apply role to a $mock
# - create url() and make_request() methods on $mock
my $mock = consumer_of(
    'MooseX::CachingProxy', 
    url          => sub { $server->uri },
    make_request => sub {
        my ($self, $uri) = @_;
        my $request = HTTP::Request->new(GET => $uri);
        return LWP::UserAgent->new()->request($request);
    },
);

$mock->start_caching_proxy();

ok $mock->make_request($uri)->is_success, "request";

undef $server; # shut down web server

ok $mock->make_request($uri)->is_success, "request from cache";

$mock->stop_caching_proxy();

ok !$mock->make_request($uri)->is_success, "request; no cache, no server";

done_testing;

