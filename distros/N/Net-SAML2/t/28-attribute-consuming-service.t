use strict;
use warnings;
use Test::Lib;
use Test::Net::SAML2;
use URN::OASIS::SAML2 qw(URN_METADATA);

my $acs = Net::SAML2::AttributeConsumingService->new(
    service_name => 'Net::SAML2 testsuite',
    index        => 1,
    default      => 1,
);

my $attr = Net::SAML2::RequestedAttribute->new(name => 'thing');
$acs->add_attribute($attr);

my $xpath = get_xpath($acs->to_xml, md => URN_METADATA);
my $node  = get_single_node_ok($xpath, '/md:AttributeConsumingService');
is($node->getAttribute('index'), '1', ".. with the correct index");
ok($node->getAttribute('isDefault'), ".. and is the default");
$node
  = get_single_node_ok($xpath, '/md:AttributeConsumingService/md:ServiceName');
is(
    $node->textContent(),
    "Net::SAML2 testsuite",
    ".. and has the correct content"
);
is(
    $node->getAttribute('xml:lang'),
    "en",
    ".. and has the correct xml:lang"
);

$node = get_single_node_ok($xpath,
    '/md:AttributeConsumingService/md:RequestedAttribute');
is($node->getAttribute('Name'), 'thing', ".. with the correct name");


$acs = Net::SAML2::AttributeConsumingService->new(
    service_name        => 'Net::SAML2 testsuite',
    service_description => "Some thing",
    index               => 1,
    default             => 1,
);
$acs->add_attribute($attr);

$xpath = get_xpath($acs->to_xml, md => URN_METADATA);
$node  = get_single_node_ok($xpath, '/md:AttributeConsumingService');
is($node->getAttribute('index'), '1', ".. with the correct index");
ok($node->getAttribute('isDefault'), ".. and is the default");
$node
  = get_single_node_ok($xpath, '/md:AttributeConsumingService/md:ServiceName');
is(
    $node->textContent(),
    "Net::SAML2 testsuite",
    ".. and has the correct content"
);

$node = get_single_node_ok($xpath,
    '/md:AttributeConsumingService/md:ServiceDescription');
is($node->textContent(), "Some thing", ".. and has the correct content");

done_testing;
