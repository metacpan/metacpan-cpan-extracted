use strict;
use Carp;
use XML::Parser;
use Rinchi::XMLSchema;
use Rinchi::XMLSchema::HFP;

#print $XML::Parser::VERSION,"\n";

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

$Data::Dumper::Indent = 1;

Rinchi::XMLSchema->add_namespace($nsdef);
my $Document = Rinchi::XMLSchema->parsefile('test_src/datatypes.xsd');

my $elements = $Document->elements();
my $ct = 0;

foreach my $key (sort keys %{$elements}) {
  $ct++;
}

my $types = $Document->types();
my $ct = 0;

foreach my $key (sort keys %{$types}) {
  $ct++;
}


my $groups = $Document->groups();
my $ct = 0;

foreach my $key (sort keys %{$groups}) {
  $ct++;
}


