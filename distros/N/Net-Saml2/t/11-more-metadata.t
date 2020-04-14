use Test::More;
use Net::SAML2;
use File::Slurp;

my $xml = read_file('t/idp-metadata2.xml');

my $idp = Net::SAML2::IdP->new_from_xml( xml => $xml, cacert => 't/cacert.pem' );
ok($idp);

ok($idp->sso_url($idp->binding('redirect')));
ok($idp->slo_url($idp->binding('redirect')));
ok($idp->art_url($idp->binding('soap')));

ok($idp->cert('signing'));
ok($idp->entityid eq 'http://sso.dev.venda.com/opensso');

done_testing;
