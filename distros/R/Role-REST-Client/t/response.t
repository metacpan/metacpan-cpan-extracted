use strict;
use warnings;
use Test::More;
use HTTP::Response;

eval 'use JSON';
if ($@) {
	plan skip_all => 'Install JSON to run this test';
} else {
	plan tests => 12
};

use_ok( 'Role::REST::Client::Serializer' );
use_ok( 'Role::REST::Client::Response' );


{
    package MyResponse;
    use Moose;
    extends 'Role::REST::Client::Response';

    sub foo { 1  }
}

{
    package MyClient;
    use Moose;
    use Role::REST::Client;
    with 'Role::REST::Client';

    sub _rest_response_class { 'MyResponse' }
}

# test JSON hashes / arrays
my $jtype = 'application/json';
my $json_array = '["foo","bar"]';
my $array_data = [qw/foo bar/];

ok (my $serializer = Role::REST::Client::Serializer->new(type => $jtype), "New $jtype type serializer");
is($serializer->content_type, $jtype, 'Content Type');
ok(my $sdata = $serializer->serialize($array_data), 'Serialize');
is($sdata, $json_array, 'Serialize data');

ok(my $res = Role::REST::Client::Response->new(
    code => 200,
    response => HTTP::Response->new,
    data => sub { $serializer->deserialize($sdata) },
), 'response accepted');
is_deeply($res->data, $array_data, 'Deserialize');
ok($res = Role::REST::Client::Response->new(
    code => 500,
    response => HTTP::Response->new,
    error => 'Internal Server Error',
), 'error response accepted');
is_deeply($res->data, {}, 'empty hashref if the response was unsuccessful');

sub Mock::UA::request { shift(@{$_[0]->{responses}}) }

my $client = MyClient->new('server' => 'bar');
my $response = $client->get('/foo');

isa_ok($response, 'MyResponse', 'proper response class returned');
ok($response->can('foo'), 'custom response method included');
