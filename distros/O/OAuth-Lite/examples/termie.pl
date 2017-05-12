#!/usr/bin/perl

use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');

use OAuth::Lite::Consumer;
use OAuth::Lite::AuthMethod;
use Data::Dumper;
use Perl6::Say;

# Example with
# http://term.ie/oauth/example/

my $consumer_key    = 'key';
my $consumer_secret = 'secret';

my $request_token_url = 'http://term.ie/oauth/example/request_token.php';
my $access_token_url  = 'http://term.ie/oauth/example/access_token.php';

my $resource_url = 'http://term.ie/oauth/example/echo_api.php';

my $consumer = OAuth::Lite::Consumer->new(
    consumer_key     => $consumer_key,
    consumer_secret  => $consumer_secret,
    signature_method => 'HMAC-SHA1',
    #signature_method => 'PLAINTEXT',
    http_method      => 'GET',
    auth_method      => OAuth::Lite::AuthMethod::URL_QUERY,
    #auth_method      => OAuth::Lite::AuthMethod::AUTH_HEADER,
);

say "start to get request token";

my $rtoken = $consumer->get_request_token( url => $request_token_url )
    or die $consumer->errstr;

say $rtoken->token;
say $rtoken->secret;

say "start to get access token";

my $atoken = $consumer->get_access_token( url => $access_token_url, token => $rtoken )
    or die $consumer->errstr;
say $atoken->token;
say $atoken->secret;

say Dumper($consumer->oauth_response);

my $res = $consumer->request(
    method  => 'GET',
    url     => $resource_url,
    token   => $atoken,
);

say Dumper($res);
say $res->content;
