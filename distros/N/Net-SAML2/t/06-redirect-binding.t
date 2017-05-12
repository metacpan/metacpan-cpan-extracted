use Test::More;
use strict;
use warnings;
use Net::SAML2;
use MIME::Base64;
use Data::Dumper;
use File::Slurp;
use LWP::UserAgent;

my $sp = Net::SAML2::SP->new(
        id               => 'http://localhost:3000',
        url              => 'http://localhost:3000',
        cert             => 't/sign-nopw-cert.pem',
        cacert           => 't/cacert.pem',
        org_name         => 'Test',
        org_display_name => 'Test',
        org_contact      => 'test@example.com',
);
ok($sp);

my $metadata = read_file('t/idp-metadata.xml');
ok($metadata);
my $idp = Net::SAML2::IdP->new_from_xml( xml => $metadata, cacert => 't/cacert.pem' );
ok($idp);

my $sso_url = $idp->sso_url($idp->binding('redirect'));
ok($sso_url);
my $authnreq = $sp->authn_request(
    $idp->entityid,
    $idp->format('persistent'),
)->as_xml;
ok($authnreq);

my $redirect = $sp->sso_redirect_binding($idp, 'SAMLRequest');
ok($redirect);

my $location = $redirect->sign(
        $authnreq,
        'http://return/url',
);
ok($location);

my ($request, $relaystate) = $redirect->verify($location);
ok($request);
ok($relaystate);
ok($relaystate eq 'http://return/url');

done_testing;
