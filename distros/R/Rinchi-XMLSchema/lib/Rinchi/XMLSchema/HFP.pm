package Rinchi::XMLSchema::HFP;

use 5.006;
use strict;
use FileHandle;
use strict;
use Carp;
use XML::Parser;
use Class::ISA;

our @ISA = qw();

our @EXPORT = qw();
our @EXPORT_OK = qw();

our $VERSION = 0.01;

=head1 NAME

Rinchi::XMLSchema::HFP - Module for creating XML Schema objects.

=head1 SYNOPSIS

  use Rinchi::XMLSchema;
  use Rinchi::XMLSchema::HFP;
  my $nsdef = Rinchi::HFP->namespace_def();
  $nsdef->{'Prefix'} = 'hfp';
  Rinchi::XMLSchema->add_namespace($nsdef);
  my $Document = Rinchi::XMLSchema->parsefile('datatypes.xsd');
  $document = Rinchi::XMLSchema->parse($file);

=head1 DESCRIPTION

  Description.

=head2 EXPORT

None by default.

=cut

#===============================================================================

sub handle_start_hasFacet() {
  my ($expat,$tag,%attrs) = @_;
  my $HasFacet = Rinchi::XMLSchema::HFP::HasFacet->new();

  if (exists($attrs{'name'})) {
    $HasFacet->name($attrs{'name'});
  }
  return $HasFacet;
}

#-------------------------------------------------------------------------------

sub handle_end_hasFacet() {
  my ($expat,$tag,$HasFacet) = @_;
}

#===============================================================================

sub handle_start_hasProperty() {
  my ($expat,$tag,%attrs) = @_;
  my $HasProperty = Rinchi::XMLSchema::HFP::HasProperty->new();

  if (exists($attrs{'name'})) {
    $HasProperty->name($attrs{'name'});
  }
  if (exists($attrs{'value'})) {
    $HasProperty->value($attrs{'value'});
  }

  return $HasProperty;
}

#-------------------------------------------------------------------------------

sub handle_end_hasProperty() {
  my ($expat,$tag,$HasProperty) = @_;
}

#===============================================================================

my %sax_start_handlers = (
  'hasFacet'         => \&handle_start_hasFacet,
  'hasProperty'      => \&handle_start_hasProperty,
);

my %sax_end_handlers = (
  'hasFacet'         => \&handle_end_hasFacet,
  'hasProperty'      => \&handle_end_hasProperty,
);

my $schema_namespace='http://www.w3.org/2001/XMLSchema-hasFacetAndProperty';

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

#===============================================================================

package Rinchi::XMLSchema::HFP::HasFacet;
use Carp;

sub new() {
  my $class = shift;
  
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  return $self;
}

#===============================================================================

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

package Rinchi::XMLSchema::HFP::HasProperty;
use Carp;

sub new() {
  my $class = shift;
  
  $class = ref($class) || $class;
  my $self = {};
  bless($self,$class);
  return $self;
}

#===============================================================================

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

sub value() {
  my $self = shift;
  if (@_) {
    $self->{'_value'} = shift;
  }
  return $self->{'_value'};
}


