use Test::Lib;
use Test::Net::SAML2;
use Net::SAML2::IdP;

my $xml = path('t/idp-metadata2.xml')->slurp;

my $idp = Net::SAML2::IdP->new_from_xml(
    xml => $xml,
    cacert => 't/cacert.pem',
);
isa_ok($idp, 'Net::SAML2::IdP');

is(
    $idp->sso_url($idp->binding('redirect')),
    'http://sso.dev.venda.com/opensso/SSORedirect/metaAlias/idp',
    'Found SSO redirect binding'
);

is(
    $idp->slo_url($idp->binding('redirect')),
    'http://sso.dev.venda.com/opensso/IDPSloRedirect/metaAlias/idp',
    'Found SLO redirect binding'
);

is(
    $idp->art_url($idp->binding('soap')),
    'http://sso.dev.venda.com/opensso/ArtifactResolver/metaAlias/idp',
    'Found SSO artifact binding'
);

looks_like_a_cert($idp->cert('signing'));

is(
    $idp->entityid,
    'http://sso.dev.venda.com/opensso',
    "Found correct entity id"
);

done_testing;
