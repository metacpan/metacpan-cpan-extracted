package Test::Net::SAML2::RequestedAttribute;
use Moose;

extends 'Net::SAML2::RequestedAttribute';

around _build_attributes => sub {
  my $orig = shift;
  my $self = shift;

  my %attrs = $self->$orig();

  $attrs{Some} = 'Other';

  return %attrs;
};

package main;

use strict;
use warnings;
use Test::Lib;
use Test::Net::SAML2;
use URN::OASIS::SAML2 qw(URN_METADATA);

my $requested_attribute = Net::SAML2::RequestedAttribute->new(
  name => 'some:urn:here'
);

my $xpath = get_xpath(
    $requested_attribute->to_xml,
    md => URN_METADATA,
);

my $node = get_single_node_ok($xpath, '/md:RequestedAttribute');
is($node->getAttribute('Name'), 'some:urn:here', ".. with the correct name");
ok(!$node->getAttribute('isRequired'), ".. and isn't required");
ok(!$node->getAttribute('FriendlyName'), ".. and w/out friendly name");
ok(!$node->getAttribute('Some'), ".. and w/out additional attribute");

$requested_attribute = Net::SAML2::RequestedAttribute->new(
    name          => 'some:urn:here',
    required      => 1,
    friendly_name => 'My main man',
);

$xpath = get_xpath(
    $requested_attribute->to_xml,
    md => URN_METADATA,
);

$node = get_single_node_ok($xpath, '/md:RequestedAttribute');
is($node->getAttribute('Name'), 'some:urn:here', ".. with the correct name");
ok($node->getAttribute('isRequired'), ".. and is required");
is($node->getAttribute('FriendlyName'),
    "My main man", ".. and w/ friendly name");
ok(!$node->getAttribute('Some'), ".. and w/out additional attribute");

use Test::Net::SAML2::RequestedAttribute;

$requested_attribute = Test::Net::SAML2::RequestedAttribute->new(
  name => 'some:urn:here',
);

$xpath = get_xpath(
    $requested_attribute->to_xml,
    md => URN_METADATA,
);

$node = get_single_node_ok($xpath, '/md:RequestedAttribute');
is($node->getAttribute('Name'), 'some:urn:here', ".. with the correct name");
is($node->getAttribute('Some'),
    "Other", ".. and w/ additional attribute");


done_testing;
