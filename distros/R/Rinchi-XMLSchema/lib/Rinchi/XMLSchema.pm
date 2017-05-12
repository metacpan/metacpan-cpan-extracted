package Rinchi::XMLSchema;

use 5.006;
use strict;
use strict;
use Carp;
use XML::Parser;
#use Class::ISA;

our @ISA = qw();

our @EXPORT = qw();
our @EXPORT_OK = qw();

our $VERSION = 0.02;

=head1 NAME

Rinchi::XMLSchema - Module for creating XML Schema objects from XSD files.

=head1 SYNOPSIS

  use Rinchi::XMLSchema;

  $document = Rinchi::XMLSchema->parse($file);

=head1 DESCRIPTION

  This module parses XML Schema files and produces Perl objects representing 
  them. There is also the capability to compare objects to see if they are the 
  same (not necessarily equal). The intent of this module is to allow the 
  comparison of various schemas to find common constructs between them. A 
  module I intend to release later will allow the production of UML from
  schema files.
  
  Note: Imports and includes are not performed as at this time that would be
  contrary to the purpose of the module.

=head2 EXPORT

None by default.

=cut

my %sax_handlers = (
  'Init'         => \&handle_init,
  'Final'        => \&handle_final,
  'Start'        => \&handle_start,
  'End'          => \&handle_end,
  'Char'         => \&handle_char,
  'Proc'         => \&handle_proc,
  'Comment'      => \&handle_comment,
  'CdataStart'   => \&handle_cdata_start,
  'CdataEnd'     => \&handle_cdata_end,
  'Default'      => \&handle_default,
  'Unparsed'     => \&handle_unparsed,
  'Notation'     => \&handle_notation,
  'ExternEnt'    => \&handle_extern_ent,
  'ExternEntFin' => \&handle_extern_ent_fin,
  'Entity'       => \&handle_entity,
  'Element'      => \&handle_element,
  'Attlist'      => \&handle_attlist,
  'Doctype'      => \&handle_doctype,
  'DoctypeFin'   => \&handle_doctype_fin,
  'XMLDecl'      => \&handle_xml_decl,
);

my %sax_start_handlers = (
  'all'                                 => \&handle_start_all,
  'annotation'                          => \&handle_start_annotation,
  'any'                                 => \&handle_start_any,
  'anyAttribute'                        => \&handle_start_anyAttribute,
  'appinfo'                             => \&handle_start_appinfo,
  'attribute'                           => \&handle_start_attribute,
  'attributeGroup'                      => \&handle_start_attributeGroup,
  'choice'                              => \&handle_start_choice,
  'complexContent'                      => \&handle_start_complexContent,
  'complexType'                         => \&handle_start_complexType,
  'documentation'                       => \&handle_start_documentation,
  'element'                             => \&handle_start_element,
  'enumeration'                         => \&handle_start_enumeration,
  'extension'                           => \&handle_start_extension,
  'field'                               => \&handle_start_field,
  'fractionDigits'                      => \&handle_start_fractionDigits,
  'group'                               => \&handle_start_group,
  'import'                              => \&handle_start_import,
  'include'                             => \&handle_start_include,
  'key'                                 => \&handle_start_key,
  'keyref'                              => \&handle_start_keyref,
  'length'                              => \&handle_start_length,
  'list'                                => \&handle_start_list,
  'maxExclusive'                        => \&handle_start_maxExclusive,
  'maxInclusive'                        => \&handle_start_maxInclusive,
  'maxLength'                           => \&handle_start_maxLength,
  'minExclusive'                        => \&handle_start_minExclusive,
  'minInclusive'                        => \&handle_start_minInclusive,
  'minLength'                           => \&handle_start_minLength,
  'notation'                            => \&handle_start_notation,
  'pattern'                             => \&handle_start_pattern,
  'redefine'                            => \&handle_start_redefine,
  'restriction'                         => \&handle_start_restriction,
  'schema'                              => \&handle_start_schema,
  'selector'                            => \&handle_start_selector,
  'sequence'                            => \&handle_start_sequence,
  'simpleContent'                       => \&handle_start_simpleContent,
  'simpleType'                          => \&handle_start_simpleType,
  'totalDigits'                         => \&handle_start_totalDigits,
  'union'                               => \&handle_start_union,
  'unique'                              => \&handle_start_unique,
  'whiteSpace'                          => \&handle_start_whiteSpace,
);

my %sax_end_handlers = (
  'all'                                 => \&handle_end_all,
  'annotation'                          => \&handle_end_annotation,
  'any'                                 => \&handle_end_any,
  'anyAttribute'                        => \&handle_end_anyAttribute,
  'appinfo'                             => \&handle_end_appinfo,
  'attribute'                           => \&handle_end_attribute,
  'attributeGroup'                      => \&handle_end_attributeGroup,
  'choice'                              => \&handle_end_choice,
  'complexContent'                      => \&handle_end_complexContent,
  'complexType'                         => \&handle_end_complexType,
  'documentation'                       => \&handle_end_documentation,
  'element'                             => \&handle_end_element,
  'enumeration'                         => \&handle_end_enumeration,
  'extension'                           => \&handle_end_extension,
  'field'                               => \&handle_end_field,
  'fractionDigits'                      => \&handle_end_fractionDigits,
  'group'                               => \&handle_end_group,
  'import'                              => \&handle_end_import,
  'include'                             => \&handle_end_include,
  'key'                                 => \&handle_end_key,
  'keyref'                              => \&handle_end_keyref,
  'length'                              => \&handle_end_length,
  'list'                                => \&handle_end_list,
  'maxExclusive'                        => \&handle_end_maxExclusive,
  'maxInclusive'                        => \&handle_end_maxInclusive,
  'maxLength'                           => \&handle_end_maxLength,
  'minExclusive'                        => \&handle_end_minExclusive,
  'minInclusive'                        => \&handle_end_minInclusive,
  'minLength'                           => \&handle_end_minLength,
  'notation'                            => \&handle_end_notation,
  'pattern'                             => \&handle_end_pattern,
  'redefine'                            => \&handle_end_redefine,
  'restriction'                         => \&handle_end_restriction,
  'schema'                              => \&handle_end_schema,
  'selector'                            => \&handle_end_selector,
  'sequence'                            => \&handle_end_sequence,
  'simpleContent'                       => \&handle_end_simpleContent,
  'simpleType'                          => \&handle_end_simpleType,
  'totalDigits'                         => \&handle_end_totalDigits,
  'union'                               => \&handle_end_union,
  'unique'                              => \&handle_end_unique,
  'whiteSpace'                          => \&handle_end_whiteSpace,
);

my %namespaces;
my %namespace_prefixes;
my @elem_stack;
my @namespace_stack;

my $Document;

my $schema_namespace='http://www.w3.org/2001/XMLSchema';

#===============================================================================

=item  $Object = Rinchi::XMLSchema::?Class?->new();

Create an object of the appropriate class, based on the local name of the element 
being represented.

    Local Name                            Class;
all                                  Rinchi::XMLSchema::All;
annotation                           Rinchi::XMLSchema::Annotation;
any                                  Rinchi::XMLSchema::Any;
anyAttribute                         Rinchi::XMLSchema::AnyAttribute;
appinfo                              Rinchi::XMLSchema::Appinfo;
attribute                            Rinchi::XMLSchema::Attribute;
attributeGroup                       Rinchi::XMLSchema::AttributeGroup;
choice                               Rinchi::XMLSchema::Choice;
complexContent                       Rinchi::XMLSchema::ComplexContent;
complexType                          Rinchi::XMLSchema::ComplexType;
documentation                        Rinchi::XMLSchema::Documentation;
element                              Rinchi::XMLSchema::Element;
enumeration                          Rinchi::XMLSchema::Enumeration;
extension                            Rinchi::XMLSchema::Extension;
field                                Rinchi::XMLSchema::Field;
fractionDigits                       Rinchi::XMLSchema::FractionDigits;
group                                Rinchi::XMLSchema::Group;
import                               Rinchi::XMLSchema::Import;
include                              Rinchi::XMLSchema::Include;
key                                  Rinchi::XMLSchema::Key;
keyref                               Rinchi::XMLSchema::Keyref;
length                               Rinchi::XMLSchema::Length;
list                                 Rinchi::XMLSchema::List;
maxExclusive                         Rinchi::XMLSchema::MaxExclusive;
maxInclusive                         Rinchi::XMLSchema::MaxInclusive;
maxLength                            Rinchi::XMLSchema::MaxLength;
minExclusive                         Rinchi::XMLSchema::MinExclusive;
minInclusive                         Rinchi::XMLSchema::MinInclusive;
minLength                            Rinchi::XMLSchema::MinLength;
notation                             Rinchi::XMLSchema::Notation;
pattern                              Rinchi::XMLSchema::Pattern;
redefine                             Rinchi::XMLSchema::Redefine;
restriction                          Rinchi::XMLSchema::Restriction;
schema                               Rinchi::XMLSchema::Schema;
selector                             Rinchi::XMLSchema::Selector;
sequence                             Rinchi::XMLSchema::Sequence;
simpleContent                        Rinchi::XMLSchema::SimpleContent;
simpleType                           Rinchi::XMLSchema::SimpleType;
totalDigits                          Rinchi::XMLSchema::TotalDigits;
union                                Rinchi::XMLSchema::Union;
unique                               Rinchi::XMLSchema::Unique;
whiteSpace                           Rinchi::XMLSchema::WhiteSpace;

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#=================================================================

=item  $Document = Rinchi::XMLSchema->parsefile($path);

Calls XML::Parser->parsefile with the given path and the Rinchi::XMLSchema 
handlers.  Objects are created for the namespaces with available handlers, 
arrays with the tags and attributes. A tree of the objects and arrays is 
returned, with children accessible as @{$Object->{'_content_'}}.

Open FILE for reading, then call parse with the open handle. The
file is closed no matter how parse returns. Returns what parse
returns.

=cut

sub parsefile($) {
  my $self = shift @_;
  my $source = shift @_;

  my $Parser = new XML::Parser('Handlers' => \%sax_handlers);
  $Parser->parsefile($source);
  return $Document;
}

#=================================================================

=item  $nsdef = Rinchi::XMLSchema->namespace_def();

Returns a hash reference containing the following key-value pairs:

Start                       Hash reference to SAX Start event handlers
End                         Hash reference to SAX End event handlers
Namespace                   Namespace URI

=cut

sub namespace_def() {
  my $self = shift @_;
  
  return {'Start'=>\%sax_start_handlers,'End'=>\%sax_end_handlers, 'Namespace'=>$schema_namespace};
}

#=================================================================

=item  $Document = Rinchi::XMLSchema->add_namespace($nsdef);

Adds the namespace and handlers to the list of routines called by 
the parser to create objects of the specified classes.  For example:

use Rinchi::XMLSchema::HFP;
my $nsdef = Rinchi::HFP->namespace_def();
$nsdef->{'Prefix'} = 'hfp';
Rinchi::XMLSchema->add_namespace($nsdef);
my $Document = Rinchi::XMLSchema->parsefile('datatypes.xsd');

This will cause Rinchi::HFP subclassed objects from the namespace
'http://www.w3.org/2001/XMLSchema-hasFacetAndProperty' to be created 
as well as those from the XMLSchema namespace.
 

=cut

sub add_namespace($) {
  my $self = shift @_;
  my $nsdef = shift @_;
  
  my $namespace = $nsdef->{'Namespace'};
  my $prefix    = $nsdef->{'Prefix'};
#  print "add_namespace $prefix $namespace\n";
  $namespaces{$namespace} = $nsdef;
  push @{$namespace_prefixes{$prefix}},$namespace;
}

#=================================================================

sub check_xmlns($) {
  my $attrs = shift @_;
  my $prefix;

  foreach my $attr (keys %{$attrs}) {
    if ($attr =~/^xmlns:([A-Za-z][0-9A-Za-z_]*)$/) {
      my $p = $1;
#      print "$attr $p $attrs->{$attr} $schema_namespace\n";
      if($attrs->{$attr} eq $schema_namespace) {
        $prefix = $p;
      }
    }
  }

  $prefix = 'xs' unless(defined($prefix));
  
  if(defined($prefix)) {
    my $nsdef={'Start'=>\%sax_start_handlers,'End'=>\%sax_end_handlers,'Prefix'=>$prefix,'Namespace'=>$schema_namespace};
    Rinchi::XMLSchema->add_namespace($nsdef);
    push @namespace_stack,$nsdef;
  }

}
#=================================================================

# Init              (Expat)
sub handle_init() {
  my ($expat) = @_;
}

#=================================================================

# Final             (Expat)
sub handle_final() {
  my ($expat) = @_;
}

#=================================================================

# Start             (Expat, Tag [, Attr, Val [,...]])
sub handle_start() {
  my ($expat, $tag, %attrs) = @_;

  check_xmlns(\%attrs) unless (@elem_stack);
  my $prefix;
  my $local;
  
  if ($tag =~ /^([A-Za-z]+):([A-Za-z]+)$/) {
    $prefix = $1;
    $local = $2;
  } else {
    $local = $tag;
  }

#  print "$prefix $local\n";
  my $Element;  
  if (defined($prefix)) {
    if(exists($namespace_prefixes{$prefix})) {
      my $namespace = $namespace_prefixes{$prefix}[-1];
#      print "$prefix $local $namespace\n";
    }
    if(exists($namespace_prefixes{$prefix})
      and defined($namespace_prefixes{$prefix}->[0])
      and exists($namespaces{$namespace_prefixes{$prefix}->[-1]})
      and exists($namespaces{$namespace_prefixes{$prefix}->[-1]}->{'Start'})
      and exists($namespaces{$namespace_prefixes{$prefix}->[-1]}->{'Start'}{$local})
    ) {
      $Element = $namespaces{$namespace_prefixes{$prefix}->[-1]}->{'Start'}{$local}(@_);
    }
  } elsif(@namespace_stack
    and exists($namespace_stack[-1]->{'Start'})
    and exists($namespace_stack[-1]->{'Start'}{$local})
  ) {
    $Element = $namespace_stack[-1]->{'Start'}{$local}(@_);
  }
  unless(defined($Element)) {
    $Element = {'_tag' => $tag, };

    foreach my $attr (keys %attrs) {
      $Element->{$attr} = $attrs{$attr};
    }

  }
  push @{$elem_stack[-1]->{'_content_'}}, $Element if(@elem_stack);
  push @elem_stack,$Element;
}

#=================================================================

# End               (Expat, Tag)
sub handle_end() {
  my ($expat, $tag) = @_;
  my $prefix;
  my $local;
  
  if ($tag =~ /^([A-Za-z]+):([A-Za-z]+)$/) {
    $prefix = $1;
    $local = $2;
  } else {
    $local = $tag;
  }

  my $Element;  
  if (defined($prefix)) {
    if(exists($namespace_prefixes{$prefix})
      and defined($namespace_prefixes{$prefix}->[0])
      and exists($namespaces{$namespace_prefixes{$prefix}->[-1]})
      and exists($namespaces{$namespace_prefixes{$prefix}->[-1]}->{'End'})
      and exists($namespaces{$namespace_prefixes{$prefix}->[-1]}->{'End'}{$local})
    ) {
      $namespaces{$namespace_prefixes{$prefix}->[-1]}->{'End'}{$local}(@_,$elem_stack[-1]);
    }
  } elsif(@namespace_stack
    and exists($namespace_stack[-1]->{'End'})
    and exists($namespace_stack[-1]->{'End'}{$local})
  ) {
    $namespace_stack[-1]->{'End'}{$local}(@_,$elem_stack[-1]);
  }
  $Document = pop @elem_stack;
}

#=================================================================

# Char              (Expat, String)
sub handle_char() {
  my ($expat, $string) = @_;
  $elem_stack[-1]->{'_text'} .= $string unless (ref($elem_stack[-1]) =~ /^Rinchi::XMLSchema/);
}

#=================================================================

# Proc              (Expat, Target, Data)
sub handle_proc() {
  my ($expat, $target, $data) = @_;
}

#=================================================================

# Comment           (Expat, Data)
sub handle_comment() {
  my ($expat, $data) = @_;
}

#=================================================================

# CdataStart        (Expat)
sub handle_cdata_start() {
  my ($expat) = @_;
}

#=================================================================

# CdataEnd          (Expat)
sub handle_cdata_end() {
  my ($expat) = @_;
}

#=================================================================

# Default           (Expat, String)
sub handle_default() {
  my ($expat, $string) = @_;
}

#=================================================================

# Unparsed          (Expat, Entity, Base, Sysid, Pubid, Notation)
sub handle_unparsed() {
  my ($expat, $entity, $base, $sysid, $pubid, $notation) = @_;
}

#=================================================================

# Notation          (Expat, Notation, Base, Sysid, Pubid)
sub handle_notation() {
  my ($expat, $notation, $base, $sysid, $pubid) = @_;
}

#=================================================================

