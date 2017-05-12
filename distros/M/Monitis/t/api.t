use lib 't/lib';
use Test::Monitis;
require HTTP::Response;

plan tests => 7 + scalar(keys %{$Monitis::MAPPING}) * 2;

my $api = new_ok 'Monitis';

foreach my $pkg (keys %{$Monitis::MAPPING}) {
    ok $api->$pkg(), "mapping $pkg";
    like $api->context, qr/\Q$Monitis::MAPPING->{$pkg}\E$/, "mapped $pkg";
}

my $response = HTTP::Response->new;
$response->content(<<END);
{ "foo": "bar", "baz": [1,2,3] }
END

my $json = $api->parse_response($response);

is_deeply $json, {foo => 'bar', baz => [1, 2, 3]}, 'parse_response works';

# Set fake keys
$api->api_key('API_KEY');
my $request = $api->build_get_request(
    actionName => [param1 => 'value1', param2 => 'value2']);

isa_ok $request, 'HTTP::Request', 'build_get_request';
is $request->method, 'GET', 'request method';

# Set fake secret
$api->secret_key('SECRET_KEY');

$request = $api->build_post_request(
    actionName => [param1 => 'value1', param2 => 'value2']);

isa_ok $request, 'HTTP::Request', 'build_post_request';
is $request->method, 'POST', 'request method';
is $request->uri, $api->api_url, 'request url';
