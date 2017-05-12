use strict;
use Test::More tests => 7;


use OpenID::Lite::RelyingParty::CheckID::Request;
use OpenID::Lite::RelyingParty::Discover::Service;
use OpenID::Lite::Association;
use OpenID::Lite::Extension::SREG::Request;
use OpenID::Lite::Extension::SREG::Response;
use OpenID::Lite::Provider::Response;
use OpenID::Lite::Provider::AssociationBuilder;
use URI::Escape;
use URI;

my $service = OpenID::Lite::RelyingParty::Discover::Service->new;
$service->claimed_identifier( q{http://localhost/openid/user} );
$service->op_local_identifier( q{http://localhost/openid/user} );
$service->add_type( q{http://specs.openid.net/auth/2.0/signon} );
$service->add_uri( q{http://localhost/openid/endpoint} );

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

my $sreg = OpenID::Lite::Extension::SREG::Request->new;
$sreg->request_field('nickname', 1);
$sreg->request_field('fullname', 1);
$sreg->request_field('dob',      0);
$sreg->request_field('email',    1);

$sreg->policy_url(q{http://example.com/});


$checkid->add_extension( $sreg );

my $url = $checkid->redirect_url(
    return_to => q{http://example.com/return_to},
    realm     => q{http://example.com/},
);
my $query = URI->new($url)->query;
my %p;
for my $pair ( split /&/, $query ) {
    my ($k, $v) = split(/=/, $pair);
    $k = URI::Escape::uri_unescape($k);
    $v = URI::Escape::uri_unescape($v);
    $p{$k} = $v;
}
is($p{'openid.sreg.required'}, 'nickname,fullname,email');
is($p{'openid.sreg.optional'}, 'dob');
is($p{'openid.sreg.policy_url'}, 'http://example.com/');


my $params = $checkid->_params->copy();

my $op_res = OpenID::Lite::Provider::Response->new(
    type          => 'setup',
    req_params    => $params,
    res_params    => $params,
    setup_url     => q{http://localhost/openid/setup},
    endpoint_url  => q{http://localhost/openid/endpoint},
    assoc_builder => OpenID::Lite::Provider::AssociationBuilder->new,
);

my $req = OpenID::Lite::Extension::SREG::Request->from_provider_response($op_res);
ok($req);
my $data = {
    nickname => 'foo',
    fullname => 'bar',
};
my $res = OpenID::Lite::Extension::SREG::Response->extract_response($req, $data);
$op_res->add_extension( $res );
my $res_url = $op_res->make_signed_url();
#is($res_url, '');
like($res_url, qr/openid\.sreg\.fullname\=bar/);
like($res_url, qr/openid\.sreg\.nickname\=foo/);
unlike($res_url, qr/openid\.sreg\.email\=/);