# ExternEnt         (Expat, Base, Sysid, Pubid)
sub handle_extern_ent() {
  my ($expat, $base, $sysid, $pubid) = @_;
}

#=================================================================

# ExternEntFin      (Expat)
sub handle_extern_ent_fin() {
  my ($expat) = @_;
}

#=================================================================

# Entity            (Expat, Name, Val, Sysid, Pubid, Ndata, IsParam)
sub handle_entity() {
  my ($expat, $name, $val, $sysid, $pubid, $ndata, $isParam) = @_;
}

#=================================================================

# Element           (Expat, Name, Model)
sub handle_element() {
  my ($expat, $name, $model) = @_;
}

#=================================================================

# Attlist           (Expat, Elname, Attname, Type, Default, Fixed)
sub handle_attlist() {
  my ($expat, $elname, $attname, $type, $default, $fixed) = @_;
}

#=================================================================

# Doctype           (Expat, Name, Sysid, Pubid, Internal)
sub handle_doctype() {
  my ($expat, $name, $sysid, $pubid, $internal) = @_;
}

#=================================================================

# DoctypeFin        (Expat)
sub handle_doctype_fin() {
  my ($expat) = @_;
}

#=================================================================

# XMLDecl           (Expat, Version, Encoding, Standalone)
sub handle_xml_decl() {
  my ($expat, $version, $encoding, $standalone) = @_;
}

#===============================================================================

sub handle_start_all() {
  my ($expat,$tag,%attrs) = @_;
  my $All = Rinchi::XMLSchema::All->new();

  if (exists($attrs{'id'})) {
    $All->id($attrs{'id'});
  }

  if (exists($attrs{'maxOccurs'})) {
    $All->maxOccurs($attrs{'maxOccurs'});
  }

  if (exists($attrs{'minOccurs'})) {
    $All->minOccurs($attrs{'minOccurs'});
  }

  return $All;
}

#===============================================================================

sub handle_end_all() {
  my ($expat,$tag,$All) = @_;
}

#===============================================================================

sub handle_start_annotation() {
  my ($expat,$tag,%attrs) = @_;
  my $Annotation = Rinchi::XMLSchema::Annotation->new();

  return $Annotation;
}

#===============================================================================

sub handle_end_annotation() {
  my ($expat,$tag,$Annotation) = @_;
}

#===============================================================================

sub handle_start_any() {
  my ($expat,$tag,%attrs) = @_;
  my $Any = Rinchi::XMLSchema::Any->new();

  if (exists($attrs{'id'})) {
    $Any->id($attrs{'id'});
  }

  if (exists($attrs{'maxOccurs'})) {
    $Any->maxOccurs($attrs{'maxOccurs'});
  }

  if (exists($attrs{'minOccurs'})) {
    $Any->minOccurs($attrs{'minOccurs'});
  }

  if (exists($attrs{'namespace'})) {
    $Any->namespace($attrs{'namespace'});
  }

  if (exists($attrs{'processContents'})) {
    $Any->processContents($attrs{'processContents'});
  }

  return $Any;
}

#===============================================================================

sub handle_end_any() {
  my ($expat,$tag,$Any) = @_;
}

#===============================================================================

sub handle_start_anyAttribute() {
  my ($expat,$tag,%attrs) = @_;
  my $AnyAttribute = Rinchi::XMLSchema::AnyAttribute->new();

  if (exists($attrs{'id'})) {
    $AnyAttribute->id($attrs{'id'});
  }

  if (exists($attrs{'namespace'})) {
    $AnyAttribute->namespace($attrs{'namespace'});
  }

  if (exists($attrs{'processContents'})) {
    $AnyAttribute->processContents($attrs{'processContents'});
  }

  return $AnyAttribute;
}

#===============================================================================

sub handle_end_anyAttribute() {
  my ($expat,$tag,$AnyAttribute) = @_;
}

#===============================================================================

sub handle_start_appinfo() {
  my ($expat,$tag,%attrs) = @_;
  my $Appinfo = Rinchi::XMLSchema::Appinfo->new();

  if (exists($attrs{'id'})) {
    $Appinfo->id($attrs{'id'});
  }

  if (exists($attrs{'source'})) {
    $Appinfo->source($attrs{'source'});
  }

  return $Appinfo;
}

#===============================================================================

sub handle_end_appinfo() {
  my ($expat,$tag,$Appinfo) = @_;
}

#===============================================================================

sub handle_start_attribute() {
  my ($expat,$tag,%attrs) = @_;
  my $Attribute = Rinchi::XMLSchema::Attribute->new();

  if (exists($attrs{'default'})) {
    $Attribute->default($attrs{'default'});
  }

  if (exists($attrs{'fixed'})) {
    $Attribute->fixed($attrs{'fixed'});
  }

  if (exists($attrs{'form'})) {
    $Attribute->form($attrs{'form'});
  }

  if (exists($attrs{'id'})) {
    $Attribute->id($attrs{'id'});
  }

  if (exists($attrs{'name'})) {
    $Attribute->name($attrs{'name'});
  }

  if (exists($attrs{'ref'})) {
    $Attribute->ref($attrs{'ref'});
  }

  if (exists($attrs{'type'})) {
    $Attribute->type($attrs{'type'});
  }

  if (exists($attrs{'use'})) {
    $Attribute->use($attrs{'use'});
  }

  return $Attribute;
}

#===============================================================================

sub handle_end_attribute() {
  my ($expat,$tag,$Attribute) = @_;
}

#===============================================================================

sub handle_start_attributeGroup() {
  my ($expat,$tag,%attrs) = @_;
  my $AttributeGroup = Rinchi::XMLSchema::AttributeGroup->new();

  if (exists($attrs{'id'})) {
    $AttributeGroup->id($attrs{'id'});
  }

  if (exists($attrs{'name'})) {
    $AttributeGroup->name($attrs{'name'});
  }

  if (exists($attrs{'ref'})) {
    $AttributeGroup->ref($attrs{'ref'});
  }

  return $AttributeGroup;
}

#===============================================================================

sub handle_end_attributeGroup() {
  my ($expat,$tag,$AttributeGroup) = @_;
}

#===============================================================================

sub handle_start_choice() {
  my ($expat,$tag,%attrs) = @_;
  my $Choice = Rinchi::XMLSchema::Choice->new();

  if (exists($attrs{'id'})) {
    $Choice->id($attrs{'id'});
  }

  if (exists($attrs{'maxOccurs'})) {
    $Choice->maxOccurs($attrs{'maxOccurs'});
  }

  if (exists($attrs{'minOccurs'})) {
    $Choice->minOccurs($attrs{'minOccurs'});
  }

  return $Choice;
}

#===============================================================================

sub handle_end_choice() {
  my ($expat,$tag,$Choice) = @_;
}

#===============================================================================

sub handle_start_complexContent() {
  my ($expat,$tag,%attrs) = @_;
  my $ComplexContent = Rinchi::XMLSchema::ComplexContent->new();

  if (exists($attrs{'id'})) {
    $ComplexContent->id($attrs{'id'});
  }

  if (exists($attrs{'mixed'})) {
    $ComplexContent->mixed($attrs{'mixed'});
  }

  return $ComplexContent;
}

#===============================================================================

sub handle_end_complexContent() {
  my ($expat,$tag,$ComplexContent) = @_;
}

#===============================================================================

sub handle_start_complexType() {
  my ($expat,$tag,%attrs) = @_;
  my $ComplexType = Rinchi::XMLSchema::ComplexType->new();

  if (exists($attrs{'abstract'})) {
    $ComplexType->abstract($attrs{'abstract'});
  }

  if (exists($attrs{'block'})) {
    $ComplexType->block($attrs{'block'});
  }

  if (exists($attrs{'final'})) {
    $ComplexType->final($attrs{'final'});
  }

  if (exists($attrs{'id'})) {
    $ComplexType->id($attrs{'id'});
  }

  if (exists($attrs{'mixed'})) {
    $ComplexType->mixed($attrs{'mixed'});
  }

  if (exists($attrs{'name'})) {
    $ComplexType->name($attrs{'name'});
  }

  return $ComplexType;
}

#===============================================================================

sub handle_end_complexType() {
  my ($expat,$tag,$ComplexType) = @_;
}

#===============================================================================

sub handle_start_documentation() {
  my ($expat,$tag,%attrs) = @_;
  my $Documentation = Rinchi::XMLSchema::Documentation->new();

  if (exists($attrs{'id'})) {
    $Documentation->id($attrs{'id'});
  }

  if (exists($attrs{'source'})) {
    $Documentation->source($attrs{'source'});
  }

  if (exists($attrs{'xml:lang'})) {
    $Documentation->xml_lang($attrs{'xml:lang'});
  }

  return $Documentation;
}

#===============================================================================

sub handle_end_documentation() {
  my ($expat,$tag,$Documentation) = @_;
#  my $Documentation = $elem_stack[-1];
}

#===============================================================================

sub handle_start_element() {
  my ($expat,$tag,%attrs) = @_;
  my $Element = Rinchi::XMLSchema::Element->new();

  if (exists($attrs{'abstract'})) {
    $Element->abstract($attrs{'abstract'});
  }

  if (exists($attrs{'block'})) {
    $Element->block($attrs{'block'});
  }

  if (exists($attrs{'default'})) {
    $Element->default($attrs{'default'});
  }

  if (exists($attrs{'final'})) {
    $Element->final($attrs{'final'});
  }

  if (exists($attrs{'fixed'})) {
    $Element->fixed($attrs{'fixed'});
  }

  if (exists($attrs{'form'})) {
    $Element->form($attrs{'form'});
  }

  if (exists($attrs{'id'})) {
    $Element->id($attrs{'id'});
  }

  if (exists($attrs{'maxOccurs'})) {
    $Element->maxOccurs($attrs{'maxOccurs'});
  }

  if (exists($attrs{'minOccurs'})) {
    $Element->minOccurs($attrs{'minOccurs'});
  }

  if (exists($attrs{'name'})) {
    $Element->name($attrs{'name'});
  }

  if (exists($attrs{'nillable'})) {
    $Element->nillable($attrs{'nillable'});
  }

  if (exists($attrs{'ref'})) {
    $Element->ref($attrs{'ref'});
  }

  if (exists($attrs{'substitutionGroup'})) {
    $Element->substitutionGroup($attrs{'substitutionGroup'});
  }

  if (exists($attrs{'type'})) {
    $Element->type($attrs{'type'});
  }

  return $Element;
}

#===============================================================================

sub handle_end_element() {
  my ($expat,$tag,$Element) = @_;
}

#===============================================================================

sub handle_start_enumeration() {
  my ($expat,$tag,%attrs) = @_;
  my $Enumeration = Rinchi::XMLSchema::Enumeration->new();

  if (exists($attrs{'id'})) {
    $Enumeration->id($attrs{'id'});
  }

  if (exists($attrs{'value'})) {
    $Enumeration->value($attrs{'value'});
  }

  return $Enumeration;
}

#===============================================================================

sub handle_end_enumeration() {
  my ($expat,$tag,$Enumeration) = @_;
}

#===============================================================================

sub handle_start_extension() {
  my ($expat,$tag,%attrs) = @_;
  my $Extension = Rinchi::XMLSchema::Extension->new();

  if (exists($attrs{'base'})) {
    $Extension->base($attrs{'base'});
  }

  if (exists($attrs{'id'})) {
    $Extension->id($attrs{'id'});
  }

  return $Extension;
}

#===============================================================================

sub handle_end_extension() {
  my ($expat,$tag,$Extension) = @_;
}

#===============================================================================

sub handle_start_field() {
  my ($expat,$tag,%attrs) = @_;
  my $Field = Rinchi::XMLSchema::Field->new();

  if (exists($attrs{'id'})) {
    $Field->id($attrs{'id'});
  }

  if (exists($attrs{'xpath'})) {
    $Field->xpath($attrs{'xpath'});
  }

  return $Field;
}

#===============================================================================

sub handle_end_field() {
  my ($expat,$tag,$Field) = @_;
}

#===============================================================================

sub handle_start_fractionDigits() {
  my ($expat,$tag,%attrs) = @_;
  my $FractionDigits = Rinchi::XMLSchema::FractionDigits->new();

  if (exists($attrs{'fixed'})) {
    $FractionDigits->fixed($attrs{'fixed'});
  }

  if (exists($attrs{'id'})) {
    $FractionDigits->id($attrs{'id'});
  }

  if (exists($attrs{'value'})) {
    $FractionDigits->value($attrs{'value'});
  }

  return $FractionDigits;
}

#===============================================================================

sub handle_end_fractionDigits() {
  my ($expat,$tag,$FractionDigits) = @_;
}

#===============================================================================

sub handle_start_group() {
  my ($expat,$tag,%attrs) = @_;
  my $Group = Rinchi::XMLSchema::Group->new();

  if (exists($attrs{'id'})) {
    $Group->id($attrs{'id'});
  }

  if (exists($attrs{'maxOccurs'})) {
    $Group->maxOccurs($attrs{'maxOccurs'});
  }

  if (exists($attrs{'minOccurs'})) {
    $Group->minOccurs($attrs{'minOccurs'});
  }

  if (exists($attrs{'name'})) {
    $Group->name($attrs{'name'});
  }

  if (exists($attrs{'ref'})) {
    $Group->ref($attrs{'ref'});
  }

  return $Group;
}

#===============================================================================

sub handle_end_group() {
  my ($expat,$tag,$Group) = @_;
}

#===============================================================================

sub handle_start_import() {
  my ($expat,$tag,%attrs) = @_;
  my $Import = Rinchi::XMLSchema::Import->new();

  if (exists($attrs{'id'})) {
    $Import->id($attrs{'id'});
  }

  if (exists($attrs{'namespace'})) {
    $Import->namespace($attrs{'namespace'});
  }

  if (exists($attrs{'schemaLocation'})) {
    $Import->schemaLocation($attrs{'schemaLocation'});
  }

  return $Import;
}

#===============================================================================

sub handle_end_import() {
  my ($expat,$tag,$Import) = @_;
}

#===============================================================================

sub handle_start_include() {
  my ($expat,$tag,%attrs) = @_;
  my $Include = Rinchi::XMLSchema::Include->new();

  if (exists($attrs{'id'})) {
    $Include->id($attrs{'id'});
  }

  if (exists($attrs{'schemaLocation'})) {
    $Include->schemaLocation($attrs{'schemaLocation'});
  }

  return $Include;
}

#===============================================================================

sub handle_end_include() {
  my ($expat,$tag,$Include) = @_;
}

#===============================================================================

sub handle_start_key() {
  my ($expat,$tag,%attrs) = @_;
  my $Key = Rinchi::XMLSchema::Key->new();

  if (exists($attrs{'id'})) {
    $Key->id($attrs{'id'});
  }

  if (exists($attrs{'name'})) {
    $Key->name($attrs{'name'});
  }

  return $Key;
}

#===============================================================================

sub handle_end_key() {
  my ($expat,$tag,$Key) = @_;
}

#===============================================================================

sub handle_start_keyref() {
  my ($expat,$tag,%attrs) = @_;
  my $Keyref = Rinchi::XMLSchema::Keyref->new();

  if (exists($attrs{'id'})) {
    $Keyref->id($attrs{'id'});
  }

  if (exists($attrs{'name'})) {
    $Keyref->name($attrs{'name'});
  }

  if (exists($attrs{'refer'})) {
    $Keyref->refer($attrs{'refer'});
  }

  return $Keyref;
}

#===============================================================================

sub handle_end_keyref() {
  my ($expat,$tag,$Keyref) = @_;
}

#===============================================================================

sub handle_start_length() {
  my ($expat,$tag,%attrs) = @_;
  my $Length = Rinchi::XMLSchema::Length->new();

  if (exists($attrs{'fixed'})) {
    $Length->fixed($attrs{'fixed'});
  }

  if (exists($attrs{'id'})) {
    $Length->id($attrs{'id'});
  }

  if (exists($attrs{'value'})) {
    $Length->value($attrs{'value'});
  }

  return $Length;
}

#===============================================================================

sub handle_end_length() {
  my ($expat,$tag,$Length) = @_;
}

#===============================================================================

sub handle_start_list() {
  my ($expat,$tag,%attrs) = @_;
  my $List = Rinchi::XMLSchema::List->new();

  if (exists($attrs{'id'})) {
    $List->id($attrs{'id'});
  }

  if (exists($attrs{'itemType'})) {
    $List->itemType($attrs{'itemType'});
  }

  return $List;
}

#===============================================================================

sub handle_end_list() {
  my ($expat,$tag,$List) = @_;
}

#===============================================================================

sub handle_start_maxExclusive() {
  my ($expat,$tag,%attrs) = @_;
  my $MaxExclusive = Rinchi::XMLSchema::MaxExclusive->new();

  if (exists($attrs{'fixed'})) {
    $MaxExclusive->fixed($attrs{'fixed'});
  }

  if (exists($attrs{'id'})) {
    $MaxExclusive->id($attrs{'id'});
  }

  if (exists($attrs{'value'})) {
    $MaxExclusive->value($attrs{'value'});
  }

  return $MaxExclusive;
}

