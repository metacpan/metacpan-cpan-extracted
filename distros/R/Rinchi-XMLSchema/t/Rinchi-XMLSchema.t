# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Rinchi-XMLSchema.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 17;
BEGIN { use_ok('Rinchi::XMLSchema') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use strict;
use Carp;
use XML::Parser;
use Rinchi::XMLSchema;
use Rinchi::XMLSchema::HFP;

my %element = (
  'enumeration'         => 0,
  'fractionDigits'      => 0,
  'length'              => 0,
  'list'                => 0,
  'maxExclusive'        => 0,
  'maxInclusive'        => 0,
  'maxLength'           => 0,
  'minExclusive'        => 0,
  'minInclusive'        => 0,
  'minLength'           => 0,
  'pattern'             => 0,
  'restriction'         => 0,
  'simpleType'          => 0,
  'totalDigits'         => 0,
  'union'               => 0,
  'whiteSpace'          => 0,
);

my $element_ct = 16;

my %type = (
  'ENTITIES'            => 0,
  'ENTITY'              => 0,
  'ID'                  => 0,
  'IDREF'               => 0,
  'IDREFS'              => 0,
  'NCName'              => 0,
  'NMTOKEN'             => 0,
  'NMTOKENS'            => 0,
  'NOTATION'            => 0,
  'Name'                => 0,
  'QName'               => 0,
  'anyURI'              => 0,
  'base64Binary'        => 0,
  'boolean'             => 0,
  'byte'                => 0,
  'date'                => 0,
  'dateTime'            => 0,
  'decimal'             => 0,
  'derivationControl'   => 0,
  'double'              => 0,
  'duration'            => 0,
  'facet'               => 0,
  'float'               => 0,
  'gDay'                => 0,
  'gMonth'              => 0,
  'gMonthDay'           => 0,
  'gYear'               => 0,
  'gYearMonth'          => 0,
  'hexBinary'           => 0,
  'int'                 => 0,
  'integer'             => 0,
  'language'            => 0,
  'localSimpleType'     => 0,
  'long'                => 0,
  'negativeInteger'     => 0,
  'noFixedFacet'        => 0,
  'nonNegativeInteger'  => 0,
  'nonPositiveInteger'  => 0,
  'normalizedString'    => 0,
  'numFacet'            => 0,
  'positiveInteger'     => 0,
  'short'               => 0,
  'simpleDerivationSet' => 0,
  'simpleType'          => 0,
  'string'              => 0,
  'time'                => 0,
  'token'               => 0,
  'topLevelSimpleType'  => 0,
  'unsignedByte'        => 0,
  'unsignedInt'         => 0,
  'unsignedLong'        => 0,
  'unsignedShort'       => 0,
);

my $type_ct = 52;

my %group = (
  'facets'              => 0,
  'simpleDerivation'    => 0,
  'simpleRestrictionModel' => 0,
);

my $group_ct = 3;

my $nsdef = Rinchi::XMLSchema::HFP->namespace_def();

$nsdef->{'Prefix'} = 'hfp';

Rinchi::XMLSchema->add_namespace($nsdef);
my $Document = Rinchi::XMLSchema->parsefile('test_src/datatypes.xsd');

my $elements = $Document->elements();
my $ct = 0;

foreach my $key (sort keys %{$elements}) {
  $element{$key}++;
  $ct++;
}

ok($ct == $element_ct, "  datatypes element count: $ct == $element_ct");

$ct = 0;
my $tot = 0;

foreach my $key (sort keys %{$elements}) {
  $tot += $element{$key};
  $ct++;
}

ok($ct == $tot, "  datatypes element total: $ct == $tot");

my $types = $Document->types();
$ct = 0;

foreach my $key (sort keys %{$types}) {
  $type{$key}++;
  $ct++;
}

ok($ct == $type_ct, "  datatypes type count: $ct == $type_ct");

$ct = 0;
$tot = 0;

foreach my $key (sort keys %{$types}) {
  $tot += $type{$key};
  $ct++;
}

ok($ct == $tot, "  datatypes type total: $ct == $tot");

my $groups = $Document->groups();
$ct = 0;

foreach my $key (sort keys %{$groups}) {
  $group{$key}++;
  $ct++;
}

ok($ct == $group_ct, "  datatypes group count: $group_ct");

$ct = 0;
$tot = 0;

foreach my $key (sort keys %{$groups}) {
  $tot += $group{$key};
  $ct++;
}

ok($ct == $tot, "  datatypes group total: $ct == $tot");

# test parse of schema.xsd

%element = (
  'all'                         => 0,
  'annotation'                  => 0,
  'any'                         => 0,
  'anyAttribute'                => 0,
  'appinfo'                     => 0,
  'attribute'                   => 0,
  'attributeGroup'              => 0,
  'choice'                      => 0,
  'complexContent'              => 0,
  'complexType'                 => 0,
  'documentation'               => 0,
  'element'                     => 0,
  'field'                       => 0,
  'group'                       => 0,
  'import'                      => 0,
  'include'                     => 0,
  'key'                         => 0,
  'keyref'                      => 0,
  'notation'                    => 0,
  'redefine'                    => 0,
  'schema'                      => 0,
  'selector'                    => 0,
  'sequence'                    => 0,
  'simpleContent'               => 0,
  'unique'                      => 0,
);
$element_ct = 25;

%type = (
  'all'                         => 0,
  'allNNI'                      => 0,
  'annotated'                   => 0,
  'anyType'                     => 0,
  'attribute'                   => 0,
  'attributeGroup'              => 0,
  'attributeGroupRef'           => 0,
  'blockSet'                    => 0,
  'complexRestrictionType'      => 0,
  'complexType'                 => 0,
  'derivationSet'               => 0,
  'element'                     => 0,
  'explicitGroup'               => 0,
  'extensionType'               => 0,
  'formChoice'                  => 0,
  'fullDerivationSet'           => 0,
  'group'                       => 0,
  'groupRef'                    => 0,
  'keybase'                     => 0,
  'localComplexType'            => 0,
  'localElement'                => 0,
  'namedAttributeGroup'         => 0,
  'namedGroup'                  => 0,
  'namespaceList'               => 0,
  'narrowMaxMin'                => 0,
  'openAttrs'                   => 0,
  'public'                      => 0,
  'realGroup'                   => 0,
  'reducedDerivationControl'    => 0,
  'restrictionType'             => 0,
  'simpleExplicitGroup'         => 0,
  'simpleExtensionType'         => 0,
  'simpleRestrictionType'       => 0,
  'topLevelAttribute'           => 0,
  'topLevelComplexType'         => 0,
  'topLevelElement'             => 0,
  'typeDerivationControl'       => 0,
  'wildcard'                    => 0,
);
$type_ct = 38;

%group = (
  'allModel'                    => 0,
  'attrDecls'                   => 0,
  'complexTypeModel'            => 0,
  'identityConstraint'          => 0,
  'nestedParticle'              => 0,
  'particle'                    => 0,
  'redefinable'                 => 0,
  'schemaTop'                   => 0,
  'typeDefParticle'             => 0,
);
$group_ct = 9;

my %attributeGroup = (
  'defRef'                      => 0,
  'occurs'                      => 0,
);
my $attributeGroup_ct = 2;

my %identityConstraint = (
  'attribute'                   => 0,
  'attributeGroup'              => 0,
  'element'                     => 0,
  'group'                       => 0,
  'identityConstraint'          => 0,
  'notation'                    => 0,
  'type'                        => 0,
);
my $identityConstraint_ct = 7;

$Document = Rinchi::XMLSchema->parsefile('test_src/schema.xsd');

$elements = $Document->elements();
$ct = 0;

foreach my $key (sort keys %{$elements}) {
  $element{$key}++;
  $ct++;
}

ok($ct == $element_ct, "  datatypes element count: $ct == $element_ct");

$ct = 0;
$tot = 0;

foreach my $key (sort keys %{$elements}) {
  $tot += $element{$key};
  $ct++;
}

ok($ct == $tot, "  datatypes element total: $ct == $tot");

$types = $Document->types();
$ct = 0;

foreach my $key (sort keys %{$types}) {
  $type{$key}++;
  $ct++;
}

ok($ct == $type_ct, "  datatypes type count: $ct == $type_ct");

$ct = 0;
$tot = 0;

foreach my $key (sort keys %{$types}) {
  $tot += $type{$key};
  $ct++;
}

ok($ct == $tot, "  datatypes type total: $ct == $tot");

$groups = $Document->groups();
$ct = 0;

foreach my $key (sort keys %{$groups}) {
  $group{$key}++;
  $ct++;
}

ok($ct == $group_ct, "  datatypes group count: $group_ct");

$ct = 0;
$tot = 0;

foreach my $key (sort keys %{$groups}) {
  $tot += $group{$key};
  $ct++;
}

ok($ct == $tot, "  datatypes group total: $ct == $tot");

my $attributeGroups = $Document->attributeGroups();
$ct = 0;

foreach my $key (sort keys %{$attributeGroups}) {
  $attributeGroup{$key}++;
  $ct++;
}

ok($ct == $attributeGroup_ct, "  datatypes attributeGroup count: $attributeGroup_ct");

$ct = 0;
$tot = 0;

foreach my $key (sort keys %{$attributeGroups}) {
  $tot += $attributeGroup{$key};
  $ct++;
}

ok($ct == $tot, "  datatypes attributeGroup total: $ct == $tot");

my $identityConstraints = $Document->identityConstraints();
$ct = 0;

foreach my $key (sort keys %{$identityConstraints}) {
  $identityConstraint{$key}++;
  $ct++;
}

ok($ct == $identityConstraint_ct, "  datatypes identityConstraint count: $identityConstraint_ct");

$ct = 0;
$tot = 0;

foreach my $key (sort keys %{$identityConstraints}) {
  $tot += $identityConstraint{$key};
  $ct++;
}

ok($ct == $tot, "  datatypes identityConstraint total: $ct == $tot");


