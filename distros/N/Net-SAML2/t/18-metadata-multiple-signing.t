use Test::Lib;
use Test::Net::SAML2;
use Net::SAML2::IdP;

my $xml = path('t/data/idp-metadata-multiple-signing.xml')->slurp;

my $idp = Net::SAML2::IdP->new_from_xml(
    xml => $xml,
    cacert => 't/data/cacert-google.pem',
);
isa_ok($idp, 'Net::SAML2::IdP');

is(
    $idp->sso_url($idp->binding('redirect')),
    'https://accounts.google.com/o/saml2/idp?idpid=C01nccos6',
    'Found SSO redirect binding'
);

is(
    $idp->slo_url($idp->binding('redirect')),
    undef,
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
    'https://accounts.google.com/o/saml2?idpid=C01nccos6',
    "Found correct entity id"
);

done_testing;
