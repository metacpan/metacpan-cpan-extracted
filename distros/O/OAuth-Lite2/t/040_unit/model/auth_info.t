use strict;
use warnings;

use Test::More; 

use lib 't/lib';

use TestAuthInfo;

# id user_id client_id
# scope refresh_token code redirect_uri server_state
# extra

my $info1 = TestAuthInfo->new(
    id            => q{foo},
    user_id       => q{bar},
    client_id     => q{buz},
    scope         => q{scope},
    refresh_token => q{r_t},
    code          => q{code},
    redirect_uri  => q{r_uri},
    server_state  => q{s_state},
    extra         => q{hoge},
);
is($info1->id,            q{foo});
is($info1->user_id,       q{bar});
is($info1->client_id,     q{buz});
is($info1->scope,         q{scope});
is($info1->refresh_token, q{r_t});
is($info1->code,          q{code});
is($info1->redirect_uri,  q{r_uri});
is($info1->server_state,  q{s_state});
is($info1->extra,         q{hoge});

done_testing;
