use Test::More tests => 4;
use lib '../lib';

use_ok( 'SimpleDB::Client' );

my $http = SimpleDB::Client->new(secret_key=>'secretxx', access_key=>'accessyy');

isa_ok($http, 'SimpleDB::Client');

my $request = $http->construct_request('DoSomething',{foo=>'bar'});

isa_ok($request, 'HTTP::Request');

like($request->content, qr/^AWSAccessKeyId=accessyy&Action=DoSomething&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=\d{4}-\d{2}-\d{2}T\d{2}%3A\d{2}%3A\d{2}\.000Z&Version=2009-04-15&foo=bar&Signature=[A-Za-z0-9\%]+%3D$/, "request document looks good");



# everything else requires a connection
