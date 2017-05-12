use strict;
use Test::More tests => 7;


use OpenID::Lite::RelyingParty::CheckID::Request;
use OpenID::Lite::RelyingParty::Discover::Service;
use OpenID::Lite::Association;
use OpenID::Lite::Extension::UI::Request;
use OpenID::Lite::Provider::Response;

my $service = OpenID::Lite::RelyingParty::Discover::Service->new;
$service->claimed_identifier( q{http://localhost/openid/user} );
$service->op_local_identifier( q{http://localhost/openid/user} );
$service->add_type( q{http://specs.openid.net/auth/2.0/signon} );
$service->add_uri( q{http://localhost/openid/endpoint} );

#nBU36Zn5P6MfFzRsL2IKrwUYvA0=
my $assoc = OpenID::Lite::Association->new(
    expires_in => 1209600,
    handle     => "1246414277:HMAC-SHA1:49NIG8sn99Tc2fp0QNuZ:d60c3afc89",
    issued     => 1246413115,
    secret     => pack("H*","9c1537e999f93fa31f17346c2f620aaf0518bc0d"),
    type       => "HMAC-SHA1",
);

my $checkid = OpenID::Lite::RelyingParty::CheckID::Request->new(
    association => $assoc,
    service     => $service,
);

my $ui = OpenID::Lite::Extension::UI::Request->new;
$ui->mode('popup');
$ui->lang('en-US');

$checkid->add_extension( $ui );

my $url = $checkid->redirect_url(
    return_to => q{http://example.com/return_to},
    realm     => q{http://example.com/},
);

like($url, qr/openid\.ui\.mode\=popup/);
unlike($url, qr/openid\.ui\.mode\=hoge/);
like($url, qr/openid\.ui\.lang\=en\-US/);
unlike($url, qr/openid\.ui\.lang\=ja\-JP/);


my $params = $checkid->_params->copy();

my $op_res = OpenID::Lite::Provider::Response->new(
    type          => 'setup',
    req_params    => $params,
    res_params    => $params,
    setup_url     => q{http://localhost/openid/setup},
    endpoint_url  => q{http://localhost/openid/endpoint},
);

my $req = OpenID::Lite::Extension::UI::Request->from_provider_response($op_res);
ok($req);
is($req->mode, 'popup');
is($req->lang, 'en-US');