#===============================================================================

sub handle_end_maxExclusive() {
  my ($expat,$tag,$MaxExclusive) = @_;
}

#===============================================================================

sub handle_start_maxInclusive() {
  my ($expat,$tag,%attrs) = @_;
  my $MaxInclusive = Rinchi::XMLSchema::MaxInclusive->new();

  if (exists($attrs{'fixed'})) {
    $MaxInclusive->fixed($attrs{'fixed'});
  }

  if (exists($attrs{'id'})) {
    $MaxInclusive->id($attrs{'id'});
  }

  if (exists($attrs{'value'})) {
    $MaxInclusive->value($attrs{'value'});
  }

  return $MaxInclusive;
}

#===============================================================================

sub handle_end_maxInclusive() {
  my ($expat,$tag,$MaxInclusive) = @_;
}

#===============================================================================

sub handle_start_maxLength() {
  my ($expat,$tag,%attrs) = @_;
  my $MaxLength = Rinchi::XMLSchema::MaxLength->new();

  if (exists($attrs{'fixed'})) {
    $MaxLength->fixed($attrs{'fixed'});
  }

  if (exists($attrs{'id'})) {
    $MaxLength->id($attrs{'id'});
  }

  if (exists($attrs{'value'})) {
    $MaxLength->value($attrs{'value'});
  }

  return $MaxLength;
}

#===============================================================================

sub handle_end_maxLength() {
  my ($expat,$tag,$MaxLength) = @_;
}

#===============================================================================

sub handle_start_minExclusive() {
  my ($expat,$tag,%attrs) = @_;
  my $MinExclusive = Rinchi::XMLSchema::MinExclusive->new();

  if (exists($attrs{'fixed'})) {
    $MinExclusive->fixed($attrs{'fixed'});
  }

  if (exists($attrs{'id'})) {
    $MinExclusive->id($attrs{'id'});
  }

  if (exists($attrs{'value'})) {
    $MinExclusive->value($attrs{'value'});
  }

  return $MinExclusive;
}

#===============================================================================

sub handle_end_minExclusive() {
  my ($expat,$tag,$MinExclusive) = @_;
}

#===============================================================================

sub handle_start_minInclusive() {
  my ($expat,$tag,%attrs) = @_;
  my $MinInclusive = Rinchi::XMLSchema::MinInclusive->new();

  if (exists($attrs{'fixed'})) {
    $MinInclusive->fixed($attrs{'fixed'});
  }

  if (exists($attrs{'id'})) {
    $MinInclusive->id($attrs{'id'});
  }

  if (exists($attrs{'value'})) {
    $MinInclusive->value($attrs{'value'});
  }

  return $MinInclusive;
}

#===============================================================================

sub handle_end_minInclusive() {
  my ($expat,$tag,$MinInclusive) = @_;
}

#===============================================================================

sub handle_start_minLength() {
  my ($expat,$tag,%attrs) = @_;
  my $MinLength = Rinchi::XMLSchema::MinLength->new();

  if (exists($attrs{'fixed'})) {
    $MinLength->fixed($attrs{'fixed'});
  }

  if (exists($attrs{'id'})) {
    $MinLength->id($attrs{'id'});
  }

  if (exists($attrs{'value'})) {
    $MinLength->value($attrs{'value'});
  }

  return $MinLength;
}

#===============================================================================

sub handle_end_minLength() {
  my ($expat,$tag,$MinLength) = @_;
}

#===============================================================================

sub handle_start_notation() {
  my ($expat,$tag,%attrs) = @_;
  my $Notation = Rinchi::XMLSchema::Notation->new();

  if (exists($attrs{'id'})) {
    $Notation->id($attrs{'id'});
  }

  if (exists($attrs{'name'})) {
    $Notation->name($attrs{'name'});
  }

  if (exists($attrs{'public'})) {
    $Notation->public($attrs{'public'});
  }

  if (exists($attrs{'system'})) {
    $Notation->system($attrs{'system'});
  }

  return $Notation;
}

#===============================================================================

sub handle_end_notation() {
  my ($expat,$tag,$Notation) = @_;
}

#===============================================================================

sub handle_start_pattern() {
  my ($expat,$tag,%attrs) = @_;
  my $Pattern = Rinchi::XMLSchema::Pattern->new();

  if (exists($attrs{'id'})) {
    $Pattern->id($attrs{'id'});
  }

  if (exists($attrs{'value'})) {
    $Pattern->value($attrs{'value'});
  }

  return $Pattern;
}

#===============================================================================

sub handle_end_pattern() {
  my ($expat,$tag,$Pattern) = @_;
}

#===============================================================================

sub handle_start_redefine() {
  my ($expat,$tag,%attrs) = @_;
  my $Redefine = Rinchi::XMLSchema::Redefine->new();

  if (exists($attrs{'id'})) {
    $Redefine->id($attrs{'id'});
  }

  if (exists($attrs{'schemaLocation'})) {
    $Redefine->schemaLocation($attrs{'schemaLocation'});
  }

  return $Redefine;
}

#===============================================================================

sub handle_end_redefine() {
  my ($expat,$tag,$Redefine) = @_;
}

#===============================================================================

sub handle_start_restriction() {
  my ($expat,$tag,%attrs) = @_;
  my $Restriction = Rinchi::XMLSchema::Restriction->new();

  if (exists($attrs{'base'})) {
    $Restriction->base($attrs{'base'});
  }

  if (exists($attrs{'id'})) {
    $Restriction->id($attrs{'id'});
  }

  return $Restriction;
}

#===============================================================================

sub handle_end_restriction() {
  my ($expat,$tag,$Restriction) = @_;
}

#===============================================================================

sub handle_start_schema() {
  my ($expat,$tag,%attrs) = @_;
  my $Schema = Rinchi::XMLSchema::Schema->new();

  if (exists($attrs{'attributeFormDefault'})) {
    $Schema->attributeFormDefault($attrs{'attributeFormDefault'});
  }

  if (exists($attrs{'blockDefault'})) {
    $Schema->blockDefault($attrs{'blockDefault'});
  }

  if (exists($attrs{'elementFormDefault'})) {
    $Schema->elementFormDefault($attrs{'elementFormDefault'});
  }

  if (exists($attrs{'finalDefault'})) {
    $Schema->finalDefault($attrs{'finalDefault'});
  }

  if (exists($attrs{'id'})) {
    $Schema->id($attrs{'id'});
  }

  if (exists($attrs{'targetNamespace'})) {
    $Schema->targetNamespace($attrs{'targetNamespace'});
  }

  if (exists($attrs{'version'})) {
    $Schema->version($attrs{'version'});
  }

  if (exists($attrs{'xml:lang'})) {
    $Schema->xml_lang($attrs{'xml:lang'});
  }

  if (exists($attrs{'xmlns'})) {
    $Schema->xmlns($attrs{'xmlns'});
  }

  if (exists($attrs{'xmlns:xs'})) {
    $Schema->xmlns_xs($attrs{'xmlns:xs'});
  }

  return $Schema;
}

#===============================================================================

sub handle_end_schema() {
  my ($expat,$tag,$Schema) = @_;
}

#===============================================================================

sub handle_start_selector() {
  my ($expat,$tag,%attrs) = @_;
  my $Selector = Rinchi::XMLSchema::Selector->new();

  if (exists($attrs{'id'})) {
    $Selector->id($attrs{'id'});
  }

  if (exists($attrs{'xpath'})) {
    $Selector->xpath($attrs{'xpath'});
  }

  return $Selector;
}

#===============================================================================

sub handle_end_selector() {
  my ($expat,$tag,$Selector) = @_;
}

#===============================================================================

sub handle_start_sequence() {
  my ($expat,$tag,%attrs) = @_;
  my $Sequence = Rinchi::XMLSchema::Sequence->new();

  if (exists($attrs{'id'})) {
    $Sequence->id($attrs{'id'});
  }

  if (exists($attrs{'maxOccurs'})) {
    $Sequence->maxOccurs($attrs{'maxOccurs'});
  }

  if (exists($attrs{'minOccurs'})) {
    $Sequence->minOccurs($attrs{'minOccurs'});
  }

  return $Sequence;
}

#===============================================================================

sub handle_end_sequence() {
  my ($expat,$tag,$Sequence) = @_;
}

#===============================================================================

sub handle_start_simpleContent() {
  my ($expat,$tag,%attrs) = @_;
  my $SimpleContent = Rinchi::XMLSchema::SimpleContent->new();

  if (exists($attrs{'id'})) {
    $SimpleContent->id($attrs{'id'});
  }

  return $SimpleContent;
}

#===============================================================================

sub handle_end_simpleContent() {
  my ($expat,$tag,$SimpleContent) = @_;
}

#===============================================================================

sub handle_start_simpleType() {
  my ($expat,$tag,%attrs) = @_;
  my $SimpleType = Rinchi::XMLSchema::SimpleType->new();

  if (exists($attrs{'final'})) {
    $SimpleType->final($attrs{'final'});
  }

  if (exists($attrs{'id'})) {
    $SimpleType->id($attrs{'id'});
  }

  if (exists($attrs{'name'})) {
    $SimpleType->name($attrs{'name'});
  }

  return $SimpleType;
}

#===============================================================================

sub handle_end_simpleType() {
  my ($expat,$tag,$SimpleType) = @_;
}

#===============================================================================

sub handle_start_totalDigits() {
  my ($expat,$tag,%attrs) = @_;
  my $TotalDigits = Rinchi::XMLSchema::TotalDigits->new();

  if (exists($attrs{'fixed'})) {
    $TotalDigits->fixed($attrs{'fixed'});
  }

  if (exists($attrs{'id'})) {
    $TotalDigits->id($attrs{'id'});
  }

  if (exists($attrs{'value'})) {
    $TotalDigits->value($attrs{'value'});
  }

  return $TotalDigits;
}

#===============================================================================

sub handle_end_totalDigits() {
  my ($expat,$tag,$TotalDigits) = @_;
}

#===============================================================================

sub handle_start_union() {
  my ($expat,$tag,%attrs) = @_;
  my $Union = Rinchi::XMLSchema::Union->new();

  if (exists($attrs{'id'})) {
    $Union->id($attrs{'id'});
  }

  if (exists($attrs{'memberTypes'})) {
    $Union->memberTypes($attrs{'memberTypes'});
  }

  return $Union;
}

#===============================================================================

sub handle_end_union() {
  my ($expat,$tag,$Union) = @_;
}

#===============================================================================

sub handle_start_unique() {
  my ($expat,$tag,%attrs) = @_;
  my $Unique = Rinchi::XMLSchema::Unique->new();

  if (exists($attrs{'id'})) {
    $Unique->id($attrs{'id'});
  }

  if (exists($attrs{'name'})) {
    $Unique->name($attrs{'name'});
  }

  return $Unique;
}

#===============================================================================

sub handle_end_unique() {
  my ($expat,$tag,$Unique) = @_;
}

#===============================================================================

sub handle_start_whiteSpace() {
  my ($expat,$tag,%attrs) = @_;
  my $WhiteSpace = Rinchi::XMLSchema::WhiteSpace->new();

  if (exists($attrs{'fixed'})) {
    $WhiteSpace->fixed($attrs{'fixed'});
  }

  if (exists($attrs{'id'})) {
    $WhiteSpace->id($attrs{'id'});
  }

  if (exists($attrs{'value'})) {
    $WhiteSpace->value($attrs{'value'});
  }

  return $WhiteSpace;
}

#===============================================================================

sub handle_end_whiteSpace() {
  my ($expat,$tag,$WhiteSpace) = @_;
}

#===============================================================================
# Rinchi::XMLSchema::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;
  
  return 0 unless (ref($other) eq ref($self));
  
  return 1;
}

#===============================================================================
sub _find_identityConstraints() {
  my $self = shift;
  my $root = shift;
  
  foreach my $c (@{$self->{'_content_'}}) {
    my $cref = ref($c);
#    print "ref $cref\n";
    if ($cref eq 'Rinchi::XMLSchema::All') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::Annotation') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::Any') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::AnyAttribute') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::Appinfo') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::Attribute') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::AttributeGroup') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::Choice') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::ComplexContent') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::ComplexType') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::Documentation') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::Element') {
      $c->_find_identityConstraints($root);
    }
    elsif ($cref eq 'Rinchi::XMLSchema::Enumeration') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::Extension') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::Field') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::FractionDigits') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::Group') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::Import') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::Include') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::Key') {
      $root->{'_identityConstraints'}{$c->name()} = $c;
    }
    elsif ($cref eq 'Rinchi::XMLSchema::Keyref') {
      $root->{'_identityConstraints'}{$c->name()} = $c;
    }
    elsif ($cref eq 'Rinchi::XMLSchema::Length') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::List') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::MaxExclusive') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::MaxInclusive') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::MaxLength') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::MinExclusive') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::MinInclusive') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::MinLength') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::Notation') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::Pattern') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::Redefine') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::Restriction') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::Schema') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::Selector') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::Sequence') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::SimpleContent') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::SimpleType') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::TotalDigits') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::Union') {
    }
    elsif ($cref eq 'Rinchi::XMLSchema::Unique') {
      $root->{'_identityConstraints'}{$c->name()} = $c;
    }
    elsif ($cref eq 'Rinchi::XMLSchema::WhiteSpace') {
    }
  }
}

#===============================================================================

package Rinchi::XMLSchema::All;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of All class

Rinchi::XMLSchema::All is used for creating XML Schema All objects.

 id = ID
 maxOccurs = 1 : 1
 minOccurs = (0 | 1) : 1
 {any attributes with non-schema namespace ...}>
 Content: (annotation?, element*)

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::All->new();

Create a new Rinchi::XMLSchema::All object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::All::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::All::maxOccurs

=item $value = $Object->maxOccurs([$new_value]);

Set or get value of the 'maxOccurs' attribute.

=cut

sub maxOccurs() {
  my $self = shift;
  if (@_) {
    $self->{'_maxOccurs'} = shift;
  }
  return $self->{'_maxOccurs'};
}

#===============================================================================
# Rinchi::XMLSchema::All::minOccurs

=item $value = $Object->minOccurs([$new_value]);

Set or get value of the 'minOccurs' attribute.

=cut

sub minOccurs() {
  my $self = shift;
  if (@_) {
    $self->{'_minOccurs'} = shift;
  }
  return $self->{'_minOccurs'};
}

