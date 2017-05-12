use strict;
use warnings;
use Test::More;
use Net::SinaWeibo;
plan skip_all => 'Enviroment vars: SINA_APP_KEY / SINA_APP_SECRET not set!'
    unless $ENV{SINA_APP_KEY} && $ENV{SINA_APP_SECRET};

my $sina = Net::SinaWeibo->new(
    app_key => $ENV{SINA_APP_KEY},
    app_secret => $ENV{SINA_APP_SECRET},
);

my $authorize_url = $sina->get_authorize_url;
ok($authorize_url,'get_authorization_url');
diag("Go to :".$authorize_url);
diag('request_token:'.$sina->request_token->token);
diag('request_token_secret'.$sina->request_token->secret);
diag('==========================================');
diag('Open t/test.tokens,replace the oauth_verifier with the code you got.');
diag('Then,run 01oauth.t to got your access token');
$sina->save_tokens('t/test.tokens',
    app_key => $sina->app_key,
    app_secret => $sina->app_secret,
    _request_token => $sina->request_token->token,
    _request_token_secret => $sina->request_token->secret,
    oauth_verifier => 'replace this to the verifier',
    );
done_testing;
