use Test::More;
use Net::SAML2;

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
ok($sp->metadata);

my $xml = $sp->metadata;
my $xpath = XML::XPath->new( xml => $xml );
$xpath->set_namespace('md', 'urn:oasis:names:tc:SAML:2.0:metadata');

my @ssos = $xpath->findnodes('//md:EntityDescriptor/md:SPSSODescriptor/md:AssertionConsumerService');
ok($ssos[0]->getAttribute('Binding') eq 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST');

done_testing;
