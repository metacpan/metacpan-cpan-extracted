use strict;
use warnings;

use Test::More;
use OIDC::Lite::Server::DataHandler;

my $dh = OIDC::Lite::Server::DataHandler->new;
ok($dh);

# all methods are abstruct
eval {
    $dh->validate_client_for_authorization(q{foo}, q{bar});
};
ok($@);
$@ = undef;

eval {
    $dh->validate_redirect_uri(q{client_id}, q{redirect_uri});
};
ok($@);
$@ = undef;

eval {
    $dh->validate_scope(q{client_id}, q{scope});
};
ok($@);
$@ = undef;

eval {
    $dh->validate_display(q{display});
};
ok($@);
$@ = undef;

eval {
    $dh->validate_prompt(q{prompt});
};
ok($@);
$@ = undef;

eval {
    $dh->validate_max_age(q{param});
};
ok($@);
$@ = undef;

eval {
    $dh->validate_ui_locales(q{ui_locales});
};
ok($@);
$@ = undef;

eval {
    $dh->validate_claims_locales(q{claims_locales});
};
ok($@);
$@ = undef;

eval {
    $dh->validate_id_token_hint(q{param});
};
ok($@);
$@ = undef;

eval {
    $dh->validate_login_hint(q{param});
};
ok($@);
$@ = undef;

eval {
    $dh->validate_acr_values(q{param});
};
ok($@);
$@ = undef;

eval {
    $dh->validate_request(q{param});
};
ok($@);
$@ = undef;

eval {
    $dh->validate_request_uri(q{param});
};
ok($@);
$@ = undef;

eval {
    $dh->get_user_id_for_authorization;
};
ok($@);
$@ = undef;

eval {
    $dh->create_id_token;
};
ok($@);
$@ = undef;

eval {
    $dh->create_or_update_auth_info;
};
ok($@);

my $ret = $dh->validate_server_state;
ok(!$ret);

$ret = $dh->require_server_state;
ok(!$ret);

done_testing;
