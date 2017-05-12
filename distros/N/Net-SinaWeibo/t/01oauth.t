use strict;
use warnings;
use 5.010;
use Test::More;
use Data::Dumper;

plan skip_all => 'Enviroment vars: SINA_APP_KEY / SINA_APP_SECRET not set!'
    unless $ENV{SINA_APP_KEY} && $ENV{SINA_APP_SECRET};

plan skip_all  => '00oauth.t not passed!' unless -e 't/test.tokens';

use Net::SinaWeibo;
my %tokens = Net::SinaWeibo->load_tokens('t/test.tokens');

my $sina = Net::SinaWeibo->new(
    app_key => $tokens{app_key},
    app_secret => $tokens{app_secret},
    tokens => {
        request_token => $tokens{_request_token},
        request_token_secret => $tokens{_request_token_secret},
    }
    );
my $access_token = $sina->get_access_token(
        verifier => $tokens{oauth_verifier}
    );

ok($access_token);
Net::SinaWeibo->save_tokens('t/test.tokens',
            app_key => $sina->consumer_key,
            app_secret => $sina->consumer_secret,
            oauth_verifier => $tokens{oauth_verifier},
            _access_token => $access_token->token,
            _access_token_secret => $access_token->secret,
        );
diag('access_token:'.$access_token->token.' access_token_secret:'.$access_token->secret);
diag('==========================================');
