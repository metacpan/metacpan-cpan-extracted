#!perl

use Net::OAuth::Yahoo;
use Data::Dumper;
use Test::More qw/no_plan/;

BEGIN { use_ok('Net::OAuth::Yahoo'); }

print "Please enter the consumer_key: ";
chomp( my $consumer_key = <STDIN> );
print "Please enter the consumer_secret: ";
chomp( my $consumer_secret = <STDIN> );
print "Please enter yahoo login to test with: ";
chomp( my $yahoo_login = <STDIN> );
print "Please enter yahoo password to test with: ";
chomp( my $yahoo_password = <STDIN> );
print "Please enter a Yahoo API URL to test with: ";
chomp( my $api_url = <STDIN> );
print "Please enter the filename of token (it will be cleaned up at the end of this test script): ";
chomp( my $file = <STDIN> );

my $oauth = Net::OAuth::Yahoo->new();
ok( $Net::OAuth::Yahoo::ERRMSG eq "_validate_params() failed", "_validate_params() test without params" );

my $args = {
    "consumer_key"     => $consumer_key,
    "consumer_secret"  => $consumer_secret,
    "signature_method" => "HMAC-SHA1",
    "nonce"            => "random_string",
    "callback"         => "oob",
};

$oauth = Net::OAuth::Yahoo->new($args);
my $url1 = $oauth->get("token_url");

ok( $url1 eq "https://api.login.yahoo.com/oauth/v2/get_token", "new() object creation test" );

my $request_token = $oauth->get_request_token();
my $obj_req_token = $oauth->get("request_token");
is_deeply( $request_token, $obj_req_token, "get_request_token() test" );

my $url = $oauth->request_auth();
ok( $Net::OAuth::Yahoo::ERRMSG eq "request_auth() did not receive a valid request token",
    "request_auth() test without URL" );

$url = $oauth->request_auth($request_token);
like( $url, qr/oauth_token/, "request_auth() test to see if URL is fetched properly" );

my $yid = {
    "login"  => $yahoo_login,
    "passwd" => $yahoo_password,
};

my $oauth_verifier = $oauth->sim_present_auth();
ok( $Net::OAuth::Yahoo::ERRMSG eq "sim_present_auth() did not receive correct set of params",
    "sim_present_auth() test without params" );

$oauth_verifier = $oauth->sim_present_auth( $url, $yid );
like( $oauth_verifier, qr/\w{6}/, "sim_present_auth() should return 6 word characters" );

my $token = $oauth->get_token();
ok( $Net::OAuth::Yahoo::ERRMSG eq "get_token() invoked without oauth_verifier", "get_token() test without params" );

$token = $oauth->get_token($oauth_verifier);
my $obj_token = $oauth->get("token");
is_deeply( $token, $obj_token, "get_token() test with oauth_verifier" );

$oauth->access_api();
ok( $Net::OAuth::Yahoo::ERRMSG eq "access_api() did not receive a token or URL", "access_api() test without params" );

my $json = $oauth->access_api( $token, $api_url );
like( $json, qr/yahoo/, "access_api() test with token & URL" );

$oauth->save_token();
ok( $Net::OAuth::Yahoo::ERRMSG eq "save_token() did not receive filename or, object did not have a token",
    "save_token() test without a filename" );

$oauth->save_token($file);
my $check;

if ( -f $file ) {
    $check = 1;
}
else {
    $check = 0;
}
is( $check, 1, "save_token() test with a filename" );

$oauth->load_token();
ok( $Net::OAuth::Yahoo::ERRMSG eq "load_token() could not find the file specified",
    "load_token() test without a filename" );

$oauth->load_token($file);
$obj_token = $oauth->get("token");
is_deeply( $token, $obj_token, "load_token() test.  compares token before saving and after loading" );

$oauth->test_token();
ok( $Net::OAuth::Yahoo::ERRMSG eq "test_token() did not receive the right params", "test_token() without params" );

my $ret = $oauth->test_token( $token, $url );
is( $ret, 1, "test_token() test with a token, url" );

unlink $file
