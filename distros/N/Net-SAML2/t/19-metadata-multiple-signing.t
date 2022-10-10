use Test::Lib;
use Test::Net::SAML2;
use Net::SAML2::IdP;

my $xml = path('t/data/idp-metadata-multiple-signing-azure.xml')->slurp;

my $idp = Net::SAML2::IdP->new_from_xml(
    xml => $xml,
    cacert => 't/data/cacert-azure.pem',
);
isa_ok($idp, 'Net::SAML2::IdP');

is(
    $idp->sso_url($idp->binding('redirect')),
    'https://login.microsoftonline.com/239f867f-feea-452e-a800-6859e696161c/saml2',
    'Found SSO redirect binding'
);

is(
    $idp->sso_url($idp->binding('post')),
    'https://login.microsoftonline.com/239f867f-feea-452e-a800-6859e696161c/saml2',
    'Found SSO POST binding'
);

is(
    $idp->slo_url($idp->binding('redirect')),
    'https://login.microsoftonline.com/239f867f-feea-452e-a800-6859e696161c/saml2',
    'Found SLO redirect binding'
);

is(
    $idp->art_url($idp->binding('soap')),
    undef,
    'Found SSO artifact binding'
);

foreach my $use (keys %{$idp->certs}) {
    for my $cert (@{$idp->certs->{$use}}) {
        looks_like_a_cert($cert);
    }
};

is(
    $idp->entityid,
    'https://sts.windows.net/239f867f-feea-452e-a800-6859e696161c/',
    "Found correct entity id"
);

done_testing;
