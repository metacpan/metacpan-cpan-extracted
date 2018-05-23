use FindBin qw($Bin);

use lib "$Bin/../lib";
use lib "$Bin/lib";

use Test::More;

use qbit;

use TestWebInterface;

my $wi = TestWebInterface->new();

#######
# GET #
#######

my $response = $wi->get_response(test => cmd1 => {a => 1, b => 2});

is($wi->request->uri(), '/test/cmd1?a=1&b=2', 'uri()',);

is($wi->request->url(), 'http://Test:0/test/cmd1?a=1&b=2', 'url()',);

is($wi->request->url(no_uri => TRUE), 'http://Test:0', 'url( no_uri => TRUE )',);

is($wi->request->query_string(), 'a=1&b=2', 'query_string()',);

is($wi->request->param('a'), 1, 'query field "a"');
is($wi->request->param('b'), 2, 'query field "b"');

############################
# POST multipart/form-data #
############################

$wi->get_response(
    test => cmd1 => {hello => 'Привет world'},    # uri escape in QBit::WebInterface::Test
    method => 'POST',
    headers =>
      {'content-type' => "multipart/form-data;\nboundary=---------------------------11072014641901240981700179587"},
    stdin => q{-----------------------------11072014641901240981700179587
Content-Disposition: form-data; name="field_w_plus"

test + test
-----------------------------11072014641901240981700179587
Content-Disposition: form-data; name="field"

test
-----------------------------11072014641901240981700179587
Content-Disposition: form-data; name="file"; filename="testfile"
Content-Type: application/octet-stream

Test file content
-----------------------------11072014641901240981700179587--}
);

is($wi->request->param('field'),        'test',               'Multipart form data field');
is($wi->request->param('field_w_plus'), 'test + test',        'Multipart form data field with + in value');
is($wi->request->param('hello'),        'Привет world', 'query field "hello"');

is_deeply(
    $wi->request->param('file'),
    {
        content  => 'Test file content',
        filename => 'testfile'
    },
    'Multipart form data file field'
);

###################################################
# POST multipartapplication/x-www-form-urlencoded #
###################################################

$wi->get_response(
    test    => cmd1 => {},
    method  => 'POST',
    headers => {'content-type' => "application/x-www-form-urlencoded"},
    stdin   => q{a=1&b=2}
);

is($wi->request->param('a'), 1, 'form-urlencoded field "a"');
is($wi->request->param('b'), 2, 'form-urlencoded field "b"');

#########################
# POST application/json #
#########################

$wi->get_response(
    test    => cmd1 => {},
    method  => 'POST',
    headers => {'content-type' => "application/json"},
    stdin   => q{{"sum":"1 + 2 = 3"}}
);

is(from_json($wi->request->param(''))->{'sum'}, '1 + 2 = 3', 'json');

done_testing();