#===============================================================================
# Rinchi::XMLSchema::All::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_maxOccurs'})) {
    if (exists($other->{'_maxOccurs'})) {
      return 0 unless ($self->{'_maxOccurs'} eq $other->{'_maxOccurs'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_maxOccurs'}));
  }

  if (exists($self->{'_minOccurs'})) {
    if (exists($other->{'_minOccurs'})) {
      return 0 unless ($self->{'_minOccurs'} eq $other->{'_minOccurs'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_minOccurs'}));
  }

  my @self_cont = @{$self->{'_content_'}};
  my @other_cont = @{$other->{'_content_'}};
  shift @self_cont while(@self_cont and ref($self_cont[0]) eq 'Rinchi::XMLSchema::Annotation');
  shift @other_cont while(@other_cont and ref($other_cont[0]) eq 'Rinchi::XMLSchema::Annotation');

  if (@self_cont) {
    if (@other_cont) {
      while (@self_cont and @other_cont) {
        my $sc = shift @self_cont;
        my $oc = shift @other_cont;
        return 0 unless($sc->sameAs($oc));
      }
      return (0) if (@self_cont or @other_cont);
    } else {
      return 0;
    }  
  } else {
    return 0 if (@other_cont);
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::Annotation;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Annotation class

Rinchi::XMLSchema::Annotation is used for creating XML Schema Annotation objects.

 id = ID
 {any attributes with non-schema namespace ...}>
 Content: (appinfo | documentation)*

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::Annotation->new();

Create a new Rinchi::XMLSchema::Annotation object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================

package Rinchi::XMLSchema::Any;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Any class

Rinchi::XMLSchema::Any is used for creating XML Schema Any objects.

  id = ID
  maxOccurs = (nonNegativeInteger | unbounded)  : 1
  minOccurs = nonNegativeInteger : 1
  namespace = ((##any | ##other) | List of (anyURI | (##targetNamespace | ##local)) )  : ##any
  processContents = (lax | skip | strict) : strict
  {any attributes with non-schema namespace ...}>
  Content: (annotation?)

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::Any->new();

Create a new Rinchi::XMLSchema::Any object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::Any::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::Any::maxOccurs

=item $value = $Object->maxOccurs([$new_value]);

Set or get value of the 'maxOccurs' attribute.

=cut

sub maxOccurs() {
  my $self = shift;
  if (@_) {
    $self->{'_maxOccurs'} = shift;
  }
  return $self->{'_maxOccurs'};
}

#===============================================================================
# Rinchi::XMLSchema::Any::minOccurs

=item $value = $Object->minOccurs([$new_value]);

Set or get value of the 'minOccurs' attribute.

=cut

sub minOccurs() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-0-9A-Za-z_.:]+$/) {
      $self->{'_minOccurs'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting NMTOKEN.'
    }
  }
  return $self->{'_minOccurs'};
}

#===============================================================================
# Rinchi::XMLSchema::Any::namespace

=item $value = $Object->namespace([$new_value]);

Set or get value of the 'namespace' attribute.

=cut

sub namespace() {
  my $self = shift;
  if (@_) {
    $self->{'_namespace'} = shift;
  }
  return $self->{'_namespace'};
}

#===============================================================================
# Rinchi::XMLSchema::Any::processContents

=item $value = $Object->processContents([$new_value]);

Set or get value of the 'processContents' attribute.

=cut

sub processContents() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^skip|lax|strict$/) {
      $self->{'_processContents'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting value \'skip | lax | strict\'.'
    }
  }
  return $self->{'_processContents'};
}

#===============================================================================
# Rinchi::XMLSchema::Any::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_maxOccurs'})) {
    if (exists($other->{'_maxOccurs'})) {
      return 0 unless ($self->{'_maxOccurs'} eq $other->{'_maxOccurs'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_maxOccurs'}));
  }

  if (exists($self->{'_minOccurs'})) {
    if (exists($other->{'_minOccurs'})) {
      return 0 unless ($self->{'_minOccurs'} eq $other->{'_minOccurs'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_minOccurs'}));
  }

  if (exists($self->{'_namespace'})) {
    if (exists($other->{'_namespace'})) {
      return 0 unless ($self->{'_namespace'} eq $other->{'_namespace'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_namespace'}));
  }

  if (exists($self->{'_processContents'})) {
    if (exists($other->{'_processContents'})) {
      return 0 unless ($self->{'_processContents'} eq $other->{'_processContents'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_processContents'}));
  }

  my @self_cont = @{$self->{'_content_'}};
  my @other_cont = @{$other->{'_content_'}};
  shift @self_cont while(@self_cont and ref($self_cont[0]) eq 'Rinchi::XMLSchema::Annotation');
  shift @other_cont while(@other_cont and ref($other_cont[0]) eq 'Rinchi::XMLSchema::Annotation');

  if (@self_cont) {
    if (@other_cont) {
      while (@self_cont and @other_cont) {
        my $sc = shift @self_cont;
        my $oc = shift @other_cont;
        return 0 unless($sc->sameAs($oc));
      }
      return (0) if (@self_cont or @other_cont);
    } else {
      return 0;
    }  
  } else {
    return 0 if (@other_cont);
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::AnyAttribute;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of AnyAttribute class

Rinchi::XMLSchema::AnyAttribute is used for creating XML Schema AnyAttribute objects.

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::AnyAttribute->new();

Create a new Rinchi::XMLSchema::AnyAttribute object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::AnyAttribute::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::AnyAttribute::namespace

=item $value = $Object->namespace([$new_value]);

Set or get value of the 'namespace' attribute.

=cut

sub namespace() {
  my $self = shift;
  if (@_) {
    $self->{'_namespace'} = shift;
  }
  return $self->{'_namespace'};
}

#===============================================================================
# Rinchi::XMLSchema::AnyAttribute::processContents

=item $value = $Object->processContents([$new_value]);

Set or get value of the 'processContents' attribute.

=cut

sub processContents() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^skip|lax|strict$/) {
      $self->{'_processContents'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting value \'skip | lax | strict\'.'
    }
  }
  return $self->{'_processContents'};
}

#===============================================================================
# Rinchi::XMLSchema::AnyAttribute::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_namespace'})) {
    if (exists($other->{'_namespace'})) {
      return 0 unless ($self->{'_namespace'} eq $other->{'_namespace'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_namespace'}));
  }

  if (exists($self->{'_processContents'})) {
    if (exists($other->{'_processContents'})) {
      return 0 unless ($self->{'_processContents'} eq $other->{'_processContents'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_processContents'}));
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::Appinfo;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Appinfo class

Rinchi::XMLSchema::Appinfo is used for creating XML Schema Appinfo objects.

 source = anyURI
 {any attributes with non-schema namespace ...}>
 Content: ({any})*

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::Appinfo->new();

Create a new Rinchi::XMLSchema::Appinfo object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::Appinfo::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::Appinfo::source

=item $value = $Object->source([$new_value]);

Set or get value of the 'source' attribute.

=cut

sub source() {
  my $self = shift;
  if (@_) {
    $self->{'_source'} = shift;
  }
  return $self->{'_source'};
}

#===============================================================================

package Rinchi::XMLSchema::Attribute;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Attribute class

Rinchi::XMLSchema::Attribute is used for creating XML Schema Attribute objects.

 default = string
 fixed = string
 form = (qualified | unqualified)
 id = ID
 name = NCName
 ref = QName
 type = QName
 use = (optional | prohibited | required) : optional
 {any attributes with non-schema namespace ...}>
 Content: (annotation?, simpleType?)

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::Attribute->new();

Create a new Rinchi::XMLSchema::Attribute object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::Attribute::default

=item $value = $Object->default([$new_value]);

Set or get value of the 'default' attribute.

=cut

sub default() {
  my $self = shift;
  if (@_) {
    $self->{'_default'} = shift;
  }
  return $self->{'_default'};
}

#===============================================================================
# Rinchi::XMLSchema::Attribute::fixed

=item $value = $Object->fixed([$new_value]);

Set or get value of the 'fixed' attribute.

=cut

sub fixed() {
  my $self = shift;
  if (@_) {
    $self->{'_fixed'} = shift;
  }
  return $self->{'_fixed'};
}

#===============================================================================
# Rinchi::XMLSchema::Attribute::form

=item $value = $Object->form([$new_value]);

Set or get value of the 'form' attribute.

=cut

sub form() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^qualified|unqualified$/) {
      $self->{'_form'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting value \'qualified | unqualified\'.'
    }
  }
  return $self->{'_form'};
}

#===============================================================================
# Rinchi::XMLSchema::Attribute::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::Attribute::name

=item $value = $Object->name([$new_value]);

Set or get value of the 'name' attribute.

=cut

sub name() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_name'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting an XML name.'
    }
  }
  return $self->{'_name'};
}

#===============================================================================
# Rinchi::XMLSchema::Attribute::ref

=item $value = $Object->ref([$new_value]);

Set or get value of the 'ref' attribute.

=cut

sub ref() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_ref'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting an XML name.'
    }
  }
  return $self->{'_ref'};
}

#===============================================================================
# Rinchi::XMLSchema::Attribute::type

=item $value = $Object->type([$new_value]);

Set or get value of the 'type' attribute.

=cut

sub type() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_type'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting an XML name.'
    }
  }
  return $self->{'_type'};
}

#===============================================================================
# Rinchi::XMLSchema::Attribute::use

=item $value = $Object->use([$new_value]);

Set or get value of the 'use' attribute.

=cut

sub use() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^prohibited|optional|required$/) {
      $self->{'_use'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting value \'prohibited | optional | required\'.'
    }
  }
  return $self->{'_use'};
}

#===============================================================================
# Rinchi::XMLSchema::Attribute::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (CORE::ref($other) eq CORE::ref($self));

  if (exists($self->{'_default'})) {
    if (exists($other->{'_default'})) {
      return 0 unless ($self->{'_default'} eq $other->{'_default'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_default'}));
  }

  if (exists($self->{'_fixed'})) {
    if (exists($other->{'_fixed'})) {
      return 0 unless ($self->{'_fixed'} eq $other->{'_fixed'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_fixed'}));
  }

  if (exists($self->{'_form'})) {
    if (exists($other->{'_form'})) {
      return 0 unless ($self->{'_form'} eq $other->{'_form'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_form'}));
  }

  if (exists($self->{'_name'})) {
    if (exists($other->{'_name'})) {
      return 0 unless ($self->{'_name'} eq $other->{'_name'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_name'}));
  }

  if (exists($self->{'_ref'})) {
    if (exists($other->{'_ref'})) {
      return 0 unless ($self->{'_ref'} eq $other->{'_ref'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_ref'}));
  }

  if (exists($self->{'_type'})) {
    if (exists($other->{'_type'})) {
      return 0 unless ($self->{'_type'} eq $other->{'_type'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_type'}));
  }

  if (exists($self->{'_use'})) {
    if (exists($other->{'_use'})) {
      return 0 unless ($self->{'_use'} eq $other->{'_use'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_use'}));
  }

  my @self_cont = @{$self->{'_content_'}};
  my @other_cont = @{$other->{'_content_'}};
  shift @self_cont while(@self_cont and CORE::ref($self_cont[0]) eq 'Rinchi::XMLSchema::Annotation');
  shift @other_cont while(@other_cont and CORE::ref($other_cont[0]) eq 'Rinchi::XMLSchema::Annotation');

  if (@self_cont) {
    if (@other_cont) {
      while (@self_cont and @other_cont) {
        my $sc = shift @self_cont;
        my $oc = shift @other_cont;
        return 0 unless($sc->sameAs($oc));
      }
      return (0) if (@self_cont or @other_cont);
    } else {
      return 0;
    }  
  } else {
    return 0 if (@other_cont);
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::AttributeGroup;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of AttributeGroup class

Rinchi::XMLSchema::AttributeGroup is used for creating XML Schema AttributeGroup objects.

 id = ID
 name = NCName
 ref = QName
 {any attributes with non-schema namespace ...}>
 Content: (annotation?, ((attribute | attributeGroup)*, anyAttribute?))

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::AttributeGroup->new();

Create a new Rinchi::XMLSchema::AttributeGroup object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::AttributeGroup::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::AttributeGroup::name

=item $value = $Object->name([$new_value]);

Set or get value of the 'name' attribute.

=cut

sub name() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-0-9A-Za-z_.:]+$/) {
      $self->{'_name'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting NMTOKEN.'
    }
  }
  return $self->{'_name'};
}

#===============================================================================
# Rinchi::XMLSchema::AttributeGroup::ref

=item $value = $Object->ref([$new_value]);

Set or get value of the 'ref' attribute.

=cut

sub ref() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-0-9A-Za-z_.:]+$/) {
      $self->{'_ref'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting NMTOKEN.'
    }
  }
  return $self->{'_ref'};
}

#===============================================================================
# Rinchi::XMLSchema::AttributeGroup::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (CORE::ref($other) eq CORE::ref($self));

  if (exists($self->{'_name'})) {
    if (exists($other->{'_name'})) {
      return 0 unless ($self->{'_name'} eq $other->{'_name'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_name'}));
  }

  if (exists($self->{'_ref'})) {
    if (exists($other->{'_ref'})) {
      return 0 unless ($self->{'_ref'} eq $other->{'_ref'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_ref'}));
  }

  my @self_cont = @{$self->{'_content_'}};
  my @other_cont = @{$other->{'_content_'}};
  shift @self_cont while(@self_cont and CORE::ref($self_cont[0]) eq 'Rinchi::XMLSchema::Annotation');
  shift @other_cont while(@other_cont and CORE::ref($other_cont[0]) eq 'Rinchi::XMLSchema::Annotation');

  if (@self_cont) {
    if (@other_cont) {
      while (@self_cont and @other_cont) {
        my $sc = shift @self_cont;
        my $oc = shift @other_cont;
        return 0 unless($sc->sameAs($oc));
      }
      return (0) if (@self_cont or @other_cont);
    } else {
      return 0;
    }  
  } else {
    return 0 if (@other_cont);
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::Choice;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Choice class

Rinchi::XMLSchema::Choice is used for creating XML Schema Choice objects.

 id = ID
 maxOccurs = (nonNegativeInteger | unbounded)  : 1
 minOccurs = nonNegativeInteger : 1
 {any attributes with non-schema namespace ...}>
 Content: (annotation?, (element | group | choice | sequence | any)*)

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::Choice->new();

Create a new Rinchi::XMLSchema::Choice object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::Choice::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::Choice::maxOccurs

=item $value = $Object->maxOccurs([$new_value]);

Set or get value of the 'maxOccurs' attribute.

=cut

sub maxOccurs() {
  my $self = shift;
  if (@_) {
    $self->{'_maxOccurs'} = shift;
  }
  return $self->{'_maxOccurs'};
}

#===============================================================================
# Rinchi::XMLSchema::Choice::minOccurs

=item $value = $Object->minOccurs([$new_value]);

Set or get value of the 'minOccurs' attribute.

=cut

sub minOccurs() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-0-9A-Za-z_.:]+$/) {
      $self->{'_minOccurs'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting NMTOKEN.'
    }
  }
  return $self->{'_minOccurs'};
}

#===============================================================================
# Rinchi::XMLSchema::Choice::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_maxOccurs'})) {
    if (exists($other->{'_maxOccurs'})) {
      return 0 unless ($self->{'_maxOccurs'} eq $other->{'_maxOccurs'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_maxOccurs'}));
  }

  if (exists($self->{'_minOccurs'})) {
    if (exists($other->{'_minOccurs'})) {
      return 0 unless ($self->{'_minOccurs'} eq $other->{'_minOccurs'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_minOccurs'}));
  }

  my @self_cont = @{$self->{'_content_'}};
  my @other_cont = @{$other->{'_content_'}};
  shift @self_cont while(@self_cont and ref($self_cont[0]) eq 'Rinchi::XMLSchema::Annotation');
  shift @other_cont while(@other_cont and ref($other_cont[0]) eq 'Rinchi::XMLSchema::Annotation');

  if (@self_cont) {
    if (@other_cont) {
      while (@self_cont and @other_cont) {
        my $sc = shift @self_cont;
        my $oc = shift @other_cont;
        return 0 unless($sc->sameAs($oc));
      }
      return (0) if (@self_cont or @other_cont);
    } else {
      return 0;
    }  
  } else {
    return 0 if (@other_cont);
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::ComplexContent;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of ComplexContent class

Rinchi::XMLSchema::ComplexContent is used for creating XML Schema ComplexContent objects.

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::ComplexContent->new();

Create a new Rinchi::XMLSchema::ComplexContent object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::ComplexContent::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::ComplexContent::mixed

=item $value = $Object->mixed([$new_value]);

Set or get value of the 'mixed' attribute.

=cut

sub mixed() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^true|false$/) {
      $self->{'_mixed'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting value \'true | false\'.'
    }
  }
  return $self->{'_mixed'};
}

#===============================================================================
# Rinchi::XMLSchema::ComplexContent::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_mixed'})) {
    if (exists($other->{'_mixed'})) {
      return 0 unless ($self->{'_mixed'} eq $other->{'_mixed'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_mixed'}));
  }

  my @self_cont = @{$self->{'_content_'}};
  my @other_cont = @{$other->{'_content_'}};
  shift @self_cont while(@self_cont and ref($self_cont[0]) eq 'Rinchi::XMLSchema::Annotation');
  shift @other_cont while(@other_cont and ref($other_cont[0]) eq 'Rinchi::XMLSchema::Annotation');

  if (@self_cont) {
    if (@other_cont) {
      while (@self_cont and @other_cont) {
        my $sc = shift @self_cont;
        my $oc = shift @other_cont;
        return 0 unless($sc->sameAs($oc));
      }
      return (0) if (@self_cont or @other_cont);
    } else {
      return 0;
    }  
  } else {
    return 0 if (@other_cont);
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::ComplexType;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of ComplexType class

Rinchi::XMLSchema::ComplexType is used for creating XML Schema ComplexType objects.

 abstract = boolean : false
 block = (#all | List of (extension | restriction))
 final = (#all | List of (extension | restriction))
 id = ID
 mixed = boolean : false
 name = NCName
 {any attributes with non-schema namespace ...}>
 Content: (annotation?, (simpleContent | complexContent | ((group | all | choice | sequence)?, ((attribute | attributeGroup)*, anyAttribute?))))

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::ComplexType->new();

Create a new Rinchi::XMLSchema::ComplexType object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::ComplexType::abstract

=item $value = $Object->abstract([$new_value]);

Set or get value of the 'abstract' attribute.

=cut

sub abstract() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^true|false$/) {
      $self->{'_abstract'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting value \'true | false\'.'
    }
  }
  return $self->{'_abstract'};
}

#===============================================================================
# Rinchi::XMLSchema::ComplexType::block

=item $value = $Object->block([$new_value]);

Set or get value of the 'block' attribute.

=cut

sub block() {
  my $self = shift;
  if (@_) {
    $self->{'_block'} = shift;
  }
  return $self->{'_block'};
}

#===============================================================================
# Rinchi::XMLSchema::ComplexType::final

=item $value = $Object->final([$new_value]);

Set or get value of the 'final' attribute.

=cut

sub final() {
  my $self = shift;
  if (@_) {
    $self->{'_final'} = shift;
  }
  return $self->{'_final'};
}

#===============================================================================
# Rinchi::XMLSchema::ComplexType::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::ComplexType::mixed

=item $value = $Object->mixed([$new_value]);

Set or get value of the 'mixed' attribute.

=cut

sub mixed() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^true|false$/) {
      $self->{'_mixed'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting value \'true | false\'.'
    }
  }
  return $self->{'_mixed'};
}

#===============================================================================
# Rinchi::XMLSchema::ComplexType::name

=item $value = $Object->name([$new_value]);

Set or get value of the 'name' attribute.

=cut

sub name() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-0-9A-Za-z_.:]+$/) {
      $self->{'_name'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting NMTOKEN.'
    }
  }
  return $self->{'_name'};
}

#===============================================================================
# Rinchi::XMLSchema::ComplexType::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;
  
  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_abstract'})) {
    if (exists($other->{'_abstract'})) {
      return 0 unless ($self->{'_abstract'} eq $other->{'_abstract'});
    } else {
      return 0;
    }  
  } else {
    return 0 if (exists($other->{'_abstract'}));
  }

  if (exists($self->{'_block'})) {
    if (exists($other->{'_block'})) {
      return 0 unless ($self->{'_block'} eq $other->{'_block'});
    } else {
      return 0;
    }  
  } else {
    return 0 if (exists($other->{'_block'}));
  }

  if (exists($self->{'_final'})) {
    if (exists($other->{'_final'})) {
      return 0 unless ($self->{'_final'} eq $other->{'_final'});
    } else {
      return 0;
    }  
  } else {
    return 0 if (exists($other->{'_final'}));
  }

  if (exists($self->{'_mixed'})) {
    if (exists($other->{'_mixed'})) {
      return 0 unless ($self->{'_mixed'} eq $other->{'_mixed'});
    } else {
      return 0;
    }  
  } else {
    return 0 if (exists($other->{'_mixed'}));
  }

  if (exists($self->{'_name'})) {
    if (exists($other->{'_name'})) {
      return 0 unless ($self->{'_name'} eq $other->{'_name'});
    } else {
      return 0;
    }  
  } else {
    return 0 if (exists($other->{'_name'}));
  }

  my @self_cont = @{$self->{'_content_'}};
  my @other_cont = @{$other->{'_content_'}};
  
  shift @self_cont if(@self_cont and ref($self_cont[0]) eq 'Rinchi::XMLSchema::Annotation');
  shift @other_cont if(@other_cont and ref($other_cont[0]) eq 'Rinchi::XMLSchema::Annotation');
  
  if (@self_cont) {
    if (@other_cont) {
      while (@self_cont and @other_cont) {
        my $sc = shift @self_cont;
        my $oc = shift @other_cont;
       
        return 0 unless($sc->sameAs($oc));
      }
      return (0) if (@self_cont or @other_cont);
    } else {
      return 0;
    }  
  } else {
    return 0 if (@other_cont);
  }
  
  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::Documentation;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Documentation class

Rinchi::XMLSchema::Documentation is used for creating XML Schema Documentation objects.

 source = anyURI
 xml:lang = language
 {any attributes with non-schema namespace ...}>
 Content: ({any})*

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::Documentation->new();

Create a new Rinchi::XMLSchema::Documentation object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::Documentation::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::Documentation::source

=item $value = $Object->source([$new_value]);

Set or get value of the 'source' attribute.

=cut

sub source() {
  my $self = shift;
  if (@_) {
    $self->{'_source'} = shift;
  }
  return $self->{'_source'};
}

#===============================================================================
# Rinchi::XMLSchema::Documentation::xml:lang

=item $value = $Object->xml_lang([$new_value]);

Set or get value of the 'xml:lang' attribute.

=cut

sub xml_lang() {
  my $self = shift;
  if (@_) {
    $self->{'_xml:lang'} = shift;
  }
  return $self->{'_xml:lang'};
}

#===============================================================================

package Rinchi::XMLSchema::Element;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Element class

Rinchi::XMLSchema::Element is used for creating XML Schema Element objects.

 abstract = boolean : false
 block = (#all | List of (extension | restriction | substitution))
 default = string
 final = (#all | List of (extension | restriction))
 fixed = string
 form = (qualified | unqualified)
 id = ID
 maxOccurs = (nonNegativeInteger | unbounded)  : 1
 minOccurs = nonNegativeInteger : 1
 name = NCName
 nillable = boolean : false
 ref = QName
 substitutionGroup = QName
 type = QName
 {any attributes with non-schema namespace ...}>
 Content: (annotation?, ((simpleType | complexType)?, (unique | key | keyref)*))

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::Element->new();

Create a new Rinchi::XMLSchema::Element object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::Element::abstract

=item $value = $Object->abstract([$new_value]);

Set or get value of the 'abstract' attribute.

=cut

sub abstract() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^true|false$/) {
      $self->{'_abstract'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting value \'true | false\'.'
    }
  }
  return $self->{'_abstract'};
}

#===============================================================================
# Rinchi::XMLSchema::Element::block

=item $value = $Object->block([$new_value]);

Set or get value of the 'block' attribute.

=cut

sub block() {
  my $self = shift;
  if (@_) {
    $self->{'_block'} = shift;
  }
  return $self->{'_block'};
}

#===============================================================================
# Rinchi::XMLSchema::Element::default

=item $value = $Object->default([$new_value]);

Set or get value of the 'default' attribute.

=cut

sub default() {
  my $self = shift;
  if (@_) {
    $self->{'_default'} = shift;
  }
  return $self->{'_default'};
}

#===============================================================================
# Rinchi::XMLSchema::Element::final

=item $value = $Object->final([$new_value]);

Set or get value of the 'final' attribute.

=cut

sub final() {
  my $self = shift;
  if (@_) {
    $self->{'_final'} = shift;
  }
  return $self->{'_final'};
}

#===============================================================================
# Rinchi::XMLSchema::Element::fixed

=item $value = $Object->fixed([$new_value]);

Set or get value of the 'fixed' attribute.

=cut

sub fixed() {
  my $self = shift;
  if (@_) {
    $self->{'_fixed'} = shift;
  }
  return $self->{'_fixed'};
}

#===============================================================================
# Rinchi::XMLSchema::Element::form

=item $value = $Object->form([$new_value]);

Set or get value of the 'form' attribute.

=cut

sub form() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^qualified|unqualified$/) {
      $self->{'_form'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting value \'qualified | unqualified\'.'
    }
  }
  return $self->{'_form'};
}

#===============================================================================
# Rinchi::XMLSchema::Element::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::Element::maxOccurs

=item $value = $Object->maxOccurs([$new_value]);

Set or get value of the 'maxOccurs' attribute.

=cut

sub maxOccurs() {
  my $self = shift;
  if (@_) {
    $self->{'_maxOccurs'} = shift;
  }
  return $self->{'_maxOccurs'};
}

#===============================================================================
# Rinchi::XMLSchema::Element::minOccurs

=item $value = $Object->minOccurs([$new_value]);

Set or get value of the 'minOccurs' attribute.

=cut

sub minOccurs() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-0-9A-Za-z_.:]+$/) {
      $self->{'_minOccurs'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting NMTOKEN.'
    }
  }
  return $self->{'_minOccurs'};
}

#===============================================================================
# Rinchi::XMLSchema::Element::name

=item $value = $Object->name([$new_value]);

Set or get value of the 'name' attribute.

=cut

sub name() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-0-9A-Za-z_.:]+$/) {
      $self->{'_name'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting NMTOKEN.'
    }
  }
  return $self->{'_name'};
}

#===============================================================================
# Rinchi::XMLSchema::Element::nillable

=item $value = $Object->nillable([$new_value]);

Set or get value of the 'nillable' attribute.

=cut

sub nillable() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^true|false$/) {
      $self->{'_nillable'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting value \'true | false\'.'
    }
  }
  return $self->{'_nillable'};
}

#===============================================================================
# Rinchi::XMLSchema::Element::ref

=item $value = $Object->ref([$new_value]);

Set or get value of the 'ref' attribute.

=cut

sub ref() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-0-9A-Za-z_.:]+$/) {
      $self->{'_ref'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting NMTOKEN.'
    }
  }
  return $self->{'_ref'};
}

#===============================================================================
# Rinchi::XMLSchema::Element::substitutionGroup

=item $value = $Object->substitutionGroup([$new_value]);

Set or get value of the 'substitutionGroup' attribute.

=cut

sub substitutionGroup() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-0-9A-Za-z_.:]+$/) {
      $self->{'_substitutionGroup'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting NMTOKEN.'
    }
  }
  return $self->{'_substitutionGroup'};
}

#===============================================================================
# Rinchi::XMLSchema::Element::type

=item $value = $Object->type([$new_value]);

Set or get value of the 'type' attribute.

=cut

sub type() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-0-9A-Za-z_.:]+$/) {
      $self->{'_type'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting NMTOKEN.'
    }
  }
  return $self->{'_type'};
}

#===============================================================================
# Rinchi::XMLSchema::Element::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (CORE::ref($other) eq CORE::ref($self));

  if (exists($self->{'_abstract'})) {
    if (exists($other->{'_abstract'})) {
      return 0 unless ($self->{'_abstract'} eq $other->{'_abstract'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_abstract'}));
  }

  if (exists($self->{'_block'})) {
    if (exists($other->{'_block'})) {
      return 0 unless ($self->{'_block'} eq $other->{'_block'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_block'}));
  }

  if (exists($self->{'_default'})) {
    if (exists($other->{'_default'})) {
      return 0 unless ($self->{'_default'} eq $other->{'_default'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_default'}));
  }

  if (exists($self->{'_final'})) {
    if (exists($other->{'_final'})) {
      return 0 unless ($self->{'_final'} eq $other->{'_final'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_final'}));
  }

  if (exists($self->{'_fixed'})) {
    if (exists($other->{'_fixed'})) {
      return 0 unless ($self->{'_fixed'} eq $other->{'_fixed'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_fixed'}));
  }

  if (exists($self->{'_form'})) {
    if (exists($other->{'_form'})) {
      return 0 unless ($self->{'_form'} eq $other->{'_form'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_form'}));
  }

  if (exists($self->{'_maxOccurs'})) {
    if (exists($other->{'_maxOccurs'})) {
      return 0 unless ($self->{'_maxOccurs'} eq $other->{'_maxOccurs'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_maxOccurs'}));
  }

  if (exists($self->{'_minOccurs'})) {
    if (exists($other->{'_minOccurs'})) {
      return 0 unless ($self->{'_minOccurs'} eq $other->{'_minOccurs'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_minOccurs'}));
  }

  if (exists($self->{'_name'})) {
    if (exists($other->{'_name'})) {
      return 0 unless ($self->{'_name'} eq $other->{'_name'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_name'}));
  }

  if (exists($self->{'_nillable'})) {
    if (exists($other->{'_nillable'})) {
      return 0 unless ($self->{'_nillable'} eq $other->{'_nillable'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_nillable'}));
  }

  if (exists($self->{'_ref'})) {
    if (exists($other->{'_ref'})) {
      return 0 unless ($self->{'_ref'} eq $other->{'_ref'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_ref'}));
  }

  if (exists($self->{'_substitutionGroup'})) {
    if (exists($other->{'_substitutionGroup'})) {
      return 0 unless ($self->{'_substitutionGroup'} eq $other->{'_substitutionGroup'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_substitutionGroup'}));
  }

  if (exists($self->{'_type'})) {
    if (exists($other->{'_type'})) {
      return 0 unless ($self->{'_type'} eq $other->{'_type'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_type'}));
  }

  my @self_cont = @{$self->{'_content_'}};
  my @other_cont = @{$other->{'_content_'}};
  shift @self_cont while(@self_cont and CORE::ref($self_cont[0]) eq 'Rinchi::XMLSchema::Annotation');
  shift @other_cont while(@other_cont and CORE::ref($other_cont[0]) eq 'Rinchi::XMLSchema::Annotation');

  if (@self_cont) {
    if (@other_cont) {
      while (@self_cont and @other_cont) {
        my $sc = shift @self_cont;
        my $oc = shift @other_cont;
        return 0 unless($sc->sameAs($oc));
      }
      return (0) if (@self_cont or @other_cont);
    } else {
      return 0;
    }  
  } else {
    return 0 if (@other_cont);
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::Enumeration;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Enumeration class

Rinchi::XMLSchema::Enumeration is used for creating XML Schema Enumeration objects.

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::Enumeration->new();

Create a new Rinchi::XMLSchema::Enumeration object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::Enumeration::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::Enumeration::value

=item $value = $Object->value([$new_value]);

Set or get value of the 'value' attribute.

=cut

sub value() {
  my $self = shift;
  if (@_) {
    $self->{'_value'} = shift;
  }
  return $self->{'_value'};
}

#===============================================================================
# Rinchi::XMLSchema::Enumeration::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_value'})) {
    if (exists($other->{'_value'})) {
      return 0 unless ($self->{'_value'} eq $other->{'_value'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_value'}));
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::Extension;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Extension class

Rinchi::XMLSchema::Extension is used for creating XML Schema Extension objects.

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::Extension->new();

Create a new Rinchi::XMLSchema::Extension object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::Extension::base

=item $value = $Object->base([$new_value]);

Set or get value of the 'base' attribute.

=cut

sub base() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-0-9A-Za-z_.:]+$/) {
      $self->{'_base'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting NMTOKEN.'
    }
  }
  return $self->{'_base'};
}

#===============================================================================
# Rinchi::XMLSchema::Extension::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::Extension::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_base'})) {
    if (exists($other->{'_base'})) {
      return 0 unless ($self->{'_base'} eq $other->{'_base'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_base'}));
  }

  my @self_cont = @{$self->{'_content_'}};
  my @other_cont = @{$other->{'_content_'}};
  shift @self_cont while(@self_cont and ref($self_cont[0]) eq 'Rinchi::XMLSchema::Annotation');
  shift @other_cont while(@other_cont and ref($other_cont[0]) eq 'Rinchi::XMLSchema::Annotation');

  if (@self_cont) {
    if (@other_cont) {
      while (@self_cont and @other_cont) {
        my $sc = shift @self_cont;
        my $oc = shift @other_cont;
        return 0 unless($sc->sameAs($oc));
      }
      return (0) if (@self_cont or @other_cont);
    } else {
      return 0;
    }  
  } else {
    return 0 if (@other_cont);
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::Field;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Field class

Rinchi::XMLSchema::Field is used for creating XML Schema Field objects.

 id = ID
 xpath = a subset of XPath expression, see below
 {any attributes with non-schema namespace ...}>
 Content: (annotation?)

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::Field->new();

Create a new Rinchi::XMLSchema::Field object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::Field::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::Field::xpath

=item $value = $Object->xpath([$new_value]);

Set or get value of the 'xpath' attribute.

=cut

sub xpath() {
  my $self = shift;
  if (@_) {
    $self->{'_xpath'} = shift;
  }
  return $self->{'_xpath'};
}

#===============================================================================
# Rinchi::XMLSchema::Field::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_xpath'})) {
    if (exists($other->{'_xpath'})) {
      return 0 unless ($self->{'_xpath'} eq $other->{'_xpath'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_xpath'}));
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::FractionDigits;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of FractionDigits class

Rinchi::XMLSchema::FractionDigits is used for creating XML Schema FractionDigits objects.

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::FractionDigits->new();

Create a new Rinchi::XMLSchema::FractionDigits object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::FractionDigits::fixed

=item $value = $Object->fixed([$new_value]);

Set or get value of the 'fixed' attribute.

=cut

sub fixed() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^true|false$/) {
      $self->{'_fixed'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting value \'true | false\'.'
    }
  }
  return $self->{'_fixed'};
}

#===============================================================================
# Rinchi::XMLSchema::FractionDigits::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::FractionDigits::value

=item $value = $Object->value([$new_value]);

Set or get value of the 'value' attribute.

=cut

sub value() {
  my $self = shift;
  if (@_) {
    $self->{'_value'} = shift;
  }
  return $self->{'_value'};
}

#===============================================================================
# Rinchi::XMLSchema::FractionDigits::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_fixed'})) {
    if (exists($other->{'_fixed'})) {
      return 0 unless ($self->{'_fixed'} eq $other->{'_fixed'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_fixed'}));
  }

  if (exists($self->{'_value'})) {
    if (exists($other->{'_value'})) {
      return 0 unless ($self->{'_value'} eq $other->{'_value'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_value'}));
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::Group;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Group class

Rinchi::XMLSchema::Group is used for creating XML Schema Group objects.

 id = ID
 maxOccurs = (nonNegativeInteger | unbounded)  : 1
 minOccurs = nonNegativeInteger : 1
 name = NCName
 ref = QName
 {any attributes with non-schema namespace ...}>
 Content: (annotation?, (all | choice | sequence)?)

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::Group->new();

Create a new Rinchi::XMLSchema::Group object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::Group::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::Group::maxOccurs

=item $value = $Object->maxOccurs([$new_value]);

Set or get value of the 'maxOccurs' attribute.

=cut

sub maxOccurs() {
  my $self = shift;
  if (@_) {
    $self->{'_maxOccurs'} = shift;
  }
  return $self->{'_maxOccurs'};
}

#===============================================================================
# Rinchi::XMLSchema::Group::minOccurs

=item $value = $Object->minOccurs([$new_value]);

Set or get value of the 'minOccurs' attribute.

=cut

sub minOccurs() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-0-9A-Za-z_.:]+$/) {
      $self->{'_minOccurs'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting NMTOKEN.'
    }
  }
  return $self->{'_minOccurs'};
}

#===============================================================================
# Rinchi::XMLSchema::Group::name

=item $value = $Object->name([$new_value]);

Set or get value of the 'name' attribute.

=cut

sub name() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-0-9A-Za-z_.:]+$/) {
      $self->{'_name'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting NMTOKEN.'
    }
  }
  return $self->{'_name'};
}

#===============================================================================
# Rinchi::XMLSchema::Group::ref

=item $value = $Object->ref([$new_value]);

Set or get value of the 'ref' attribute.

=cut

sub ref() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-0-9A-Za-z_.:]+$/) {
      $self->{'_ref'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting NMTOKEN.'
    }
  }
  return $self->{'_ref'};
}

#===============================================================================
# Rinchi::XMLSchema::Group::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (CORE::ref($other) eq CORE::ref($self));

  if (exists($self->{'_maxOccurs'})) {
    if (exists($other->{'_maxOccurs'})) {
      return 0 unless ($self->{'_maxOccurs'} eq $other->{'_maxOccurs'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_maxOccurs'}));
  }

  if (exists($self->{'_minOccurs'})) {
    if (exists($other->{'_minOccurs'})) {
      return 0 unless ($self->{'_minOccurs'} eq $other->{'_minOccurs'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_minOccurs'}));
  }

  if (exists($self->{'_name'})) {
    if (exists($other->{'_name'})) {
      return 0 unless ($self->{'_name'} eq $other->{'_name'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_name'}));
  }

  if (exists($self->{'_ref'})) {
    if (exists($other->{'_ref'})) {
      return 0 unless ($self->{'_ref'} eq $other->{'_ref'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_ref'}));
  }

  my @self_cont = @{$self->{'_content_'}};
  my @other_cont = @{$other->{'_content_'}};
  shift @self_cont while(@self_cont and CORE::ref($self_cont[0]) eq 'Rinchi::XMLSchema::Annotation');
  shift @other_cont while(@other_cont and CORE::ref($other_cont[0]) eq 'Rinchi::XMLSchema::Annotation');

  if (@self_cont) {
    if (@other_cont) {
      while (@self_cont and @other_cont) {
        my $sc = shift @self_cont;
        my $oc = shift @other_cont;
        return 0 unless($sc->sameAs($oc));
      }
      return (0) if (@self_cont or @other_cont);
    } else {
      return 0;
    }  
  } else {
    return 0 if (@other_cont);
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::Import;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Import class

Rinchi::XMLSchema::Import is used for creating XML Schema Import objects.

 id = ID
 namespace = anyURI
 schemaLocation = anyURI
 {any attributes with non-schema namespace . . .}>
 Content: (annotation?)

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::Import->new();

Create a new Rinchi::XMLSchema::Import object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::Import::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::Import::namespace

=item $value = $Object->namespace([$new_value]);

Set or get value of the 'namespace' attribute.

=cut

sub namespace() {
  my $self = shift;
  if (@_) {
    $self->{'_namespace'} = shift;
  }
  return $self->{'_namespace'};
}

#===============================================================================
# Rinchi::XMLSchema::Import::schemaLocation

=item $value = $Object->schemaLocation([$new_value]);

Set or get value of the 'schemaLocation' attribute.

=cut

sub schemaLocation() {
  my $self = shift;
  if (@_) {
    $self->{'_schemaLocation'} = shift;
  }
  return $self->{'_schemaLocation'};
}

#===============================================================================
# Rinchi::XMLSchema::Import::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_namespace'})) {
    if (exists($other->{'_namespace'})) {
      return 0 unless ($self->{'_namespace'} eq $other->{'_namespace'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_namespace'}));
  }

  if (exists($self->{'_schemaLocation'})) {
    if (exists($other->{'_schemaLocation'})) {
      return 0 unless ($self->{'_schemaLocation'} eq $other->{'_schemaLocation'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_schemaLocation'}));
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::Include;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Include class

Rinchi::XMLSchema::Include is used for creating XML Schema Include objects.

 id = ID
 schemaLocation = anyURI
 {any attributes with non-schema namespace . . .}>
 Content: (annotation?)

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::Include->new();

Create a new Rinchi::XMLSchema::Include object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::Include::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::Include::schemaLocation

=item $value = $Object->schemaLocation([$new_value]);

Set or get value of the 'schemaLocation' attribute.

=cut

sub schemaLocation() {
  my $self = shift;
  if (@_) {
    $self->{'_schemaLocation'} = shift;
  }
  return $self->{'_schemaLocation'};
}

#===============================================================================
# Rinchi::XMLSchema::Include::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_schemaLocation'})) {
    if (exists($other->{'_schemaLocation'})) {
      return 0 unless ($self->{'_schemaLocation'} eq $other->{'_schemaLocation'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_schemaLocation'}));
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::Key;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Key class

Rinchi::XMLSchema::Key is used for creating XML Schema Key objects.

 id = ID
 name = NCName
 {any attributes with non-schema namespace ...}>
 Content: (annotation?, (selector, field+))

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::Key->new();

Create a new Rinchi::XMLSchema::Key object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::Key::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::Key::name

=item $value = $Object->name([$new_value]);

Set or get value of the 'name' attribute.

=cut

sub name() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-0-9A-Za-z_.:]+$/) {
      $self->{'_name'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting NMTOKEN.'
    }
  }
  return $self->{'_name'};
}

#===============================================================================
# Rinchi::XMLSchema::Key::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_name'})) {
    if (exists($other->{'_name'})) {
      return 0 unless ($self->{'_name'} eq $other->{'_name'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_name'}));
  }

  my @self_cont = @{$self->{'_content_'}};
  my @other_cont = @{$other->{'_content_'}};
  shift @self_cont while(@self_cont and ref($self_cont[0]) eq 'Rinchi::XMLSchema::Annotation');
  shift @other_cont while(@other_cont and ref($other_cont[0]) eq 'Rinchi::XMLSchema::Annotation');

  if (@self_cont) {
    if (@other_cont) {
      while (@self_cont and @other_cont) {
        my $sc = shift @self_cont;
        my $oc = shift @other_cont;
        return 0 unless($sc->sameAs($oc));
      }
      return (0) if (@self_cont or @other_cont);
    } else {
      return 0;
    }  
  } else {
    return 0 if (@other_cont);
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::Keyref;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Keyref class

Rinchi::XMLSchema::Keyref is used for creating XML Schema Keyref objects.

 id = ID
 name = NCName
 refer = QName
 {any attributes with non-schema namespace ...}>
 Content: (annotation?, (selector, field+))

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::Keyref->new();

Create a new Rinchi::XMLSchema::Keyref object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::Keyref::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::Keyref::name

=item $value = $Object->name([$new_value]);

Set or get value of the 'name' attribute.

=cut

sub name() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-0-9A-Za-z_.:]+$/) {
      $self->{'_name'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting NMTOKEN.'
    }
  }
  return $self->{'_name'};
}

#===============================================================================
# Rinchi::XMLSchema::Keyref::refer

=item $value = $Object->refer([$new_value]);

Set or get value of the 'refer' attribute.

=cut

sub refer() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-0-9A-Za-z_.:]+$/) {
      $self->{'_refer'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting NMTOKEN.'
    }
  }
  return $self->{'_refer'};
}

#===============================================================================
# Rinchi::XMLSchema::Keyref::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_name'})) {
    if (exists($other->{'_name'})) {
      return 0 unless ($self->{'_name'} eq $other->{'_name'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_name'}));
  }

  if (exists($self->{'_refer'})) {
    if (exists($other->{'_refer'})) {
      return 0 unless ($self->{'_refer'} eq $other->{'_refer'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_refer'}));
  }

  my @self_cont = @{$self->{'_content_'}};
  my @other_cont = @{$other->{'_content_'}};
  shift @self_cont while(@self_cont and ref($self_cont[0]) eq 'Rinchi::XMLSchema::Annotation');
  shift @other_cont while(@other_cont and ref($other_cont[0]) eq 'Rinchi::XMLSchema::Annotation');

  if (@self_cont) {
    if (@other_cont) {
      while (@self_cont and @other_cont) {
        my $sc = shift @self_cont;
        my $oc = shift @other_cont;
        return 0 unless($sc->sameAs($oc));
      }
      return (0) if (@self_cont or @other_cont);
    } else {
      return 0;
    }  
  } else {
    return 0 if (@other_cont);
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::Length;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Length class

Rinchi::XMLSchema::Length is used for creating XML Schema Length objects.

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::Length->new();

Create a new Rinchi::XMLSchema::Length object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::Length::fixed

=item $value = $Object->fixed([$new_value]);

Set or get value of the 'fixed' attribute.

=cut

sub fixed() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^true|false$/) {
      $self->{'_fixed'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting value \'true | false\'.'
    }
  }
  return $self->{'_fixed'};
}

#===============================================================================
# Rinchi::XMLSchema::Length::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::Length::value

=item $value = $Object->value([$new_value]);

Set or get value of the 'value' attribute.

=cut

sub value() {
  my $self = shift;
  if (@_) {
    $self->{'_value'} = shift;
  }
  return $self->{'_value'};
}

#===============================================================================
# Rinchi::XMLSchema::Length::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_fixed'})) {
    if (exists($other->{'_fixed'})) {
      return 0 unless ($self->{'_fixed'} eq $other->{'_fixed'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_fixed'}));
  }

  if (exists($self->{'_value'})) {
    if (exists($other->{'_value'})) {
      return 0 unless ($self->{'_value'} eq $other->{'_value'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_value'}));
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::List;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of List class

Rinchi::XMLSchema::List is used for creating XML Schema List objects.

 id = ID
 itemType = QName
 {any attributes with non-schema namespace ...}>
 Content: (annotation?, simpleType?)

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::List->new();

Create a new Rinchi::XMLSchema::List object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::List::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::List::itemType

=item $value = $Object->itemType([$new_value]);

Set or get value of the 'itemType' attribute.

=cut

sub itemType() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-0-9A-Za-z_.:]+$/) {
      $self->{'_itemType'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting NMTOKEN.'
    }
  }
  return $self->{'_itemType'};
}

#===============================================================================
# Rinchi::XMLSchema::List::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_itemType'})) {
    if (exists($other->{'_itemType'})) {
      return 0 unless ($self->{'_itemType'} eq $other->{'_itemType'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_itemType'}));
  }

  my @self_cont = @{$self->{'_content_'}};
  my @other_cont = @{$other->{'_content_'}};
  shift @self_cont while(@self_cont and ref($self_cont[0]) eq 'Rinchi::XMLSchema::Annotation');
  shift @other_cont while(@other_cont and ref($other_cont[0]) eq 'Rinchi::XMLSchema::Annotation');

  if (@self_cont) {
    if (@other_cont) {
      while (@self_cont and @other_cont) {
        my $sc = shift @self_cont;
        my $oc = shift @other_cont;
        return 0 unless($sc->sameAs($oc));
      }
      return (0) if (@self_cont or @other_cont);
    } else {
      return 0;
    }  
  } else {
    return 0 if (@other_cont);
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::MaxExclusive;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of MaxExclusive class

Rinchi::XMLSchema::MaxExclusive is used for creating XML Schema MaxExclusive objects.

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::MaxExclusive->new();

Create a new Rinchi::XMLSchema::MaxExclusive object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::MaxExclusive::fixed

=item $value = $Object->fixed([$new_value]);

Set or get value of the 'fixed' attribute.

=cut

sub fixed() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^true|false$/) {
      $self->{'_fixed'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting value \'true | false\'.'
    }
  }
  return $self->{'_fixed'};
}

#===============================================================================
# Rinchi::XMLSchema::MaxExclusive::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::MaxExclusive::value

=item $value = $Object->value([$new_value]);

Set or get value of the 'value' attribute.

=cut

sub value() {
  my $self = shift;
  if (@_) {
    $self->{'_value'} = shift;
  }
  return $self->{'_value'};
}

#===============================================================================
# Rinchi::XMLSchema::MaxExclusive::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_fixed'})) {
    if (exists($other->{'_fixed'})) {
      return 0 unless ($self->{'_fixed'} eq $other->{'_fixed'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_fixed'}));
  }

  if (exists($self->{'_value'})) {
    if (exists($other->{'_value'})) {
      return 0 unless ($self->{'_value'} eq $other->{'_value'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_value'}));
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::MaxInclusive;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of MaxInclusive class

Rinchi::XMLSchema::MaxInclusive is used for creating XML Schema MaxInclusive objects.

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::MaxInclusive->new();

Create a new Rinchi::XMLSchema::MaxInclusive object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::MaxInclusive::fixed

=item $value = $Object->fixed([$new_value]);

Set or get value of the 'fixed' attribute.

=cut

sub fixed() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^true|false$/) {
      $self->{'_fixed'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting value \'true | false\'.'
    }
  }
  return $self->{'_fixed'};
}

#===============================================================================
# Rinchi::XMLSchema::MaxInclusive::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::MaxInclusive::value

=item $value = $Object->value([$new_value]);

Set or get value of the 'value' attribute.

=cut

sub value() {
  my $self = shift;
  if (@_) {
    $self->{'_value'} = shift;
  }
  return $self->{'_value'};
}

#===============================================================================
# Rinchi::XMLSchema::MaxInclusive::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_fixed'})) {
    if (exists($other->{'_fixed'})) {
      return 0 unless ($self->{'_fixed'} eq $other->{'_fixed'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_fixed'}));
  }

  if (exists($self->{'_value'})) {
    if (exists($other->{'_value'})) {
      return 0 unless ($self->{'_value'} eq $other->{'_value'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_value'}));
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::MaxLength;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of MaxLength class

Rinchi::XMLSchema::MaxLength is used for creating XML Schema MaxLength objects.

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::MaxLength->new();

Create a new Rinchi::XMLSchema::MaxLength object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::MaxLength::fixed

=item $value = $Object->fixed([$new_value]);

Set or get value of the 'fixed' attribute.

=cut

sub fixed() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^true|false$/) {
      $self->{'_fixed'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting value \'true | false\'.'
    }
  }
  return $self->{'_fixed'};
}

#===============================================================================
# Rinchi::XMLSchema::MaxLength::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::MaxLength::value

=item $value = $Object->value([$new_value]);

Set or get value of the 'value' attribute.

=cut

sub value() {
  my $self = shift;
  if (@_) {
    $self->{'_value'} = shift;
  }
  return $self->{'_value'};
}

#===============================================================================
# Rinchi::XMLSchema::MaxLength::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_fixed'})) {
    if (exists($other->{'_fixed'})) {
      return 0 unless ($self->{'_fixed'} eq $other->{'_fixed'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_fixed'}));
  }

  if (exists($self->{'_value'})) {
    if (exists($other->{'_value'})) {
      return 0 unless ($self->{'_value'} eq $other->{'_value'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_value'}));
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::MinExclusive;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of MinExclusive class

Rinchi::XMLSchema::MinExclusive is used for creating XML Schema MinExclusive objects.

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::MinExclusive->new();

Create a new Rinchi::XMLSchema::MinExclusive object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::MinExclusive::fixed

=item $value = $Object->fixed([$new_value]);

Set or get value of the 'fixed' attribute.

=cut

sub fixed() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^true|false$/) {
      $self->{'_fixed'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting value \'true | false\'.'
    }
  }
  return $self->{'_fixed'};
}

#===============================================================================
# Rinchi::XMLSchema::MinExclusive::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::MinExclusive::value

=item $value = $Object->value([$new_value]);

Set or get value of the 'value' attribute.

=cut

sub value() {
  my $self = shift;
  if (@_) {
    $self->{'_value'} = shift;
  }
  return $self->{'_value'};
}

#===============================================================================
# Rinchi::XMLSchema::MinExclusive::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_fixed'})) {
    if (exists($other->{'_fixed'})) {
      return 0 unless ($self->{'_fixed'} eq $other->{'_fixed'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_fixed'}));
  }

  if (exists($self->{'_value'})) {
    if (exists($other->{'_value'})) {
      return 0 unless ($self->{'_value'} eq $other->{'_value'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_value'}));
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::MinInclusive;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of MinInclusive class

Rinchi::XMLSchema::MinInclusive is used for creating XML Schema MinInclusive objects.

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::MinInclusive->new();

Create a new Rinchi::XMLSchema::MinInclusive object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::MinInclusive::fixed

=item $value = $Object->fixed([$new_value]);

Set or get value of the 'fixed' attribute.

=cut

sub fixed() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^true|false$/) {
      $self->{'_fixed'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting value \'true | false\'.'
    }
  }
  return $self->{'_fixed'};
}

#===============================================================================
# Rinchi::XMLSchema::MinInclusive::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::MinInclusive::value

=item $value = $Object->value([$new_value]);

Set or get value of the 'value' attribute.

=cut

sub value() {
  my $self = shift;
  if (@_) {
    $self->{'_value'} = shift;
  }
  return $self->{'_value'};
}

#===============================================================================
# Rinchi::XMLSchema::MinInclusive::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_fixed'})) {
    if (exists($other->{'_fixed'})) {
      return 0 unless ($self->{'_fixed'} eq $other->{'_fixed'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_fixed'}));
  }

  if (exists($self->{'_value'})) {
    if (exists($other->{'_value'})) {
      return 0 unless ($self->{'_value'} eq $other->{'_value'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_value'}));
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::MinLength;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of MinLength class

Rinchi::XMLSchema::MinLength is used for creating XML Schema MinLength objects.

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::MinLength->new();

Create a new Rinchi::XMLSchema::MinLength object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::MinLength::fixed

=item $value = $Object->fixed([$new_value]);

Set or get value of the 'fixed' attribute.

=cut

sub fixed() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^true|false$/) {
      $self->{'_fixed'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting value \'true | false\'.'
    }
  }
  return $self->{'_fixed'};
}

#===============================================================================
# Rinchi::XMLSchema::MinLength::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::MinLength::value

=item $value = $Object->value([$new_value]);

Set or get value of the 'value' attribute.

=cut

sub value() {
  my $self = shift;
  if (@_) {
    $self->{'_value'} = shift;
  }
  return $self->{'_value'};
}

#===============================================================================
# Rinchi::XMLSchema::MinLength::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_fixed'})) {
    if (exists($other->{'_fixed'})) {
      return 0 unless ($self->{'_fixed'} eq $other->{'_fixed'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_fixed'}));
  }

  if (exists($self->{'_value'})) {
    if (exists($other->{'_value'})) {
      return 0 unless ($self->{'_value'} eq $other->{'_value'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_value'}));
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::Notation;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Notation class

Rinchi::XMLSchema::Notation is used for creating XML Schema Notation objects.

 id = ID
 name = NCName
 public = token
 system = anyURI
 {any attributes with non-schema namespace ...}>
 Content: (annotation?)

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::Notation->new();

Create a new Rinchi::XMLSchema::Notation object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::Notation::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::Notation::name

=item $value = $Object->name([$new_value]);

Set or get value of the 'name' attribute.

=cut

sub name() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-0-9A-Za-z_.:]+$/) {
      $self->{'_name'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting NMTOKEN.'
    }
  }
  return $self->{'_name'};
}

#===============================================================================
# Rinchi::XMLSchema::Notation::public

=item $value = $Object->public([$new_value]);

Set or get value of the 'public' attribute.

=cut

sub public() {
  my $self = shift;
  if (@_) {
    $self->{'_public'} = shift;
  }
  return $self->{'_public'};
}

#===============================================================================
# Rinchi::XMLSchema::Notation::system

=item $value = $Object->system([$new_value]);

Set or get value of the 'system' attribute.

=cut

sub system() {
  my $self = shift;
  if (@_) {
    $self->{'_system'} = shift;
  }
  return $self->{'_system'};
}

#===============================================================================
# Rinchi::XMLSchema::Notation::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_name'})) {
    if (exists($other->{'_name'})) {
      return 0 unless ($self->{'_name'} eq $other->{'_name'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_name'}));
  }

  if (exists($self->{'_public'})) {
    if (exists($other->{'_public'})) {
      return 0 unless ($self->{'_public'} eq $other->{'_public'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_public'}));
  }

  if (exists($self->{'_system'})) {
    if (exists($other->{'_system'})) {
      return 0 unless ($self->{'_system'} eq $other->{'_system'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_system'}));
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::Pattern;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Pattern class

Rinchi::XMLSchema::Pattern is used for creating XML Schema Pattern objects.

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::Pattern->new();

Create a new Rinchi::XMLSchema::Pattern object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::Pattern::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::Pattern::value

=item $value = $Object->value([$new_value]);

Set or get value of the 'value' attribute.

=cut

sub value() {
  my $self = shift;
  if (@_) {
    $self->{'_value'} = shift;
  }
  return $self->{'_value'};
}

#===============================================================================
# Rinchi::XMLSchema::Pattern::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_value'})) {
    if (exists($other->{'_value'})) {
      return 0 unless ($self->{'_value'} eq $other->{'_value'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_value'}));
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::Redefine;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Redefine class

Rinchi::XMLSchema::Redefine is used for creating XML Schema Redefine objects.

 id = ID
 schemaLocation = anyURI
 {any attributes with non-schema namespace . . .}>
 Content: (annotation | (simpleType | complexType | group | attributeGroup))*

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::Redefine->new();

Create a new Rinchi::XMLSchema::Redefine object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::Redefine::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::Redefine::schemaLocation

=item $value = $Object->schemaLocation([$new_value]);

Set or get value of the 'schemaLocation' attribute.

=cut

sub schemaLocation() {
  my $self = shift;
  if (@_) {
    $self->{'_schemaLocation'} = shift;
  }
  return $self->{'_schemaLocation'};
}

#===============================================================================
# Rinchi::XMLSchema::Redefine::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_schemaLocation'})) {
    if (exists($other->{'_schemaLocation'})) {
      return 0 unless ($self->{'_schemaLocation'} eq $other->{'_schemaLocation'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_schemaLocation'}));
  }

  my @self_cont = @{$self->{'_content_'}};
  my @other_cont = @{$other->{'_content_'}};
  shift @self_cont while(@self_cont and ref($self_cont[0]) eq 'Rinchi::XMLSchema::Annotation');
  shift @other_cont while(@other_cont and ref($other_cont[0]) eq 'Rinchi::XMLSchema::Annotation');

  if (@self_cont) {
    if (@other_cont) {
      while (@self_cont and @other_cont) {
        my $sc = shift @self_cont;
        my $oc = shift @other_cont;
        return 0 unless($sc->sameAs($oc));
      }
      return (0) if (@self_cont or @other_cont);
    } else {
      return 0;
    }  
  } else {
    return 0 if (@other_cont);
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::Restriction;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Restriction class

Rinchi::XMLSchema::Restriction is used for creating XML Schema Restriction objects.

 base = QName
 id = ID
 {any attributes with non-schema namespace ...}>
 Content: (annotation?, (simpleType?, (minExclusive | minInclusive | maxExclusive | maxInclusive | totalDigits | fractionDigits | length | minLength | maxLength | enumeration | whiteSpace | pattern)*))

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::Restriction->new();

Create a new Rinchi::XMLSchema::Restriction object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::Restriction::base

=item $value = $Object->base([$new_value]);

Set or get value of the 'base' attribute.

=cut

sub base() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-0-9A-Za-z_.:]+$/) {
      $self->{'_base'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting NMTOKEN.'
    }
  }
  return $self->{'_base'};
}

#===============================================================================
# Rinchi::XMLSchema::Restriction::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::Restriction::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_base'})) {
    if (exists($other->{'_base'})) {
      return 0 unless ($self->{'_base'} eq $other->{'_base'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_base'}));
  }

  my @self_cont = @{$self->{'_content_'}};
  my @other_cont = @{$other->{'_content_'}};
  shift @self_cont while(@self_cont and ref($self_cont[0]) eq 'Rinchi::XMLSchema::Annotation');
  shift @other_cont while(@other_cont and ref($other_cont[0]) eq 'Rinchi::XMLSchema::Annotation');

  if (@self_cont) {
    if (@other_cont) {
      while (@self_cont and @other_cont) {
        my $sc = shift @self_cont;
        my $oc = shift @other_cont;
        return 0 unless($sc->sameAs($oc));
      }
      return (0) if (@self_cont or @other_cont);
    } else {
      return 0;
    }  
  } else {
    return 0 if (@other_cont);
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::Schema;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Schema class

Rinchi::XMLSchema::Schema is used for creating XML Schema Schema objects.

 attributeFormDefault = (qualified | unqualified) : unqualified
 blockDefault = (#all | List of (extension | restriction | substitution))  : ''
 elementFormDefault = (qualified | unqualified) : unqualified
 finalDefault = (#all | List of (extension | restriction | list | union))  : ''
 id = ID
 targetNamespace = anyURI
 version = token
 xml:lang = language
 {any attributes with non-schema namespace . . .}>
 Content: ((include | import | redefine | annotation)*, (((simpleType | complexType | group | attributeGroup) | element | attribute | notation), annotation*)*)

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::Schema->new();

Create a new Rinchi::XMLSchema::Schema object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  
  $self->{'_content_'} = [];
  $self->{'_elements'} = undef;
  $self->{'_attributes'} = undef;
  $self->{'_types'} = undef;
  $self->{'_groups'} = undef;
  $self->{'_attributeGroups'} = undef;
  $self->{'_notations'} = undef;
  $self->{'_identityConstraints'} = undef;
  
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::Schema::attributeFormDefault

=item $value = $Object->attributeFormDefault([$new_value]);

Set or get value of the 'attributeFormDefault' attribute.

=cut

sub attributeFormDefault() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^qualified|unqualified$/) {
      $self->{'_attributeFormDefault'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting value \'qualified | unqualified\'.';
    }
  }
  return $self->{'_attributeFormDefault'};
}

#===============================================================================
# Rinchi::XMLSchema::Schema::blockDefault

=item $value = $Object->blockDefault([$new_value]);

Set or get value of the 'blockDefault' attribute.

=cut

sub blockDefault() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^#all$|^(extension|restriction|substitution)(\s+(extension|restriction|substitution))*$/) {
      $self->{'_blockDefault'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting value \'#all\' or a list of \'extension | restriction | substitution\'.';
    }
  }
  return $self->{'_blockDefault'};
}

#===============================================================================
# Rinchi::XMLSchema::Schema::elementFormDefault

=item $value = $Object->elementFormDefault([$new_value]);

Set or get value of the 'elementFormDefault' attribute.

=cut

sub elementFormDefault() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^qualified|unqualified$/) {
      $self->{'_elementFormDefault'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting value \'qualified | unqualified\'.'
    }
  }
  return $self->{'_elementFormDefault'};
}

#===============================================================================
# Rinchi::XMLSchema::Schema::finalDefault

=item $value = $Object->finalDefault([$new_value]);

Set or get value of the 'finalDefault' attribute.

=cut

sub finalDefault() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^#all$|^(extension|restriction)(\s+(extension|restriction))*$/) {
      $self->{'_finalDefault'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting value \'#all\' or a list of \'extension | restriction\'.'
    }
  }
  return $self->{'_finalDefault'};
}

#===============================================================================
# Rinchi::XMLSchema::Schema::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::Schema::targetNamespace

=item $value = $Object->targetNamespace([$new_value]);

Set or get value of the 'targetNamespace' attribute.

=cut

sub targetNamespace() {
  my $self = shift;
  if (@_) {
    $self->{'_targetNamespace'} = shift;
  }
  return $self->{'_targetNamespace'};
}

#===============================================================================
# Rinchi::XMLSchema::Schema::version

=item $value = $Object->version([$new_value]);

Set or get value of the 'version' attribute.

=cut

sub version() {
  my $self = shift;
  if (@_) {
    $self->{'_version'} = shift;
  }
  return $self->{'_version'};
}

#===============================================================================
# Rinchi::XMLSchema::Schema::xml:lang

=item $value = $Object->xml_lang([$new_value]);

Set or get value of the 'xml:lang' attribute.

=cut

sub xml_lang() {
  my $self = shift;
  if (@_) {
    $self->{'_xml:lang'} = shift;
  }
  return $self->{'_xml:lang'};
}

#===============================================================================
# Rinchi::XMLSchema::Schema::xmlns

=item $value = $Object->xmlns([$new_value]);

Set or get value of the 'xmlns' attribute.

=cut

sub xmlns() {
  my $self = shift;
  if (@_) {
    $self->{'_xmlns'} = shift;
  }
  return $self->{'_xmlns'};
}

#===============================================================================
# Rinchi::XMLSchema::Schema::xmlns:xs

=item $value = $Object->xmlns_xs([$new_value]);

Set or get value of the 'xmlns:xs' attribute.

=cut

sub xmlns_xs() {
  my $self = shift;
  if (@_) {
    $self->{'_xmlns:xs'} = shift;
  }
  return $self->{'_xmlns:xs'};
}

#===============================================================================
sub _classify_content() {
  my $self = shift;
  
  foreach my $c (@{$self->{'_content_'}}) {
    my $cref = ref($c);
    if ($cref eq 'Rinchi::XMLSchema::Element') {
      if (exists($c->{'_ref'})) {
        delete $c->{'_ref'};
        carp "The attribute 'ref' is prohibited in a top-level element.";
      }
      if (exists($c->{'_form'})) {
        delete $c->{'_form'};
        carp "The attribute 'form' is prohibited in a top-level element.";
      }
      if (exists($c->{'_minOccurs'})) {
        delete $c->{'_minOccurs'};
        carp "The attribute 'minOccurs' is prohibited in a top-level element.";
      }
      if (exists($c->{'_maxOccurs'})) {
        delete $c->{'_maxOccurs'};
        carp "The attribute 'maxOccurs' is prohibited in a top-level element.";
      }
      unless (exists($c->{'_name'})) {
        carp "The attribute 'name' is required in a top-level element.";
      }
      $self->{'_elements'}{$c->name()} = $c;
    }
    elsif ($cref eq 'Rinchi::XMLSchema::Attribute') {
      $self->{'_attributes'}{$c->name()} = $c;
    }
    elsif ($cref eq 'Rinchi::XMLSchema::ComplexType') {
      $self->{'_types'}{$c->name()} = $c;
    }
    elsif ($cref eq 'Rinchi::XMLSchema::SimpleType') {
      $self->{'_types'}{$c->name()} = $c;
    }
    elsif ($cref eq 'Rinchi::XMLSchema::Group') {
      $self->{'_groups'}{$c->name()} = $c;
    }
    elsif ($cref eq 'Rinchi::XMLSchema::AttributeGroup') {
      $self->{'_attributeGroups'}{$c->name()} = $c;
    }
    elsif ($cref eq 'Rinchi::XMLSchema::Notation') {
      $self->{'_Notations'}{$c->name()} = $c;
    }
  }
}

#===============================================================================
# Rinchi::XMLSchema::Schema::elements

=item $value = $Object->elements();

Get the top-level element objects.

=cut

sub elements() {
  my $self = shift;
  unless (defined($self->{'_elements'})) {
    $self->_classify_content();
  }
  return $self->{'_elements'};
}

#===============================================================================
# Rinchi::XMLSchema::Schema::attributes

=item $value = $Object->attributes();

Get the top-level attribute objects.

=cut

sub attributes() {
  my $self = shift;
  unless (defined($self->{'_attributes'})) {
    $self->_classify_content();
  }
  return $self->{'_attributes'};
}

#===============================================================================
# Rinchi::XMLSchema::Schema::types

=item $value = $Object->types();

Get the top-level type objects.

=cut

sub types() {
  my $self = shift;
  unless (defined($self->{'_types'})) {
    $self->_classify_content();
  }
  return $self->{'_types'};
}

#===============================================================================
# Rinchi::XMLSchema::Schema::groups

=item $value = $Object->groups();

Get the top-level groups objects.

=cut

sub groups() {
  my $self = shift;
  unless (defined($self->{'_groups'})) {
    $self->_classify_content();
  }
  return $self->{'_groups'};
}

#===============================================================================
# Rinchi::XMLSchema::Schema::attributeGroups

=item $value = $Object->attributeGroups();

Get the top-level attributeGroups objects.

=cut

sub attributeGroups() {
  my $self = shift;
  unless (defined($self->{'_attributeGroups'})) {
    $self->_classify_content();
  }
  return $self->{'_attributeGroups'};
}

#===============================================================================
# Rinchi::XMLSchema::Schema::notations

=item $value = $Object->notations();

Get the top-level notation objects.

=cut

sub notations() {
  my $self = shift;
  unless (defined($self->{'_notations'})) {
    $self->_classify_content();
  }
  return $self->{'_notations'};
}

#===============================================================================
# Rinchi::XMLSchema::Schema::identityConstraints

=item $value = $Object->identityConstraints();

Get the top-level identityConstraint objects.

=cut

sub identityConstraints() {
  my $self = shift;
  unless (defined($self->{'_identityConstraints'})) {
    $self->_find_identityConstraints($self);
  }
  return $self->{'_identityConstraints'};
}

#===============================================================================
# Rinchi::XMLSchema::Schema::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_attributeFormDefault'})) {
    if (exists($other->{'_attributeFormDefault'})) {
      return 0 unless ($self->{'_attributeFormDefault'} eq $other->{'_attributeFormDefault'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_attributeFormDefault'}));
  }

  if (exists($self->{'_blockDefault'})) {
    if (exists($other->{'_blockDefault'})) {
      return 0 unless ($self->{'_blockDefault'} eq $other->{'_blockDefault'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_blockDefault'}));
  }

  if (exists($self->{'_elementFormDefault'})) {
    if (exists($other->{'_elementFormDefault'})) {
      return 0 unless ($self->{'_elementFormDefault'} eq $other->{'_elementFormDefault'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_elementFormDefault'}));
  }

  if (exists($self->{'_finalDefault'})) {
    if (exists($other->{'_finalDefault'})) {
      return 0 unless ($self->{'_finalDefault'} eq $other->{'_finalDefault'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_finalDefault'}));
  }

  if (exists($self->{'_targetNamespace'})) {
    if (exists($other->{'_targetNamespace'})) {
      return 0 unless ($self->{'_targetNamespace'} eq $other->{'_targetNamespace'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_targetNamespace'}));
  }

  if (exists($self->{'_version'})) {
    if (exists($other->{'_version'})) {
      return 0 unless ($self->{'_version'} eq $other->{'_version'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_version'}));
  }

  if (exists($self->{'_xml:lang'})) {
    if (exists($other->{'_xml:lang'})) {
      return 0 unless ($self->{'_xml:lang'} eq $other->{'_xml:lang'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_xml:lang'}));
  }

  if (exists($self->{'_xmlns'})) {
    if (exists($other->{'_xmlns'})) {
      return 0 unless ($self->{'_xmlns'} eq $other->{'_xmlns'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_xmlns'}));
  }

  if (exists($self->{'_xmlns:xs'})) {
    if (exists($other->{'_xmlns:xs'})) {
      return 0 unless ($self->{'_xmlns:xs'} eq $other->{'_xmlns:xs'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_xmlns:xs'}));
  }

  my @self_cont = @{$self->{'_content_'}};
  my @other_cont = @{$other->{'_content_'}};
  shift @self_cont while(@self_cont and ref($self_cont[0]) eq 'Rinchi::XMLSchema::Annotation');
  shift @other_cont while(@other_cont and ref($other_cont[0]) eq 'Rinchi::XMLSchema::Annotation');

  if (@self_cont) {
    if (@other_cont) {
      while (@self_cont and @other_cont) {
        my $sc = shift @self_cont;
        my $oc = shift @other_cont;
        return 0 unless($sc->sameAs($oc));
      }
      return (0) if (@self_cont or @other_cont);
    } else {
      return 0;
    }  
  } else {
    return 0 if (@other_cont);
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::Selector;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Selector class

Rinchi::XMLSchema::Selector is used for creating XML Schema Selector objects.

 id = ID
 xpath = a subset of XPath expression, see below
 {any attributes with non-schema namespace ...}>
 Content: (annotation?)

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::Selector->new();

Create a new Rinchi::XMLSchema::Selector object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::Selector::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::Selector::xpath

=item $value = $Object->xpath([$new_value]);

Set or get value of the 'xpath' attribute.

=cut

sub xpath() {
  my $self = shift;
  if (@_) {
    $self->{'_xpath'} = shift;
  }
  return $self->{'_xpath'};
}

#===============================================================================
# Rinchi::XMLSchema::Selector::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_xpath'})) {
    if (exists($other->{'_xpath'})) {
      return 0 unless ($self->{'_xpath'} eq $other->{'_xpath'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_xpath'}));
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::Sequence;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Sequence class

Rinchi::XMLSchema::Sequence is used for creating XML Schema Sequence objects.

 id = ID
 maxOccurs = (nonNegativeInteger | unbounded)  : 1
 minOccurs = nonNegativeInteger : 1
 {any attributes with non-schema namespace ...}>
 Content: (annotation?, (element | group | choice | sequence | any)*)

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::Sequence->new();

Create a new Rinchi::XMLSchema::Sequence object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::Sequence::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::Sequence::maxOccurs

=item $value = $Object->maxOccurs([$new_value]);

Set or get value of the 'maxOccurs' attribute.

=cut

sub maxOccurs() {
  my $self = shift;
  if (@_) {
    $self->{'_maxOccurs'} = shift;
  }
  return $self->{'_maxOccurs'};
}

#===============================================================================
# Rinchi::XMLSchema::Sequence::minOccurs

=item $value = $Object->minOccurs([$new_value]);

Set or get value of the 'minOccurs' attribute.

=cut

sub minOccurs() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-0-9A-Za-z_.:]+$/) {
      $self->{'_minOccurs'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting NMTOKEN.'
    }
  }
  return $self->{'_minOccurs'};
}

#===============================================================================
# Rinchi::XMLSchema::Sequence::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_maxOccurs'})) {
    if (exists($other->{'_maxOccurs'})) {
      return 0 unless ($self->{'_maxOccurs'} eq $other->{'_maxOccurs'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_maxOccurs'}));
  }

  if (exists($self->{'_minOccurs'})) {
    if (exists($other->{'_minOccurs'})) {
      return 0 unless ($self->{'_minOccurs'} eq $other->{'_minOccurs'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_minOccurs'}));
  }

  my @self_cont = @{$self->{'_content_'}};
  my @other_cont = @{$other->{'_content_'}};
  shift @self_cont while(@self_cont and ref($self_cont[0]) eq 'Rinchi::XMLSchema::Annotation');
  shift @other_cont while(@other_cont and ref($other_cont[0]) eq 'Rinchi::XMLSchema::Annotation');

  if (@self_cont) {
    if (@other_cont) {
      while (@self_cont and @other_cont) {
        my $sc = shift @self_cont;
        my $oc = shift @other_cont;
        return 0 unless($sc->sameAs($oc));
      }
      return (0) if (@self_cont or @other_cont);
    } else {
      return 0;
    }  
  } else {
    return 0 if (@other_cont);
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::SimpleContent;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of SimpleContent class

Rinchi::XMLSchema::SimpleContent is used for creating XML Schema SimpleContent objects.

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::SimpleContent->new();

Create a new Rinchi::XMLSchema::SimpleContent object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::SimpleContent::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::SimpleContent::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  my @self_cont = @{$self->{'_content_'}};
  my @other_cont = @{$other->{'_content_'}};
  shift @self_cont while(@self_cont and ref($self_cont[0]) eq 'Rinchi::XMLSchema::Annotation');
  shift @other_cont while(@other_cont and ref($other_cont[0]) eq 'Rinchi::XMLSchema::Annotation');

  if (@self_cont) {
    if (@other_cont) {
      while (@self_cont and @other_cont) {
        my $sc = shift @self_cont;
        my $oc = shift @other_cont;
        return 0 unless($sc->sameAs($oc));
      }
      return (0) if (@self_cont or @other_cont);
    } else {
      return 0;
    }  
  } else {
    return 0 if (@other_cont);
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::SimpleType;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of SimpleType class

Rinchi::XMLSchema::SimpleType is used for creating XML Schema SimpleType objects.

 final = (#all | List of (list | union | restriction))
 id = ID
 name = NCName
 {any attributes with non-schema namespace ...}>
 Content: (annotation?, (restriction | list | union))

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::SimpleType->new();

Create a new Rinchi::XMLSchema::SimpleType object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::SimpleType::final

=item $value = $Object->final([$new_value]);

Set or get value of the 'final' attribute.

=cut

sub final() {
  my $self = shift;
  if (@_) {
    $self->{'_final'} = shift;
  }
  return $self->{'_final'};
}

#===============================================================================
# Rinchi::XMLSchema::SimpleType::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::SimpleType::name

=item $value = $Object->name([$new_value]);

Set or get value of the 'name' attribute.

=cut

sub name() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-0-9A-Za-z_.:]+$/) {
      $self->{'_name'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting NMTOKEN.'
    }
  }
  return $self->{'_name'};
}

#===============================================================================
# Rinchi::XMLSchema::SimpleType::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;
  
  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_final'})) {
    if (exists($other->{'_final'})) {
      return 0 unless ($self->{'_final'} eq $other->{'_final'});
    } else {
      return 0;
    }  
  } else {
    return 0 if (exists($other->{'_final'}));
  }

  if (exists($self->{'_name'})) {
    if (exists($other->{'_name'})) {
      return 0 unless ($self->{'_name'} eq $other->{'_name'});
    } else {
      return 0;
    }  
  } else {
    return 0 if (exists($other->{'_name'}));
  }

  my @self_cont = @{$self->{'_content_'}};
  my @other_cont = @{$other->{'_content_'}};
  shift @self_cont while(@self_cont and ref($self_cont[0]) eq 'Rinchi::XMLSchema::Annotation');
  shift @other_cont while(@other_cont and ref($other_cont[0]) eq 'Rinchi::XMLSchema::Annotation');

  if (@self_cont) {
    if (@other_cont) {
      while (@self_cont and @other_cont) {
        my $sc = shift @self_cont;
        my $oc = shift @other_cont;
        return 0 unless($sc->sameAs($oc));
      }
      return (0) if (@self_cont or @other_cont);
    } else {
      return 0;
    }  
  } else {
    return 0 if (@other_cont);
  }
  
  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::TotalDigits;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of TotalDigits class

Rinchi::XMLSchema::TotalDigits is used for creating XML Schema TotalDigits objects.

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::TotalDigits->new();

Create a new Rinchi::XMLSchema::TotalDigits object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::TotalDigits::fixed

=item $value = $Object->fixed([$new_value]);

Set or get value of the 'fixed' attribute.

=cut

sub fixed() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^true|false$/) {
      $self->{'_fixed'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting value \'true | false\'.'
    }
  }
  return $self->{'_fixed'};
}

#===============================================================================
# Rinchi::XMLSchema::TotalDigits::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::TotalDigits::value

=item $value = $Object->value([$new_value]);

Set or get value of the 'value' attribute.

=cut

sub value() {
  my $self = shift;
  if (@_) {
    $self->{'_value'} = shift;
  }
  return $self->{'_value'};
}

#===============================================================================
# Rinchi::XMLSchema::TotalDigits::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_fixed'})) {
    if (exists($other->{'_fixed'})) {
      return 0 unless ($self->{'_fixed'} eq $other->{'_fixed'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_fixed'}));
  }

  if (exists($self->{'_value'})) {
    if (exists($other->{'_value'})) {
      return 0 unless ($self->{'_value'} eq $other->{'_value'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_value'}));
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::Union;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Union class

Rinchi::XMLSchema::Union is used for creating XML Schema Union objects.

 id = ID
 memberTypes = List of QName
 {any attributes with non-schema namespace ...}>
 Content: (annotation?, simpleType*)

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::Union->new();

Create a new Rinchi::XMLSchema::Union object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::Union::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::Union::memberTypes

=item $value = $Object->memberTypes([$new_value]);

Set or get value of the 'memberTypes' attribute.

=cut

sub memberTypes() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-0-9A-Za-z_.:]+(\s+[-0-9A-Za-z_.:]+)*$/) {
      $self->{'_memberTypes'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting NMTOKENS.'
    }
  }
  return $self->{'_memberTypes'};
}

#===============================================================================
# Rinchi::XMLSchema::Union::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_memberTypes'})) {
    if (exists($other->{'_memberTypes'})) {
      return 0 unless ($self->{'_memberTypes'} eq $other->{'_memberTypes'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_memberTypes'}));
  }

  my @self_cont = @{$self->{'_content_'}};
  my @other_cont = @{$other->{'_content_'}};
  shift @self_cont while(@self_cont and ref($self_cont[0]) eq 'Rinchi::XMLSchema::Annotation');
  shift @other_cont while(@other_cont and ref($other_cont[0]) eq 'Rinchi::XMLSchema::Annotation');

  if (@self_cont) {
    if (@other_cont) {
      while (@self_cont and @other_cont) {
        my $sc = shift @self_cont;
        my $oc = shift @other_cont;
        return 0 unless($sc->sameAs($oc));
      }
      return (0) if (@self_cont or @other_cont);
    } else {
      return 0;
    }  
  } else {
    return 0 if (@other_cont);
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::Unique;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of Unique class

Rinchi::XMLSchema::Unique is used for creating XML Schema Unique objects.

 id = ID
 name = NCName
 {any attributes with non-schema namespace ...}>
 Content: (annotation?, (selector, field+))

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::Unique->new();

Create a new Rinchi::XMLSchema::Unique object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::Unique::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::Unique::name

=item $value = $Object->name([$new_value]);

Set or get value of the 'name' attribute.

=cut

sub name() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[-0-9A-Za-z_.:]+$/) {
      $self->{'_name'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting NMTOKEN.'
    }
  }
  return $self->{'_name'};
}

#===============================================================================
# Rinchi::XMLSchema::Unique::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_name'})) {
    if (exists($other->{'_name'})) {
      return 0 unless ($self->{'_name'} eq $other->{'_name'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_name'}));
  }

  my @self_cont = @{$self->{'_content_'}};
  my @other_cont = @{$other->{'_content_'}};
  shift @self_cont while(@self_cont and ref($self_cont[0]) eq 'Rinchi::XMLSchema::Annotation');
  shift @other_cont while(@other_cont and ref($other_cont[0]) eq 'Rinchi::XMLSchema::Annotation');

  if (@self_cont) {
    if (@other_cont) {
      while (@self_cont and @other_cont) {
        my $sc = shift @self_cont;
        my $oc = shift @other_cont;
        return 0 unless($sc->sameAs($oc));
      }
      return (0) if (@self_cont or @other_cont);
    } else {
      return 0;
    }  
  } else {
    return 0 if (@other_cont);
  }

  return 1;
}

#===============================================================================

package Rinchi::XMLSchema::WhiteSpace;

use Carp;

our @ISA = qw(Rinchi::XMLSchema);

our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 DESCRIPTION of WhiteSpace class

Rinchi::XMLSchema::WhiteSpace is used for creating XML Schema WhiteSpace objects.

=cut

#===============================================================================

=item $Object = Rinchi::XMLSchema::WhiteSpace->new();

Create a new Rinchi::XMLSchema::WhiteSpace object.

=cut

sub new() {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  $self->{'_content_'} = [];
  return $self;
}

#===============================================================================
# Rinchi::XMLSchema::WhiteSpace::fixed

=item $value = $Object->fixed([$new_value]);

Set or get value of the 'fixed' attribute.

=cut

sub fixed() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^true|false$/) {
      $self->{'_fixed'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting value \'true | false\'.'
    }
  }
  return $self->{'_fixed'};
}

#===============================================================================
# Rinchi::XMLSchema::WhiteSpace::id

=item $value = $Object->id([$new_value]);

Set or get value of the 'id' attribute.

=cut

sub id() {
  my $self = shift;
  if (@_) {
    if ($_[0] =~ /^[A-Za-z_][-0-9A-Za-z_.:]*$/) {
      $self->{'_id'} = shift;
    } else {
      carp 'Found value \'' . $_[0] . '\', expecting ID.'
    }
  }
  return $self->{'_id'};
}

#===============================================================================
# Rinchi::XMLSchema::WhiteSpace::value

=item $value = $Object->value([$new_value]);

Set or get value of the 'value' attribute.

=cut

sub value() {
  my $self = shift;
  if (@_) {
    $self->{'_value'} = shift;
  }
  return $self->{'_value'};
}

#===============================================================================
# Rinchi::XMLSchema::WhiteSpace::sameAs

=item $value = $Object->sameAs($other);

Compares self to other returning 1 if they are the same, 0 otherwise;

=cut

sub sameAs() {
  my $self = shift @_;
  my $other = shift @_;

  return 0 unless (ref($other) eq ref($self));

  if (exists($self->{'_fixed'})) {
    if (exists($other->{'_fixed'})) {
      return 0 unless ($self->{'_fixed'} eq $other->{'_fixed'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_fixed'}));
  }

  if (exists($self->{'_value'})) {
    if (exists($other->{'_value'})) {
      return 0 unless ($self->{'_value'} eq $other->{'_value'});
    } else {
      return 0;
    }
  } else {
    return 0 if (exists($other->{'_value'}));
  }

  my @self_cont = @{$self->{'_content_'}};
  my @other_cont = @{$other->{'_content_'}};
  shift @self_cont while(@self_cont and ref($self_cont[0]) eq 'Rinchi::XMLSchema::Annotation');
  shift @other_cont while(@other_cont and ref($other_cont[0]) eq 'Rinchi::XMLSchema::Annotation');

  if (@self_cont) {
    if (@other_cont) {
      while (@self_cont and @other_cont) {
        my $sc = shift @self_cont;
        my $oc = shift @other_cont;
        return 0 unless($sc->sameAs($oc));
      }
      return (0) if (@self_cont or @other_cont);
    } else {
      return 0;
    }  
  } else {
    return 0 if (@other_cont);
  }

  return 1;
}

#===============================================================================

1

__END__

=head1 AUTHOR

Brian M. Ames, E<lt>bmames.netE<gt>

=head1 SEE ALSO

L<XML::Parser>.

=head1 COPYRIGHT and LICENSE

Copyright 2008 Brian M. Ames. 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
