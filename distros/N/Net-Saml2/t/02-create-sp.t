use Test::Lib;
use Test::Net::SAML2;

my $sp = net_saml2_sp();

my $xpath = get_xpath(
    $sp->metadata,
    md => 'urn:oasis:names:tc:SAML:2.0:metadata'
);

my @ssos = $xpath->findnodes(
    '//md:EntityDescriptor/md:SPSSODescriptor/md:AssertionConsumerService');

if (is(@ssos, 2, "Got two assertionConsumerService(s)")) {
    is(
        $ssos[0]->getAttribute('Binding'),
        'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST',
        "Returns the correct binding: HTTP-POST"
    );
    is(
        $ssos[1]->getAttribute('Binding'),
        'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact',
        "Returns the correct binding: HTTP-Artifact"
    );
}

done_testing;
