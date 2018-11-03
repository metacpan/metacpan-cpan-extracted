use strict;
use warnings;

# does not test mkrequest auto-export via @EXPORT
use Net::OpenStack::Client::Request qw(mkrequest parse_endpoint @SUPPORTED_METHODS);

use REST::Client;
use Test::More;
use Test::Warnings;
use version;

use File::Basename;
BEGIN {
    push(@INC, dirname(__FILE__));
}

use testapi;

my $r;

my $rclient = REST::Client->new();
foreach my $method (@SUPPORTED_METHODS) {
    ok($rclient->can($method), "REST::Client supports method $method");
}


=head1 init

=cut

$r = Net::OpenStack::Client::Request->new('c', 'POST');
isa_ok($r, 'Net::OpenStack::Client::Request', 'a Net::OpenStack::Client::Request instance created');


$r = mkrequest('c', 'POST');
isa_ok($r, 'Net::OpenStack::Client::Request', 'a Net::OpenStack::Client::Request instance created using mkrequest');

is($r->{endpoint}, 'c', 'endpoint set');
is($r->{method}, 'POST', 'method set');
is_deeply($r->{tpls}, {}, 'empty hash ref as tpls by default');
is_deeply($r->{opts}, {}, 'empty hash ref as opts by default');
is_deeply($r->{paths}, {}, 'empty hash ref as paths by default');
is_deeply($r->{rest}, {}, 'empty hash ref as rest by default');
ok(! defined($r->{error}), 'No error attribute set by default');
ok(! defined($r->{id}), 'No id attribute set by default');
ok(! $r->is_error(), 'is_error false');
ok($r, 'overloaded boolean = true if no error via is_error');

$r = mkrequest('d', 'PUT', tpls => {a => 2}, params => {x => 1}, opts => {a => 3, b => 4}, paths => {a => [qw(some path)], b => ['a']}, error => 'message', rest => {woo => 'hoo'}, service => 'myservice', version => 2);
is($r->{endpoint}, 'd', 'endpoint set 2');
is($r->{method}, 'PUT', 'method set 2');
is_deeply($r->{tpls}, {a => 2}, 'hash ref as tpls');
is_deeply($r->{params}, {x => 1}, 'hash ref as params');
is_deeply($r->{opts}, {a => 3, b => 4}, 'hash ref as opts');
is_deeply($r->{paths}, {a => ['some', 'path'], b => ['a']}, 'hash ref as paths');
is_deeply($r->{rest}, {woo => 'hoo'}, 'hash ref as rest');
is($r->{error}, 'message', 'error attribute set');
ok($r->is_error(), 'is_error true');
ok(! $r, 'overloaded boolean = false on error via is_error');
is($r->{service}, 'myservice', "service attribute");
is($r->{version}, 2, "version attribute");

$r = Net::OpenStack::Client::Request->new('c', 'NOSUCHMETHOD');
isa_ok($r, 'Net::OpenStack::Client::Request', 'a Net::OpenStack::Client::Request instance created');
ok(!defined($r->{method}), "undefined method attribute with unsupported method");
ok(!$r, "false request with unsupported method");
is($r->{error}, "Unsupported method NOSUCHMETHOD", "error message with unsupported method");

=head1 endpoints

=cut

is_deeply([parse_endpoint("/a/b/c")], ['/a/b/c', [], []], "endpoint w/o templates");
is_deeply([parse_endpoint("/a/{b}/c/{b}/{e}/")], ["/a/{b}/c/{b}/{e}/", [qw(b e)], []], "endpoint with templates");
is_deeply([parse_endpoint("/a/{b}/c/{b}/{e}?a=1&b=2")], ["/a/{b}/c/{b}/{e}", [qw(b e)], [qw(a b)]], 
          "endpoint with templates and params");

my $endpt = 'd/{a}/b/{a}/c/{d}/e';
my $oendpt = "$endpt?x=1&y=2&z=3";
$r = mkrequest($oendpt, 'PUT', tpls => {a => 2, d => 'd'}, params => {v => 10, y => 123, z => 456}, version => version->new('v1.2'));
is($r->{endpoint}, $oendpt, "endpoint before templating");
is($r->endpoint, 'd/2/b/2/c/d/e?y=123&z=456', "templated endpoint, params added");
is($r->endpoint("my.fqdn"), 'https://my.fqdn/v1.2/d/2/b/2/c/d/e?y=123&z=456', "templated endpoint with fqdn host");
is($r->endpoint("http://my.fqdn"), 'http://my.fqdn/v1.2/d/2/b/2/c/d/e?y=123&z=456', "templated endpoint with url host w/o version");
is($r->endpoint("http://my.fqdn/v3.5"), 'http://my.fqdn/v3.5/d/2/b/2/c/d/e?y=123&z=456', "templated endpoint with url host w version");
is($r->{endpoint}, $oendpt, "endpoint after templating");

delete $r->{tpls}->{d};
ok(!defined($r->endpoint), "failed endpoint templating returns undef");
is($r->{endpoint}, $oendpt, "endpoint after failed templating");
ok(!$r, "false request after failed templating");
is($r->{error}, "Missing template d data to replace endpoint $oendpt", "error after failed templating");


=head1 opts data

=cut

# get data
my $client = testapi->new();
$client->{versions}->{theservice} = 'v3.1';
my $resp = $client->api_theservice_humanreadable(user => 'auser', int => 1, name => 'thename');
my $req = $resp->{req};
isa_ok($req, 'Net::OpenStack::Client::Request',
       "client method called returned AUTOLOADed response with call to rest method");

is_deeply($req->opts_data, {something => {name => 'thename', int => 1}}, "Request opts_data returns hashref");

$resp = $client->api_theservice_humanreadable(user => 'auser', int => 1, name => 'thename', raw => {what => 'ever'});
is_deeply($resp->{req}->opts_data, {what => 'ever'}, "Request opts_data returns raw hashref ignoring all options");

=head1 headers

=cut

is_deeply($r->headers(), {
    Accept => 'application/json, text/plain',
    'Accept-Encoding' => 'identity, gzip, deflate, compress',
    'Content-Type' => 'application/json',
}, "headers without args returns default headers");


is_deeply($r->headers(token => 123, headers => {test => 1, Accept => undef}), {
    'Accept-Encoding' => 'identity, gzip, deflate, compress',
    'Content-Type' => 'application/json',
    'X-Auth-Token' => 123,
    test => 1,
}, "headers with token and custom headers");

done_testing();
