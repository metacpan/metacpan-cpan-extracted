use Test::More;
use strict;
use warnings;
use Net::SAML2;
use MIME::Base64;
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
my $slo_url = $idp->slo_url($idp->binding('soap'));
ok($slo_url);
my $idp_cert = $idp->cert('signing');
ok($idp_cert);

my $nameid = 'user-to-log-out';
my $session = 'session-to-log-out';

my $request = $sp->logout_request(
        $idp->entityid, $nameid, $idp->format('persistent'), $session,
);
ok($request);
my $request_xml = $request->as_xml;
ok($request_xml);

my $ua = LWP::UserAgent->new; # not used
my $soap = $sp->soap_binding($ua, $slo_url, $idp_cert);
ok($soap);

my $soap_req = $soap->create_soap_envelope($request_xml);
ok($soap_req);

my ($subject, $xml) = $soap->handle_request($soap_req);
ok($subject);
ok($xml);

my $soaped_request = Net::SAML2::Protocol::LogoutRequest->new_from_xml(
        xml => $xml
);
ok($soaped_request);
isa_ok($soaped_request, 'Net::SAML2::Protocol::LogoutRequest');
ok($soaped_request->session eq $request->session);
ok($soaped_request->nameid eq $request->nameid);

done_testing;
