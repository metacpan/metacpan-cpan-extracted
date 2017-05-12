# $Id: Ontology.pm 2015-02-28 erick.antezana $
#
# Module  : Ontology.pm
# Purpose : OBO ontologies handling.
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#
package OBO::Core::Ontology;

use OBO::Core::IDspace;
use OBO::Util::IDspaceSet;
use OBO::Util::SubsetDefMap;
use OBO::Util::SynonymTypeDefSet;
use OBO::Util::TermSet;
use OBO::Util::InstanceSet;
use OBO::Util::RelationshipTypeSet;

use Carp;
use strict;
use warnings;

use open qw(:std :utf8); # Make All I/O Default to UTF-8

our $VERSION = '1.45';

sub new {
	my $class  = shift;
	my $self   = {};
        
	$self->{ID}                             = undef;                          # not required, (1)
	$self->{NAME}                           = undef;                          # not required, (0..1)
	$self->{IMPORTS}                        = OBO::Util::Set->new();          # set (0..N)
	$self->{TREAT_XREFS_AS_EQUIVALENT}      = OBO::Util::Set->new();          # set (0..N)
	$self->{TREAT_XREFS_AS_IS_A}            = OBO::Util::Set->new();          # set (0..N)
	$self->{IDSPACES_SET}                   = OBO::Util::IDspaceSet->new();   # string (0..N)
	$self->{DEFAULT_RELATIONSHIP_ID_PREFIX} = undef;                          # string (0..1)
	$self->{DEFAULT_NAMESPACE}              = undef;                          # string (0..1)
	$self->{DATA_VERSION}                   = undef;                          # string (0..1)
	$self->{DATE}                           = undef;                          # (1) The current date in dd:MM:yyyy HH:mm format
	$self->{SAVED_BY}                       = undef;                          # string (0..1)
	$self->{REMARKS}                        = OBO::Util::Set->new();          # set (0..N)
	$self->{SUBSETDEF_MAP}                  = OBO::Util::SubsetDefMap->new(); # map of SubsetDef's (0..N); A subset is a view over an ontology
	$self->{SYNONYM_TYPE_DEF_SET}           = OBO::Util::SynonymTypeDefSet->new(); # set (0..N); A description of a user-defined synonym type

	$self->{TERMS}                          = {}; # map: term_id(string) vs. term(OBO::Core::Term)  (0..N)
	$self->{INSTANCES}                      = {}; # map: instance_id(string) vs. instance(OBO::Core::Instance)  (0..N)
	$self->{RELATIONSHIP_TYPES}             = {}; # map: relationship_type_id(string) vs. relationship_type(OBO::Core::RelationshipType) (0..N)
	$self->{RELATIONSHIPS}                  = {}; # (0..N)
	
	$self->{TERMS_SET}                      = OBO::Util::TermSet->new();      # Terms (0..n) # TODO Test this more deeply
	#$self->{INSTANCES_SET}                 = OBO::Util::TermSet->new();          # Instances (0..n) # TODO enable the instances_set
	#$self->{RELATIONSHIP_SET}              = OBO::Util::RelationshipSet->new();  # TODO Implement RELATIONSHIP_SET
		
	$self->{TARGET_RELATIONSHIPS}           = {}; # (0..N)
	$self->{SOURCE_RELATIONSHIPS}           = {}; # (0..N)
	$self->{TARGET_SOURCE_RELATIONSHIPS}    = {}; # (0..N)
        
	bless ($self, $class);
	return $self;
}

=head2 id

  Usage    - print $ontology->id() or $ontology->id($id)
  Returns  - the ID space of this ontology (string)
  Args     - the ID space of this ontology (string)
  Function - gets/sets the ID space of this ontology
  
=cut

sub id {
	my ($self, $id) = @_;
	if ($id) { $self->{ID} = $id }
	return $self->{ID};
}

=head2 name

  Usage    - print $ontology->name() or $ontology->name($name)
  Returns  - the name (string) of the ontology
  Args     - the name (string) of the ontology
  Function - gets/sets the name of the ontology
  
=cut

sub name {
	my ($self, $name) = @_;
    if ($name) { $self->{NAME} = $name }
    return $self->{NAME};
}

=head2 imports

  Usage    - $onto->imports() or $onto->imports($id1, $id2, $id3, ...)
  Returns  - a set (OBO::Util::Set) with the imported id ontologies
  Args     - the ontology id(s) (string) 
  Function - gets/sets the id(s) of the ontologies that are imported by this one
  
=cut

sub imports {
	my $self = shift;
	if (scalar(@_) > 1) {
		$self->{IMPORTS}->add_all(@_);
	} elsif (scalar(@_) == 1) {
		$self->{IMPORTS}->add($_[0]);
	}
	return $self->{IMPORTS};
}

=head2 treat_xrefs_as_equivalent

  Usage    - $onto->treat_xrefs_as_equivalent() or $onto->treat_xrefs_as_equivalent($xref1, $xref2, $xref3, ...)
  Returns  - a set (OBO::Util::Set) of ontology id spaces
  Args     - an ontology ID space(s) (string) 
  Function - gets/sets the id spaces(s) of the ontologies that their xrefs are treated as equivalent
  Remark   - Macro. Treats all xrefs coming from a particular ID-Space as being statements of exact equivalence.
  
=cut

sub treat_xrefs_as_equivalent {
	my $self = shift;
	if (scalar(@_) > 1) {
		$self->{TREAT_XREFS_AS_EQUIVALENT}->add_all(@_);
	} elsif (scalar(@_) == 1) {
		$self->{TREAT_XREFS_AS_EQUIVALENT}->add($_[0]);
	}
	return $self->{TREAT_XREFS_AS_EQUIVALENT};
}

=head2 treat_xrefs_as_is_a

  Usage    - $onto->treat_xrefs_as_is_a() or $onto->treat_xrefs_as_is_a($xref1, $xref2, $xref3, ...)
  Returns  - a set (OBO::Util::Set) of ontology id spaces
  Args     - an ontology ID space(s) (string) 
  Function - gets/sets the id spaces(s) of the ontologies that their xrefs are treated as equivalent
  Remark   - Treats all xrefs coming from a particular ID-Space as being is_a relationships.
  
=cut

sub treat_xrefs_as_is_a {
	my $self = shift;
	if (scalar(@_) > 1) {
		$self->{TREAT_XREFS_AS_IS_A}->add_all(@_);
	} elsif (scalar(@_) == 1) {
		$self->{TREAT_XREFS_AS_IS_A}->add($_[0]);
	}
	return $self->{TREAT_XREFS_AS_IS_A};
}

=head2 date

  Usage    - print $ontology->date()
  Returns  - the current date (in dd:MM:yyyy HH:mm format) of the ontology
  Args     - the current date (in dd:MM:yyyy HH:mm format) of the ontology
  Function - gets/sets the date of the ontology
  Remark   - for historic reasons, this is NOT a ISO 8601 date, as is the case for the creation-date field
  
=cut

sub date {
	my ($self, $d) = @_;
	if ($d) { $self->{DATE} = $d }
	return $self->{DATE};
}

=head2 default_relationship_id_prefix

  Usage    - print $ontology->default_relationship_id_prefix() or $ontology->default_relationship_id_prefix("OBO_REL")
  Returns  - the default relationship ID prefix (string) of this ontology
  Args     - the default relationship ID prefix (string) of this ontology
  Function - gets/sets the default relationship ID prefix of this ontology
  Remark   - Any relationship lacking an ID space will be prefixed with the value of this tag.

=cut

sub default_relationship_id_prefix {
	my ($self, $drip) = @_;
	if ($drip) { $self->{DEFAULT_RELATIONSHIP_ID_PREFIX} = $drip }
	return $self->{DEFAULT_RELATIONSHIP_ID_PREFIX};
}

=head2 default_namespace

  Usage    - print $ontology->default_namespace() or $ontology->default_namespace("cellcycle_ontology")
  Returns  - the default namespace (string) of this ontology
  Args     - the default namespace (string) of this ontology
  Function - gets/sets the default namespace of this ontology
  
=cut

sub default_namespace {
	my ($self, $dns) = @_;
	if ($dns) { $self->{DEFAULT_NAMESPACE} = $dns }
	return $self->{DEFAULT_NAMESPACE};
}

=head2 idspaces

  Usage    - $ontology->idspaces() or $ontology->idspaces($IDspace)
  Returns  - the id spaces, as a set (OBO::Util::IDspaceSet) of OBO::Core::IDspace's, of this ontology
  Args     - the id spaces, as a set (OBO::Util::IDspaceSet) of OBO::Core::IDspace's, of this ontology
  Function - gets/sets the idspaces of this ontology
  
=cut

sub idspaces {
	my $self = shift;
	if (scalar(@_) > 1) {
		$self->{IDSPACES_SET}->add_all(@_);
	} elsif (scalar(@_) == 1) {
		$self->{IDSPACES_SET}->add($_[0]);
	}
	return $self->{IDSPACES_SET};
} 

=head2 data_version

  Usage    - print $ontology->data_version()
  Returns  - the data version (string) of this ontology
  Args     - the data version (string) of this ontology
  Function - gets/sets the data version of this ontology
  
=cut

sub data_version {
	my ($self, $dv) = @_;
	if ($dv) { $self->{DATA_VERSION} = $dv }
	return $self->{DATA_VERSION};
}

=head2 saved_by

  Usage    - print $ontology->saved_by()
  Returns  - the username of the person (string) to last save this ontology
  Args     - the username of the person (string) to last save this ontology
  Function - gets/sets the username of the person to last save this ontology
  
=cut

sub saved_by {
	my ($self, $sb) = @_;
	if ($sb) { $self->{SAVED_BY} = $sb }
	return $self->{SAVED_BY};
}

=head2 remarks

  Usage    - print $ontology->remarks()
  Returns  - the remarks (OBO::Util::Set) of this ontology
  Args     - the remarks (OBO::Util::Set) of this ontology
  Function - gets/sets the remarks of this ontology
  
=cut

sub remarks {
	my $self = shift;
	if (scalar(@_) > 1) {
		$self->{REMARKS}->add_all(@_);
	} elsif (scalar(@_) == 1) {
		$self->{REMARKS}->add($_[0]);
	}
	return $self->{REMARKS};
}

=head2 subset_def_map

  Usage    - $onto->subset_def_map() or $onto->subset_def_map($subset_def_map)
  Returns  - a map (OBO::Util::SubsetDefMap) with the subset definition(s) used in this ontology. A subset is a view over an ontology
  Args     - a subset definitions map (OBO::Core::SubsetDefMap)
  Function - gets/sets the subset definition(s) of this ontology
        
=cut

sub subset_def_map {
	my $self = shift;
	$self->{SUBSETDEF_MAP}->put_all(@_);
	return $self->{SUBSETDEF_MAP};
}

=head2 synonym_type_def_set

  Usage    - $onto->synonym_type_def_set() or $onto->synonym_type_def_set($st1, $st2, $st3, ...)
  Returns  - a set (OBO::Util::SynonymTypeDefSet) with the synonym type definitions used in this ontology. A synonym type is a description of a user-defined synonym type 
  Args     - the synonym type definition(s) (OBO::Core::SynonymTypeDef) used in this ontology 
  Function - gets/sets the synonym type definitions (s) of this ontology
        
=cut

sub synonym_type_def_set {
	my $self = shift;
	if (scalar(@_) > 1) {
		$self->{SYNONYM_TYPE_DEF_SET}->add_all(@_);
	} elsif (scalar(@_) == 1) {
		$self->{SYNONYM_TYPE_DEF_SET}->add($_[0]);
	}
	return $self->{SYNONYM_TYPE_DEF_SET};
}

=head2 add_term

  Usage    - $ontology->add_term($term)
  Returns  - the just added term (OBO::Core::Term)
  Args     - the term (OBO::Core::Term) to be added. The ID of the term to be added must have already been defined.
  Function - adds a term to this ontology
  Remark   - adding a term to an ontology does not mean adding its instances
  
=cut

sub add_term {
	my ($self, $term) = @_;
	if ($term) {
		my $term_id = $term->id();
		if ($term_id) {
			$self->{TERMS}->{$term_id} = $term;
			$self->{TERMS_SET}->add($term);
			return $term;
		} else {
			croak 'A term to be added to this ontology must have an ID.';
		}
	} else {
    	croak 'Missing term.';
    }
}

=head2 add_instance

  Usage    - $ontology->add_instance($instance)
  Returns  - the just added instance (OBO::Core::Instance)
  Args     - the instance (OBO::Core::Instance) to be added. The ID of the instance to be added must have already been defined.
  Function - adds a instance to this ontology
  
=cut

sub add_instance {
	my ($self, $instance) = @_;
	if ($instance) {
		my $instance_id = $instance->id();
		if (defined $instance_id) {
			$self->{INSTANCES}->{$instance_id} = $instance;
			#$self->{INSTANCES_SET}->add($instance);
			return $instance;
		} else {
			croak 'An instance to be added to this ontology must have an ID.';
		}
	} else {
    	croak 'Missing instance.';
    }
}

=head2 add_term_as_string

  Usage    - $ontology->add_term_as_string($term_id, $term_name)
  Returns  - the just added term (OBO::Core::Term)
  Args     - the term id (string) and the term name (string) of term to be added
  Function - adds a term to this ontology
  
=cut

sub add_term_as_string {
    my $self = shift;
    if (@_) {
		my $term_id = shift;
		if (!$self->has_term_id($term_id)){
			my $term_name = shift;
			$term_id || croak 'A term to be added to this ontology must have an ID.';
			my $new_term = OBO::Core::Term->new();
			$new_term->id($term_id);
			$new_term->name($term_name);
			$self->add_term($new_term);
			return $new_term;
		} else {
			warn "The term you tried to add ($term_id) is already in the ontology.\n";
		}
    } else {
    	croak 'To add a term, you need to provide both a term ID and a term name.';
    }
}

=head2 add_instance_as_string

  Usage    - $ontology->add_instance_as_string($instance_id, $instance_name)
  Returns  - the just added instance (OBO::Core::Instance)
  Args     - the instance id (string) and the instance name (string) of instance to be added
  Function - adds a instance to this ontology
  
=cut

sub add_instance_as_string {
    my $self = shift;
    if (@_) {
		my $instance_id = shift;
		if (!$self->has_instance_id($instance_id)){
			my $instance_name = shift;
			$instance_id || croak 'A instance to be added to this ontology must have an ID.';
			my $new_instance = OBO::Core::Instance->new();
			$new_instance->id($instance_id);
			$new_instance->name($instance_name);
			$self->add_instance($new_instance);
			return $new_instance;
		} else {
			warn "The instance you tried to add ($instance_id) is already in the ontology.\n";
		}
    } else {
    	croak 'To add a instance, you need to provide both a instance ID and a instance name.';
    }
}

=head2 add_relationship_type

  Usage    - $ontology->add_relationship_type($relationship_type)
  Returns  - the just added relationship type (OBO::Core::RelationshipType)
  Args     - the relationship type to be added (OBO::Core::RelationshipType). The ID of the relationship type to be added must have already been defined.
  Function - adds a relationship type to this ontology
  
=cut

sub add_relationship_type {
    my ($self, $relationship_type) = @_;
    if ($relationship_type) {
		$self->{RELATIONSHIP_TYPES}->{$relationship_type->id()} = $relationship_type;
		return $relationship_type;
		
		# TODO Is it necessary to implement a set of relationship types? Maybe for get_relationship_types()?
		#$self->{RELATIONSHIP_TYPES_SET}->add($relationship_type);
    } else {
    	croak 'Missing argument: add_relationship_type(relationship_type)';
    }
}

=head2 add_relationship_type_as_string

  Usage    - $ontology->add_relationship_type_as_string($relationship_type_id, $relationship_type_name)
  Returns  - the just added relationship type (OBO::Core::RelationshipType)
  Args     - the relationship type id (string) and the relationship type name (string) of the relationship type to be added
  Function - adds a relationship type to this ontology
  
=cut

sub add_relationship_type_as_string {
    my $self = shift;
    if (@_) {
		my $relationship_type_id = shift;
		
		$relationship_type_id || croak 'A relationship type to be added to this ontology must have an ID';
		
		if (!$self->has_relationship_type_id($relationship_type_id)){
			my $relationship_type_name = shift;
			my $new_relationship_type  = OBO::Core::RelationshipType->new();
			$new_relationship_type->id($relationship_type_id);
			$new_relationship_type->name($relationship_type_name);
			$self->add_relationship_type($new_relationship_type);
			return $new_relationship_type;
		} else {
			warn "The relationship type you tried to add ($relationship_type_id) is already in the ontology\n";
		}
    } else {
    	croak 'To add a relationship type, you need to provide both a relationship type ID and a relationship type name';
    }
}

=head2 delete_term

  Usage    - $ontology->delete_term($term)
  Returns  - none
  Args     - the term (OBO::Core::Term) to be deleted
  Function - deletes a term from this ontology
  Remark   - the resulting ontology might be segmented, i.e., the deleted node might create an unconnected sub-ontology
  Remark   - the term (OBO::Core::Term) still exits after removing it from this ontology
  
=cut

sub delete_term {
    my ($self, $term) = @_;
    if ($term) {    
		$term->id() || croak 'The term to be deleted from this ontology does not have an ID.';
    
		my $id = $term->id();
		if (defined($id) && defined($self->{TERMS}->{$id})) {
			delete $self->{TERMS}->{$id};
			$self->{TERMS_SET}->remove($term);
			
			# Delete the relationships: to its parents and children!
			my @outward = @{$self->get_relationships_by_source_term($term)};
			my @inward  = @{$self->get_relationships_by_target_term($term)};
			foreach my $r (@outward, @inward){
				$self->delete_relationship($r);
			}
		}
    }
}

=head2 delete_instance

  Usage    - $ontology->delete_instance($instance)
  Returns  - none
  Args     - the instance (OBO::Core::Instance) to be deleted
  Function - deletes a instance from this ontology
  Remark   - the instance (OBO::Core::Instance) still exits after removing it from this ontology
  
=cut

sub delete_instance {
    my ($self, $instance) = @_;
    if ($instance) {    
		$instance->id() || croak 'The instance to be deleted from this ontology does not have an ID.';
    
		my $id = $instance->id();
		if (defined($id) && defined($self->{INSTANCES}->{$id})) {
			delete $self->{INSTANCES}->{$id};
			#$self->{INSTANCES_SET}->remove($instance);
			
			# TODO Delete the relationships ($self->delete_relationship()): to its parents and children!
		}
    }
}

=head2 delete_relationship

  Usage    - $ontology->delete_relationship($rel)
  Returns  - none
  Args     - the relationship (OBO::Core::Relationship) to be deleted
  Function - deletes a relationship from this ontology
  Remark   - the relationship (OBO::Core::Relationship) still exits after removing it from this ontology

=cut

sub delete_relationship {
    my ($self, $relationship) = @_;
    if ($relationship) {    
		$relationship->id() || croak 'The relationship to be deleted from this ontology does not have an ID.';
    
		my $id = $relationship->id();
		if (defined($id) && defined($self->{RELATIONSHIPS}->{$id})) {
			delete $self->{RELATIONSHIPS}->{$id};
			
			my $head = $relationship->head();
			my $type = $relationship->type();
			my $tail = $relationship->tail();
			delete $self->{TARGET_RELATIONSHIPS}->{$head}->{$type}->{$tail};
			delete $self->{SOURCE_RELATIONSHIPS}->{$tail}->{$type}->{$head};
			delete $self->{TARGET_SOURCE_RELATIONSHIPS}->{$tail}->{$head}->{$type};

			#$self->{RELATIONSHIPS_SET}->remove($term);
		}
    }
}

=head2 has_term

  Usage    - print $ontology->has_term($term)
  Returns  - true or false
  Args     - the term (OBO::Core::Term) to be tested
  Function - checks if the given term belongs to this ontology
  
=cut

sub has_term {
	my ($self, $term) = @_;
	#return (defined $term && defined($self->{TERMS}->{$term->id()})); # TODO Is this faster than:
	return defined $term && $self->{TERMS_SET}->contains($term);
}

=head2 has_instance

  Usage    - print $ontology->has_instance($instance)
  Returns  - true or false
  Args     - the instance (OBO::Core::Instance) to be tested
  Function - checks if the given instance belongs to this ontology
  
=cut

sub has_instance {
	my ($self, $instance) = @_;
	return (defined $instance && defined($self->{INSTANCES}->{$instance->id()}));
	# TODO Check the INSTANCES_SET
	#$result = 1 if (defined($id) && defined($self->{INSTANCES}->{$id}) && $self->{INSTANCES_SET}->contains($instance));
}

=head2 has_term_id

  Usage    - print $ontology->has_term_id($term_id)
  Returns  - true or false
  Args     - the term id (string) to be tested
  Function - checks if the given term id corresponds to a term held by this ontology
  
=cut

sub has_term_id {
	my ($self, $term_id) = @_;
	return (defined $term_id && defined($self->{TERMS}->{$term_id}));
	# TODO Check the TERMS_SET
	#return (defined $term_id && defined($self->{TERMS}->{$term_id}) && $self->{TERMS_SET}->contains($self->get_term_by_id($term_id)));
}

=head2 has_instance_id

  Usage    - print $ontology->has_instance_id($instance_id)
  Returns  - true or false
  Args     - the instance id (string) to be tested
  Function - checks if the given instance id corresponds to a instance held by this ontology
  
=cut

sub has_instance_id {
	my ($self, $instance_id) = @_;
	return (defined $instance_id && defined($self->{INSTANCES}->{$instance_id}));
	# TODO Check the INSTANCES_SET
	#return (defined $instance_id && defined($self->{INSTANCES}->{$instance_id}) && $self->{INSTANCES_SET}->contains($self->get_instance_by_id($instance_id)));
}

=head2 has_relationship_type

  Usage    - print $ontology->has_relationship_type($relationship_type)
  Returns  - true or false
  Args     - the relationship type (OBO::Core::RelationshipType) to be tested
  Function - checks if the given relationship type belongs to this ontology
  
=cut

sub has_relationship_type {
	my ($self, $relationship_type) = @_;    
	return (defined $relationship_type && defined($self->{RELATIONSHIP_TYPES}->{$relationship_type->id()}));
}

=head2 has_relationship_type_id

  Usage    - print $ontology->has_relationship_type_id($relationship_type_id)
  Returns  - true or false
  Args     - the relationship type id (string) to be tested
  Function - checks if the given relationship type id corresponds to a relationship type held by this ontology
  
=cut

sub has_relationship_type_id {
	my ($self, $relationship_type_id) = @_;
	return (defined $relationship_type_id && defined($self->{RELATIONSHIP_TYPES}->{$relationship_type_id}));
}

=head2 has_relationship_id

  Usage    - print $ontology->has_relationship_id($rel_id)
  Returns  - true or false
  Args     - the relationship id (string) to be tested
  Function - checks if the given relationship id corresponds to a relationship held by this ontology
  
=cut

sub has_relationship_id {
	my ($self, $id) = @_;
	return (defined $id && defined($self->{RELATIONSHIPS}->{$id}));
}

=head2 equals

  Usage    - print $ontology->equals($another_ontology)
  Returns  - either 1 (true) or 0 (false)
  Args     - the ontology (OBO::Core::Ontology) to compare with
  Function - tells whether this ontology is equal to the parameter
  
=cut

sub equals {
	my $self = shift;
	my $result =  0; 
	
	# TODO Implement this method
	croak 'Function: OBO::Core:Ontology::equals in not implemented yet, use OBO::Util::Ontolome meanwhile';
	
	return $result;
}

=head2 get_terms

  Usage    - $ontology->get_terms() or $ontology->get_terms("APO:I.*") or $ontology->get_terms("GO:012*")
  Returns  - the terms held by this ontology as a reference to an array of OBO::Core::Term's
  Args     - none or the regular expression for filtering the terms by id's
  Function - returns the terms held by this ontology
  
=cut

sub get_terms {
    my $self = shift;
    my @terms;
    if (@_) {
		foreach my $term (__sort_by_id(sub {shift}, values(%{$self->{TERMS}}))) {
			push @terms, $term if ($term->id() =~ /$_[0]/);
		}
    } else {
		#@terms = $self->{TERMS_SET}->get_set();                            # TODO Is this faster than using 'values'?		
		#@terms = __sort_by_id(sub {shift}, $self->{TERMS_SET}->get_set());
		
		#@terms = values(%{$self->{TERMS}}); # TODO sort or not?
		@terms = __sort_by_id(sub {shift}, values(%{$self->{TERMS}}));
    }
    return \@terms;
}

=head2 get_instances

  Usage    - $ontology->get_instances() or $ontology->get_instances("APO:K.*")
  Returns  - the instances held by this ontology as a reference to an array of OBO::Core::Instance's
  Args     - none or the regular expression for filtering the instances by id's
  Function - returns the instances held by this ontology
  
=cut

sub get_instances {
    my $self = shift;
    my @instances;
    if (@_) {
		foreach my $instance (sort values(%{$self->{INSTANCES}})) {
			push @instances, $instance if ($instance->id() =~ /$_[0]/);
		}
    } else {
		#@instances = $self->{INSTANCES_SET}->get_set(); # TODO This INSTANCES_SET was giving wrong results....
		
		#@instances = sort values(%{$self->{INSTANCES}}); # TODO sort or not?
		@instances =__sort_by_id(sub {shift}, values(%{$self->{INSTANCES}}));
    }
    return \@instances;
}

=head2 get_terms_sorted_by_id

  Usage    - $ontology->get_terms_sorted_by_id() or $ontology->get_terms_sorted_by_id("APO:I.*")
  Returns  - the terms held by this ontology as a reference to a sorted (by ID) array of OBO::Core::Term's
  Args     - none or the regular expression for filtering the terms by id's
  Function - returns the terms held by this ontology, the terms are sorted by ID (using the Schwartzian Transform)
  
=cut

sub get_terms_sorted_by_id {
	my $self = shift;
    my @sorted_terms = __sort_by_id(sub {shift}, @{$self->get_terms(@_)}); 
	return \@sorted_terms;
}

=head2 get_instances_sorted_by_id

  Usage    - $ontology->get_instances_sorted_by_id() or $ontology->get_instances_sorted_by_id("APO:K.*")
  Returns  - the instances held by this ontology as a reference to a sorted (by ID) array of OBO::Core::Instance's
  Args     - none or the regular expression for filtering the instances by id's
  Function - returns the instances held by this ontology, the instances are sorted by ID (using the Schwartzian Transform)
  
=cut

sub get_instances_sorted_by_id {
	my $self = shift;
    my @sorted_instances = __sort_by_id(sub {shift}, @{$self->get_instances(@_)}); 
	return \@sorted_instances;
}

=head2 get_terms_by_subnamespace

  Usage    - $ontology->get_terms_by_subnamespace() or $ontology->get_terms_by_subnamespace("P") or or $ontology->get_terms_by_subnamespace("Pa")
  Returns  - the terms held by this ontology corresponding to the requested subnamespace as a reference to an array of OBO::Core::Term's
  Args     - none or the subnamespace: 'P', 'I', 'Pa', 'Ia' and so on.
  Function - returns the terms held by this ontology corresponding to the requested subnamespace
  
=cut

sub get_terms_by_subnamespace {
	my $self = shift;
	my $terms;
	if (@_) {
		my $is = $self->get_terms_idspace();
		if (!defined $is) {
			croak 'The local ID space is not defined for this ontology.';
		} else {
			$terms = $self->get_terms($is.':'.$_[0]);
		}
	}
	return $terms;
}

=head2 get_instances_by_subnamespace

  Usage    - $ontology->get_instances_by_subnamespace() or $ontology->get_instances_by_subnamespace("K") or or $ontology->get_instances_by_subnamespace("Ka")
  Returns  - the instances held by this ontology corresponding to the requested subnamespace as a reference to an array of OBO::Core::Instance's
  Args     - none or the subnamespace: 'K', 'L', 'Ka', 'La' and so on.
  Function - returns the instances held by this ontology corresponding to the requested subnamespace
  
=cut

sub get_instances_by_subnamespace {
	my $self = shift;
	my $instances;
	if (@_) {
		my $is = $self->get_instances_idspace();
		if (!defined $is) {
			croak 'The local ID space is not defined for this ontology.';
		} else {
			$instances = $self->get_instances($is.':'.$_[0]);
		}
	}
	return $instances;
}

=head2 get_terms_by_subset

  Usage    - $ontology->get_terms_by_subset("GO_SLIM")
  Returns  - the terms held by this ontology belonging to the given subset as a reference to an array of OBO::Core::Term's
  Args     - a subset name
  Function - returns the terms held by this ontology belonging to the requested subset
  
=cut

sub get_terms_by_subset {
	my ($self, $subset) = @_;
	my @terms;
	foreach my $term (__sort_by_id(sub {shift}, values(%{$self->{TERMS}}))) {
		foreach my $ss ($term->subset()) {
			push @terms, $term if ($ss =~ /$subset/);
		}
	}
	return \@terms;
}

=head2 get_instances_by_subset

  Usage    - $ontology->get_instances_by_subset("INSTANCES_SLIM")
  Returns  - the instances held by this ontology belonging to the given subset as a reference to an array of OBO::Core::Instance's
  Args     - a subset name
  Function - returns the instances held by this ontology belonging to the requested subset
  
=cut

sub get_instances_by_subset {
	my ($self, $subset) = @_;
	my @instances;
	foreach my $instance (sort values(%{$self->{INSTANCES}})) {
		foreach my $ss ($instance->subset()) {
			push @instances, $instance if ($ss =~ /$subset/);
		}
	}
	return \@instances;
}

=head2 get_relationships

  Usage    - $ontology->get_relationships()
  Returns  - the relationships held by this ontology as a reference to an array of OBO::Core::Relationship's
  Args     - none
  Function - returns the relationships held by this ontology
  
=cut

sub get_relationships {
    my $self = shift;
    my @relationships = sort values(%{$self->{RELATIONSHIPS}});
    return \@relationships;
}

=head2 get_relationship_types

  Usage    - $ontology->get_relationship_types()
  Returns  - a reference to an array with the relationship types (OBO::Core::RelationshipType) held by this ontology
  Args     - none
  Function - returns the relationship types held by this ontology
  
=cut

sub get_relationship_types {
	my $self = shift;
	my @relationship_types = sort values(%{$self->{RELATIONSHIP_TYPES}});
	return \@relationship_types;
}

=head2 get_relationship_types_sorted_by_id

  Usage    - $ontology->get_relationship_types_sorted_by_id()
  Returns  - the relationship types held by this ontology as a reference to a sorted (by ID) array of OBO::Core::Term's
  Args     - none or the regular expression for filtering the terms by id's
  Function - returns the relationship types held by this ontology, the relationship types are sorted by ID (using the Schwartzian Transform)
  
=cut

sub get_relationship_types_sorted_by_id {
	my $self = shift;
    my @sorted_relationship_types = __sort_by_id(sub {shift}, sort values(%{$self->{RELATIONSHIP_TYPES}}));
	return \@sorted_relationship_types;
}

=head2 get_term_local_neighbourhood

  Usage    - $ontology->get_term_local_neighbourhood($term, $rel_type)
  Returns  - the neighbourhood of a given term as a reference to an array with the relationships (OBO::Core::Relationship)
  Args     - the term (OBO::Core::Term) for which its relationships will be found out; and optionally the relationship type name (e.g. 'participates_in') to select only those types of relationships
  Function - returns the local neighbourhood of the given term as a reference to an array with the relationships (OBO::Core::Relationship)
  Remark   - this subroutine, which is an alias of OBO::Core::get_relationships_by_source_term, might change its interface in the future (a new module, named e.g. TermNeighbourhood, might be implemented)
  
=cut

sub get_term_local_neighbourhood {
	my ($self, $term, $rel_type) = @_;
	return $self->get_relationships_by_source_term($term, $rel_type);
}

=head2 get_relationships_by_source_term

  Usage    - $ontology->get_relationships_by_source_term($source_term, $rel_type)
  Returns  - a reference to an array with the relationships (OBO::Core::Relationship) connecting the given term to its children
  Args     - the term (OBO::Core::Term) for which its relationships will be found out; and optionally the relationship type name (e.g. 'participates_in') to filter out those types of relationships
  Function - returns the relationships associated to the given source term
  
=cut

sub get_relationships_by_source_term {
	my ($self, $term, $rel_type) = @_;
	my $result = OBO::Util::Set->new();
	if ($term) {
		if ($rel_type) {
			my @rels = sort values(%{$self->{SOURCE_RELATIONSHIPS}->{$term}->{$rel_type}});
			foreach my $rel (@rels) {
				$result->add($rel);
			}
		} else {
			my @hashes = sort values(%{$self->{SOURCE_RELATIONSHIPS}->{$term}});
			foreach my $hash (@hashes) {
				my @rels = sort values %{$hash};
				foreach my $rel (@rels) {
					$result->add($rel);
				}
			}
		}
	}
	my @arr = $result->get_set();
	return \@arr;
}

=head2 get_relationships_by_target_term

  Usage    - $ontology->get_relationships_by_target_term($target_term, $rel_type)
  Returns  - a reference to an array with the relationships (OBO::Core::Relationship) connecting the given term to its parents
  Args     - the term (OBO::Core::Term) for which its relationships will be found out; and optionally the relationship type name (e.g. 'participates_in') to filter out those types of relationships
  Function - returns the relationships associated to the given target term
  
=cut

sub get_relationships_by_target_term {
	my ($self, $term, $rel_type) = @_;
	
	my $result = OBO::Util::Set->new();
	if ($term) {
		if ($rel_type) {
			my @rels = sort values(%{$self->{TARGET_RELATIONSHIPS}->{$term}->{$rel_type}});
			foreach my $rel (@rels) {
				$result->add($rel);
			}
		} else {
			my @hashes = sort values(%{$self->{TARGET_RELATIONSHIPS}->{$term}});
			foreach my $hash (@hashes) {
				my @rels = sort values %{$hash};
				foreach my $rel (@rels) {
					$result->add($rel);
				}
			}
		}
	}
	my @arr = $result->get_set();
	return \@arr;
}

=head2 get_term_by_id

  Usage    - $ontology->get_term_by_id($id)
  Returns  - the term (OBO::Core::Term) associated to the given ID
  Args     - the term's ID (string)
  Function - returns the term associated to the given ID
  
=cut

sub get_term_by_id {
	my ($self, $id) = @_;
	return $self->{TERMS}->{$id};
}

=head2 get_instance_by_id

  Usage    - $ontology->get_instance_by_id($id)
  Returns  - the instance (OBO::Core::Instance) associated to the given ID
  Args     - the instance's ID (string)
  Function - returns the instance associated to the given ID
  
=cut

sub get_instance_by_id {
	my ($self, $id) = @_;
	return $self->{INSTANCES}->{$id};
}

=head2 set_term_id

  Usage    - $ontology->set_term_id($term, $new_term_id)
  Returns  - the term (OBO::Core::Term) with its new ID
  Args     - the term (OBO::Core::Term) and its new term's ID (string)
  Function - sets a new term ID for the given term 
  
=cut

sub set_term_id {
    my ($self, $term, $new_term_id) = @_;
    if ($term && $new_term_id) {
    	if ($self->has_term($term)) {
    		if (!$self->has_term_id($new_term_id)) {
				$self->{TERMS_SET}->remove($term);
				my $old_id = $term->id();
				$term->id($new_term_id);
				$self->{TERMS}->{$new_term_id} = $self->{TERMS}->{$old_id};
				delete $self->{TERMS}->{$old_id};
				$self->{TERMS_SET}->add($term);
				
				# Adapt the relationship ids of this term, e.g., APO:P0000001_is_a_APO:P0000002  => APO:P0000003_is_a_APO:P0000002
				my @outward = @{$self->get_relationships_by_source_term($term)};
				foreach my $r (@outward){
					$self->delete_relationship($r);

					my $r_id = $r->id();
					(my $new_r_id = $r_id) =~ s/^$old_id(_)/$new_term_id$1/;
					$r->id($new_r_id);
					$self->create_rel($term, $r->type(), $r->head());
				}
				my @inward  = @{$self->get_relationships_by_target_term($term)};
				foreach my $r (@inward){
					$self->delete_relationship($r);
					
					my $r_id = $r->id();
					(my $new_r_id = $r_id) =~ s/(_)$old_id$/$1$new_term_id/;
					$r->id($new_r_id);
					$self->create_rel($r->tail(), $r->type(), $term);
				}

				return $self->{TERMS}->{$new_term_id};
    		} else {
    			croak 'The given new ID (', $new_term_id, ') is already used by: ', $self->get_term_by_id($new_term_id)->name();
    		}
    	} else {
    		croak 'The term for which you want to modify its ID (', $new_term_id, ') is not in the ontology';
    	}
    }
}

=head2 set_instance_id

  Usage    - $ontology->set_instance_id($instance, $new_id)
  Returns  - the instance (OBO::Core::Instance) with its new ID
  Args     - the instance (OBO::Core::Instance) and its new instance's ID (string)
  Function - sets a new instance ID for the given instance 
  
=cut

sub set_instance_id {
    my ($self, $instance, $new_instance_id) = @_;
    if ($instance && $new_instance_id) {
    	if ($self->has_instance($instance)) {
    		if (!$self->has_instance_id($new_instance_id)) {
				my $old_id = $instance->id();
				$instance->id($new_instance_id);
				$self->{INSTANCES}->{$new_instance_id} = $self->{INSTANCES}->{$old_id};
				delete $self->{INSTANCES}->{$old_id};
				# TODO Adapt the subtype relationship this instance: APO:K0000001_is_a_APO:P0000001  => APO:K0000011_is_a_APO:P0000001
				return $self->{INSTANCES}->{$new_instance_id};
    		} else {
    			croak 'The given new ID (', $new_instance_id, ') is already used by: ', $self->get_instance_by_id($new_instance_id)->name();
    		}
    	} else {
    		croak 'The instance for which you want to modify its ID (', $new_instance_id, ') is not in the ontology';
    	}
    }
}

=head2 get_relationship_type_by_id

  Usage    - $ontology->get_relationship_type_by_id($id)
  Returns  - the relationship type (OBO::Core::RelationshipType) associated to the given id
  Args     - the relationship type's id (string)
  Function - returns the relationship type associated to the given id
  
=cut

sub get_relationship_type_by_id {
	my ($self, $id) = @_;
	return $self->{RELATIONSHIP_TYPES}->{$id} if ($id);
}

=head2 get_term_by_name

  Usage    - $ontology->get_term_by_name($name)
  Returns  - the term (OBO::Core::Term) associated to the given name
  Args     - the term's name (string)
  Function - returns the term associated to the given name
  Remark   - the argument (string) is case sensitive
  
=cut

sub get_term_by_name {
    my ($self, $name) = ($_[0], $_[1]);
    my $result;
    if ($name) {		
		foreach my $term (@{$self->get_terms()}) { # return the exact occurrence
			$result = $term, last if (defined ($term->name()) && ($term->name() eq $name)); 
		}
    }
    return $result;
}

=head2 get_instance_by_name

  Usage    - $ontology->get_instance_by_name($name)
  Returns  - the instance (OBO::Core::Instance) associated to the given name
  Args     - the instance's name (string)
  Function - returns the instance associated to the given name
  Remark   - the argument (string) is case sensitive
  
=cut

sub get_instance_by_name {
    my ($self, $name) = ($_[0], $_[1]);
    my $result;
    if ($name) {		
		foreach my $instance (@{$self->get_instances()}) { # return the exact occurrence
			$result = $instance, last if (defined ($instance->name()) && ($instance->name() eq $name)); 
		}
    }
    return $result;
}

=head2 get_term_by_name_or_synonym

  Usage    - $ontology->get_term_by_name_or_synonym($name, $scope)
  Returns  - the term (OBO::Core::Term) associated to the given name or synonym (given its scope, EXACT by default); 'undef' is returned if no term is found.
  Args     - the term's name or synonym (string) and optionally the scope of the synonym (EXACT by default)
  Function - returns the term associated to the given name or synonym (given its scope, EXACT by default)
  Remark   - this function should be carefully used since among ontologies there may be homonyms at the level of the synonyms (e.g. genes)
  Remark   - the argument (string) is case sensitive
  
=cut

sub get_term_by_name_or_synonym {
    my ($self, $name_or_synonym, $scope) = ($_[0], $_[1], $_[2]);
    if ($name_or_synonym) {
    	$scope = $scope || "EXACT";
		foreach my $term (@{$self->get_terms()}) { # return the exact occurrence
			# Look up for the 'name'
			my $t_name = $term->name();
			if (defined ($t_name) && (lc($t_name) eq $name_or_synonym)) {
				return $term;
			}
			# Look up for its synonyms (and optinal scope)
			foreach my $syn ($term->synonym_set()){
				my $s_text = $syn->def()->text();
				if (($scope eq "ANY"  && $s_text eq $name_or_synonym) || 
					($syn->scope() eq $scope && $s_text eq $name_or_synonym)) {
					return $term;
				}
			}
		}
    }
    return undef;
}

=head2 get_instance_by_name_or_synonym

  Usage    - $ontology->get_instance_by_name_or_synonym($name, $scope)
  Returns  - the instance (OBO::Core::Instance) associated to the given name or synonym (given its scope, EXACT by default); 'undef' is returned if no instance is found.
  Args     - the instance's name or synonym (string) and optionally the scope of the synonym (EXACT by default)
  Function - returns the instance associated to the given name or synonym (given its scope, EXACT by default)
  Remark   - this function should be carefully used since among ontologies there may be homonyms at the level of the synonyms (e.g. locations)
  Remark   - the argument (string) is case sensitive
  
=cut

sub get_instance_by_name_or_synonym {
    my ($self, $name_or_synonym, $scope) = ($_[0], $_[1], $_[2]);
    if ($name_or_synonym) {
    	$scope = $scope || "EXACT";
		foreach my $instance (@{$self->get_instances()}) { # return the exact occurrence
			# Look up for the 'name'
			my $t_name = $instance->name();
			if (defined ($t_name) && (lc($t_name) eq $name_or_synonym)) {
				return $instance;
			}
			# Look up for its synonyms (and optinal scope)
			foreach my $syn ($instance->synonym_set()){
				my $s_text = $syn->def()->text();
				if (($scope eq "ANY"  && $s_text eq $name_or_synonym) || 
					($syn->scope() eq $scope && $s_text eq $name_or_synonym)) {
					return $instance;
				}
			}
		}
    }
    return undef;
}

=head2 get_terms_by_name

  Usage    - $ontology->get_terms_by_name($name)
  Returns  - the term set (OBO::Util::TermSet) with all the terms (OBO::Core::Term) having $name in their names 
  Args     - the term name (string)
  Function - returns the terms having $name in their names 
  
=cut

sub get_terms_by_name {
	my ($self, $name) = ($_[0], lc($_[1]));
	my $result;
	if ($name) {
		$result   = OBO::Util::TermSet->new();
		my @terms = @{$self->get_terms()};
		
		# NB. the following two lines are equivalent to the 'for' loop
		#my @found_terms = grep {lc($_->name()) =~ /$name/} @terms;
		#$result->add_all(@found_terms);

		foreach my $term (@terms) { # return the all the occurrences
			$result->add($term) if (defined ($term->name()) && lc($term->name()) =~ /$name/); 
		}
	}
	return $result;
}

=head2 get_instances_by_name

  Usage    - $ontology->get_instances_by_name($name)
  Returns  - the instance set (OBO::Util::InstanceSet) with all the instances (OBO::Core::Instance) having $name in their names 
  Args     - the instance name (string)
  Function - returns the instances having $name in their names 
  
=cut

sub get_instances_by_name {
	my ($self, $name) = ($_[0], lc($_[1]));
	my $result;
	if ($name) {
		$result   = OBO::Util::InstanceSet->new();
		my @instances = @{$self->get_instances()};
		
		# NB. the following two lines are equivalent to the 'for' loop
		#my @found_instances = grep {lc($_->name()) =~ /$name/} @instances;
		#$result->add_all(@found_instances);

		foreach my $instance (@instances) { # return the all the occurrences
			$result->add($instance) if (defined ($instance->name()) && lc($instance->name()) =~ /$name/); 
		}
	}
	return $result;
}

=head2 get_relationship_types_by_name

  Usage    - $ontology->get_relationship_types_by_name($name)
  Returns  - the relationship types set (OBO::Util::RelationshipTypeSet) with all the relationship types (OBO::Core::RelationshipType) having $name in their names 
  Args     - the relationship type name (string)
  Function - returns the relationship type having $name in their names 
  
=cut

sub get_relationship_types_by_name {
	my ($self, $name) = ($_[0], lc($_[1]));
	my $result;
	if ($name) {
		$result   = OBO::Util::RelationshipTypeSet->new();
		my @relationship_types = @{$self->get_relationship_types()};
		
		# NB. the following two lines are equivalent to the 'for' loop
		#my @found_relationship_types = grep {lc($_->name()) =~ /$name/} @relationship_types;
		#$result->add_all(@found_relationship_types);

		foreach my $relationship_type (@relationship_types) { # return the all the occurrences
			$result->add($relationship_type) if (defined ($relationship_type->name()) && lc($relationship_type->name()) =~ /$name/); 
		}
	}
	return $result;
}

=head2 get_relationship_type_by_name

  Usage    - $ontology->get_relationship_type_by_name($name)
  Returns  - the relationship type (OBO::Core::RelationshipType) associated to the given name
  Args     - the relationship type's name (string)
  Function - returns the relationship type associated to the given name
  
=cut

sub get_relationship_type_by_name {
	my ($self, $name) = ($_[0], lc($_[1]));
	my $result;
	if ($name) {
		foreach my $rel_type (@{$self->get_relationship_types()}) { # return the exact occurrence
			$result = $rel_type, last if (defined ($rel_type->name()) && (lc($rel_type->name()) eq $name)); 
		}
	}
	return $result;
}

=head2 add_relationship

  Usage    - $ontology->add_relationship($relationship)
  Returns  - none
  Args     - the relationship (OBO::Core::Relationship) to be added between two existing terms or two relationship types
  Function - adds a relationship between either two terms or two relationship types.
  Remark   - If the terms or relationship types bound by this relationship are not yet in the ontology, they will be added
  Remark   - if you are adding relationships to an ontology, sometimes it might be better to add their type first (usually if you are building a new ontology from an extant one)  
  
=cut

sub add_relationship {
	my ($self, $relationship) = @_;

	my $rel_id   = $relationship->id();
	my $rel_type = $relationship->type();
	
	$rel_id   || croak 'The relationship to be added to this ontology does not have an ID';
	$rel_type || croak 'The relationship to be added to this ontology does not have an TYPE';
	
	$self->{RELATIONSHIPS}->{$rel_id} = $relationship;
    
	#
	# Are the target and source elements (term or relationship type) connected by $relationship already in this ontology? if not, add them.
	#
	my $r              = $self->{RELATIONSHIPS}->{$rel_id};
	my $target_element = $r->head();
	my $source_element = $r->tail();
	
	if (eval { $target_element->isa('OBO::Core::Term') } && eval { $source_element->isa('OBO::Core::Term') }) {
		$self->has_term($target_element)              || $self->add_term($target_element);
		$self->has_term($source_element)              || $self->add_term($source_element);
	} elsif (eval { $target_element->isa('OBO::Core::RelationshipType') } && eval { $source_element->isa('OBO::Core::RelationshipType') }) {
		$self->has_relationship_type($target_element) || $self->add_relationship_type($target_element);
		$self->has_relationship_type($source_element) || $self->add_relationship_type($source_element);
	} elsif (eval { $target_element->isa('OBO::Core::Term') } && eval { $source_element->isa('OBO::Core::Instance') }) { # TODO Do we need this? or better add $self->{PROPERTY_VALUES}?
		$self->has_term($target_element)              || $self->add_term($target_element);
		$self->has_instance($source_element)          || $self->add_instance($source_element);
	} elsif (eval { $target_element->isa('OBO::Core::Instance') } && eval { $source_element->isa('OBO::Core::Instance') }) { # TODO Do we need this? or better add $self->{PROPERTY_VALUES}?
		$self->has_instance($target_element)          || $self->add_instance($target_element);
		$self->has_instance($source_element)          || $self->add_instance($source_element);
	} else {
		croak "An unrecognized object type (nor a Term, nor a RelationshipType) was found as part of the relationship with ID: '", $rel_id, "'";
	}
	
	#
	# add the relationship type
	#
	if (!$self->has_relationship_type_id($rel_type) ){
		my $new_rel_type = OBO::Core::RelationshipType->new();
		$new_rel_type->id($rel_type);
		$self->{RELATIONSHIP_TYPES}->{$rel_type} = $new_rel_type;
	}
    
	# for getting children and parents
	my $head = $relationship->head();
	my $type = $relationship->type();
	my $tail = $relationship->tail();
	$self->{TARGET_RELATIONSHIPS}->{$head}->{$type}->{$tail}        = $relationship;
	$self->{SOURCE_RELATIONSHIPS}->{$tail}->{$type}->{$head}        = $relationship;
	$self->{TARGET_SOURCE_RELATIONSHIPS}->{$tail}->{$head}->{$type} = $relationship;
}

=head2 get_relationship_by_id

  Usage    - print $ontology->get_relationship_by_id()
  Returns  - the relationship (OBO::Core::Relationship) associated to the given id
  Args     - the relationship id (string)
  Function - returns the relationship associated to the given relationship id
  
=cut

sub get_relationship_by_id {
	my ($self, $id) = @_;
	return $self->{RELATIONSHIPS}->{$id};
}

=head2 create_rel

  Usage    - $ontology->create_rel($tail, $type, $head)
  Returns  - the OBO::Core::Ontology object
  Args     - an OBO::Core::(Term|Relationship) object, a relationship type string (e.g. 'is_a'), and an OBO::Core::(Term|Relationship) object
  Function - creates and adds a new relationship (between two terms or relationships) to this ontology
  
=cut

sub create_rel {
	my $self                 = shift;
	my ($tail, $type, $head) = @_;
	
	croak "Not a valid relationship type: '", $type, "'" unless($self->{RELATIONSHIP_TYPES}->{$type});
	
	if ($tail && $head) {
		my $id = $tail->id().'_'.$type.'_'.$head->id();
		
		if ($self->has_relationship_id($id)) {
			#cluck 'The following rel ID already exists in the ontology: ', $id; # Implement a RelationshipSet?
			
			my $relationship = $self->get_relationship_by_id($id);
			$self->{TARGET_RELATIONSHIPS}->{$head}->{$type}->{$tail}        = $relationship;
			$self->{SOURCE_RELATIONSHIPS}->{$tail}->{$type}->{$head}        = $relationship;
			$self->{TARGET_SOURCE_RELATIONSHIPS}->{$tail}->{$head}->{$type} = $relationship;
		} else {
			my $rel = OBO::Core::Relationship->new(); 
			$rel->type($type);
			$rel->link($tail, $head);
			$rel->id($id);
			$self->add_relationship($rel);
		}
	} else {
		croak 'To create a relationship, you must provide both a tail object and a head object!';
	}
	return $self;
}

=head2 get_child_terms

  Usage    - $ontology->get_child_terms($term)
  Returns  - a reference to an array with the child terms (OBO::Core::Term) of the given term
  Args     - the term (OBO::Core::Term) for which the children will be found
  Function - returns the child terms of the given term
  
=cut

sub get_child_terms {
	my ($self, $term) = @_;
	my $result = OBO::Util::TermSet->new();
	if ($term) {
		my @hashes = values(%{$self->{TARGET_RELATIONSHIPS}->{$term}});
		foreach my $hash (@hashes) {
			my @rels = sort values %{$hash};
			foreach my $rel (@rels) {
				$result->add($rel->tail());
			}
		}
	 }
	my @arr = $result->get_set();
	return \@arr;
}

=head2 get_parent_terms

  Usage    - $ontology->get_parent_terms($term)
  Returns  - a reference to an array with the parent terms (OBO::Core::Term) of the given term
  Args     - the term (OBO::Core::Term) for which the parents will be found
  Function - returns the parent terms of the given term
  
=cut

sub get_parent_terms {
	my ($self, $term) = @_;
	my $result = OBO::Util::TermSet->new();
	if ($term) {		
		my @hashes = sort values(%{$self->{SOURCE_RELATIONSHIPS}->{$term}});
		foreach my $hash (@hashes) {
			my @rels = sort values %{$hash};
			foreach my $rel (@rels) {
				$result->add($rel->head());
			}
		}
	}
	my @arr = $result->get_set();
	return \@arr;
}

=head2 get_head_by_relationship_type

  Usage    - $ontology->get_head_by_relationship_type($term, $relationship_type) or $ontology->get_head_by_relationship_type($rel_type, $relationship_type)
  Returns  - a reference to an array of terms (OBO::Core::Term) or relationship types (OBO::Core::RelationshipType) pointed out by the relationship of the given type; otherwise undef
  Args     - the term (OBO::Core::Term) or relationship type (OBO::Core::RelationshipType) and the pointing relationship type (OBO::Core::RelationshipType)
  Function - returns the terms or relationship types pointed out by the relationship of the given type
  
=cut

sub get_head_by_relationship_type {
	my ($self, $element, $relationship_type) = @_;
	my @heads;
	if ($element && $relationship_type) {
		my $relationship_type_id = $relationship_type->id();
		
		my @hashes = sort values(%{$self->{SOURCE_RELATIONSHIPS}->{$element}});
		foreach my $hash (@hashes) {
			my @rels = sort values %{$hash};
			foreach my $rel (@rels) {
				push @heads, $rel->head() if ($rel->type() eq $relationship_type_id);
				#Fix for some cases: push @heads, $rel->head() if ($rel->type() eq $relationship_type->name());
			}
		}
	}
	return \@heads;
}

=head2 get_tail_by_relationship_type

  Usage    - $ontology->get_tail_by_relationship_type($term, $relationship_type) or $ontology->get_tail_by_relationship_type($rel_type, $relationship_type)
  Returns  - a reference to an array of terms (OBO::Core::Term) or relationship types (OBO::Core::RelationshipType) pointing out the given term by means of the given relationship type; otherwise undef
  Args     - the term (OBO::Core::Term) or relationship type (OBO::Core::RelationshipType) and the relationship type (OBO::Core::RelationshipType)
  Function - returns the terms or relationship types pointing out the given term by means of the given relationship type
  
=cut

sub get_tail_by_relationship_type {
	my ($self, $element, $relationship_type) = @_;
	my @tails;
	if ($element && $relationship_type) {
		my $relationship_type_id = $relationship_type->id();
		
		my @hashes = sort values(%{$self->{TARGET_RELATIONSHIPS}->{$element}});
		foreach my $hash (@hashes) {
			my @rels = sort values %{$hash};
			foreach my $rel (@rels) {
				push @tails, $rel->tail() if ($rel->type() eq $relationship_type_id);
			}
		}
	}
	return \@tails;
}

=head2 get_root_terms

  Usage    - $ontology->get_root_terms()
  Returns  - the root term(s) held by this ontology (as a reference to an array of OBO::Core::Term's)
  Args     - none
  Function - returns the root term(s) held by this ontology
  
=cut

sub get_root_terms {
	my $self     = shift;
	my @roots    = ();
	my $term_set = OBO::Util::TermSet->new();
	
	$term_set->add_all(__sort_by_id(sub {shift}, values(%{$self->{TERMS}})));
	my @arr = $term_set->get_set();
	
	while ($term_set->size() > 0) {
		my $term   = pop @arr;
		my @hashes = sort values(%{$self->{SOURCE_RELATIONSHIPS}->{$term}});
		
		if ($#hashes  == -1) {        # if there are no parents
			push @roots, $term;       # it must be a root term
			$term_set->remove($term);
		} else {                      # if it is NOT a root term
			my @queue = ($term);
			while (scalar(@queue) > 0) {
				my $unqueued = shift @queue;
				my $rcode    = $term_set->remove($unqueued); # remove the nodes that need not be visited
				my @children = @{$self->get_child_terms($unqueued)};
				@queue       = (@queue, @children);
			}
			@arr = $term_set->get_set();
		}
	}
	return \@roots;
}

=head2 get_number_of_terms

  Usage    - $ontology->get_number_of_terms()
  Returns  - the number of terms held by this ontology
  Args     - none
  Function - returns the number of terms held by this ontology
  
=cut

sub get_number_of_terms {
	my $self = shift;
	return scalar values(%{$self->{TERMS}});
}

=head2 get_number_of_instances

  Usage    - $ontology->get_number_of_instances()
  Returns  - the number of instances held by this ontology
  Args     - none
  Function - returns the number of instances held by this ontology
  
=cut

sub get_number_of_instances {
	my $self = shift;
	return scalar values(%{$self->{INSTANCES}});
}

=head2 get_number_of_relationships

  Usage    - $ontology->get_number_of_relationships()
  Returns  - the number of relationships held by this ontology
  Args     - none
  Function - returns the number of relationships held by this ontology
  
=cut

sub get_number_of_relationships {
	my $self = shift;
	return scalar values(%{$self->{RELATIONSHIPS}});
}

=head2 get_number_of_relationship_types

  Usage    - $ontology->get_number_of_relationship_types()
  Returns  - the number of relationship types held by this ontology
  Args     - none
  Function - returns the number of relationship types held by this ontology
  
=cut

sub get_number_of_relationship_types {
	my $self = shift;
	return scalar values(%{$self->{RELATIONSHIP_TYPES}});
}

=head2 export2obo

  See - OBO::Core::Ontology::export()
  
=cut

sub export2obo {
	
	my ($self, $output_file_handle, $error_file_handle) = @_;
	
	#######################################################################
	#
	# preambule: OBO header tags
	#
	#######################################################################
	print $output_file_handle "format-version: 1.4\n";
	my $data_version = $self->data_version();
	print $output_file_handle 'data-version:', $data_version, "\n" if ($data_version);
	
	my $ontology_id_space = $self->id();
	print $output_file_handle 'ontology:', $ontology_id_space, "\n" if ($ontology_id_space);
	chomp(my $local_date = __date()); # `date '+%d:%m:%Y %H:%M'` # date: 11:05:2008 12:52
	print $output_file_handle 'date: ', (defined $self->date())?$self->date():$local_date, "\n";
	
	my $saved_by = $self->saved_by();
	print $output_file_handle 'saved-by: ', $saved_by, "\n" if (defined $saved_by);
	print $output_file_handle "auto-generated-by: ONTO-PERL $VERSION\n";
	
	# import
	foreach my $import (sort {lc($a) cmp lc($b)} $self->imports()->get_set()) {
		print $output_file_handle 'import: ', $import, "\n";
	}
	
	# subsetdef
	foreach my $subsetdef (sort {lc($a->name()) cmp lc($b->name())} $self->subset_def_map()->values()) {
		print $output_file_handle 'subsetdef: ', $subsetdef->as_string(), "\n";
	}
	
	# synonyntypedef
	foreach my $st (sort {lc($a->name()) cmp lc($b->name())} $self->synonym_type_def_set()->get_set()) {
		print $output_file_handle 'synonymtypedef: ', $st->as_string(), "\n";
	}

	# idspace's		
	foreach my $idspace ($self->idspaces()->get_set()) {
		print $output_file_handle 'idspace: ', $idspace->as_string(), "\n";
	}
	
	# default_relationship_id_prefix
	my $dris = $self->default_relationship_id_prefix();
	print $output_file_handle 'default_relationship_id_prefix: ', $dris, "\n" if (defined $dris);
	
	# default_namespace
	my $dns = $self->default_namespace();
	print $output_file_handle 'default-namespace: ', $dns, "\n" if (defined $dns);
	
	# remark's
	foreach my $remark ($self->remarks()->get_set()) {
		print $output_file_handle 'remark: ', $remark, "\n";
	}
	
	# treat-xrefs-as-equivalent
	foreach my $id_space_xref_eq (sort {lc($a) cmp lc($b)} $self->treat_xrefs_as_equivalent()->get_set()) {
		print $output_file_handle 'treat-xrefs-as-equivalent: ', $id_space_xref_eq, "\n";
	}
	
	# treat_xrefs_as_is_a
	foreach my $id_space_xref_eq (sort {lc($a) cmp lc($b)} $self->treat_xrefs_as_is_a()->get_set()) {
		print $output_file_handle 'treat-xrefs-as-is_a: ', $id_space_xref_eq, "\n";
	}
	
	#######################################################################
	#
	# terms
	#
	#######################################################################
	my @all_terms = @{$self->get_terms_sorted_by_id()};
	foreach my $term (@all_terms) {
		#
		# [Term]
		#
		print $output_file_handle "\n[Term]";
    	
		#
		# id
		#
		print $output_file_handle "\nid: ", $term->id();
    	
		#
		# is_anonymous
		#
		print $output_file_handle "\nis_anonymous: true" if ($term->is_anonymous());

		#
		# name
		#
		if (defined $term->name()) { # from OBO 1.4, the name is not mandatory anymore
			print $output_file_handle "\nname: ", $term->name();
		}

		#
		# namespace
		#
		foreach my $ns ($term->namespace()) {
			print $output_file_handle "\nnamespace: ", $ns;
		}
    	
		#
		# alt_id
		#
		foreach my $alt_id ($term->alt_id()->get_set()) {
			print $output_file_handle "\nalt_id: ", $alt_id;
		}
    	
		#
		# builtin
		#
		print $output_file_handle "\nbuiltin: true" if ($term->builtin());
		
		#
		# property_value
		#
		my @property_values = sort {$a->id() cmp $b->id()} $term->property_value()->get_set();
		foreach my $value (@property_values) {
			if (defined $value->head()->instance_of()) {
				print $output_file_handle "\nproperty_value: ".$value->type().' "'.$value->head()->id().'" '.$value->head()->instance_of()->id();
			} else {
				print $output_file_handle "\nproperty_value: ".$value->type().' '.$value->head()->id();
			}
		}
    	
		#
		# def
		#
		# QUICK FIXES (string substitutions) due to some odd files (e.g. IntAct data)
		if (defined $term->def()->text()) {
			my $def_as_string = $term->def_as_string();
			$def_as_string =~ s/\n+//g;
			$def_as_string =~ s/\r+//g;
			$def_as_string =~ s/\t+//g;
			print $output_file_handle "\ndef: ", $def_as_string;
		}
    	
		#
		# comment
		#
		print $output_file_handle "\ncomment: ", $term->comment() if (defined $term->comment());
	
		#
		# subset
		#
		foreach my $sset_name (sort {$a cmp $b} $term->subset()) {
			if ($self->subset_def_map()->contains_key($sset_name)) {
				print $output_file_handle "\nsubset: ", $sset_name;
			} else {
				print $error_file_handle "\nThe term ", $term->id(), " belongs to a non-defined subset ($sset_name).\nYou should add the missing subset definition.\n";
			}
		}

		#
		# synonym
		#
		my @sorted_defs = map { $_->[0] }        # restore original values
			sort { $a->[1] cmp $b->[1] }         # sort
			map  { [$_, lc($_->def()->text())] } # transform: value, sortkey
			$term->synonym_set();
		foreach my $synonym (@sorted_defs) {
			my $stn = $synonym->synonym_type_name();
			if (defined $stn) {
				print $output_file_handle "\nsynonym: \"".$synonym->def()->text().'" '.$synonym->scope().' '.$stn.' '.$synonym->def()->dbxref_set_as_string();
			} else {
				print $output_file_handle "\nsynonym: \"".$synonym->def()->text().'" '.$synonym->scope().' '.$synonym->def()->dbxref_set_as_string();
			}
		}
    	
		#
		# xref
		#
		my @sorted_xrefs = __sort_by(sub {lc(shift)}, sub { OBO::Core::Dbxref::as_string(shift) }, $term->xref_set_as_string());
		foreach my $xref (@sorted_xrefs) {
			print $output_file_handle "\nxref: ", $xref->as_string();
		}
    	
		#
		# is_a
		#
		my $rt = $self->get_relationship_type_by_id('is_a');
		if (defined $rt)  {
			my %saw_is_a; # avoid duplicated arrows (RelationshipSet?)
			my @sorted_heads = __sort_by_id(sub {lc(shift)}, @{$self->get_head_by_relationship_type($term, $rt)}); 
			foreach my $head (grep (!$saw_is_a{$_}++, @sorted_heads)) {
				my $is_a_txt = "\nis_a: ".$head->id();
				my $head_name = $head->name();
				$is_a_txt .= ' ! '.$head_name if (defined $head_name);
				print $output_file_handle $is_a_txt;
			}
		}

		#
		# intersection_of (at least 2 entries)
		#
		foreach my $tr ($term->intersection_of()) {
			my $tr_head = $tr->head();
			my $tr_type = $tr->type();
			my $intersection_of_name = $tr_head->name();
			my $intersection_of_txt  = "\nintersection_of: ";
			$intersection_of_txt    .= $tr_type.' ' if ($tr_type ne 'nil');
			$intersection_of_txt    .= $tr_head->id();
			$intersection_of_txt    .= ' ! '.$intersection_of_name if (defined $intersection_of_name);
			print $output_file_handle $intersection_of_txt;
		}

		#
		# union_of (at least 2 entries)
		#
		foreach my $tr ($term->union_of()) {
			print $output_file_handle "\nunion_of: ", $tr;
		}		
    	
		#
		# disjoint_from
		#
		foreach my $disjoint_term_id ($term->disjoint_from()) {
			my $disjoint_from_txt = "\ndisjoint_from: ".$disjoint_term_id;
			my $dt                = $self->get_term_by_id($disjoint_term_id);
			my $dt_name           = $dt->name() if (defined $dt);
			$disjoint_from_txt   .= ' ! '.$dt_name if (defined $dt_name);
			print $output_file_handle $disjoint_from_txt;
		}
		
		#
		# relationship
		#
		my %saw1;
		my @sorted_rel_types = @{$self->get_relationship_types_sorted_by_id()};
		foreach my $rt (grep (!$saw1{$_}++, @sorted_rel_types)) { # use this foreach-line if there are duplicated rel's
			my $rt_id = $rt->id();
			if ($rt_id ne 'is_a') { # is_a is printed above
				my %saw2;
				my @sorted_heads = __sort_by_id(sub {lc(shift)}, @{$self->get_head_by_relationship_type($term, $rt)});
				foreach my $head (grep (!$saw2{$_}++, @sorted_heads)) { # use this foreach-line if there are duplicated rel's
					my $relationship_txt  = "\nrelationship: ".$rt_id.' '.$head->id();
					my $relationship_name = $head->name();
					$relationship_txt    .= ' ! '.$relationship_name if (defined $relationship_name);
					print $output_file_handle $relationship_txt;
				}
			}
		}

		#
		# created_by
		#
		print $output_file_handle "\ncreated_by: ", $term->created_by() if (defined $term->created_by());

		#
		# creation_date
		#
		print $output_file_handle "\ncreation_date: ", $term->creation_date() if (defined $term->creation_date());
		
		#
		# modified_by
		#
		print $output_file_handle "\nmodified_by: ", $term->modified_by() if (defined $term->modified_by());

		#
		# modification_date
		#
		print $output_file_handle "\nmodification_date: ", $term->modification_date() if (defined $term->modification_date());
		
		#
		# is_obsolete
		#
		print $output_file_handle "\nis_obsolete: true" if ($term->is_obsolete());

		#
		# replaced_by
		#
		foreach my $replaced_by ($term->replaced_by()->get_set()) {
			print $output_file_handle "\nreplaced_by: ", $replaced_by;
		}
		
		#
		# consider
		#
		foreach my $consider ($term->consider()->get_set()) {
			print $output_file_handle "\nconsider: ", $consider;
		}
		
		#
		# end
		#
		print $output_file_handle "\n";
	}

	#######################################################################
	#
	# instances
	#
	#######################################################################
	my @all_instances = @{$self->get_instances_sorted_by_id()};
	foreach my $instance (@all_instances) {
		#
		# [Instance]
		#
		print $output_file_handle "\n[Instance]";
    	
		#
		# id
		#
		print $output_file_handle "\nid: ", $instance->id();
    	
		#
		# is_anonymous
		#
		print $output_file_handle "\nis_anonymous: true" if ($instance->is_anonymous());

		#
		# name
		#
		if (defined $instance->name()) { # from OBO 1.4, the name is not mandatory anymore
			print $output_file_handle "\nname: ", $instance->name();
		}

		#
		# namespace
		#
		foreach my $ns ($instance->namespace()) {
			print $output_file_handle "\nnamespace: ", $ns;
		}
    	
		#
		# alt_id
		#
		foreach my $alt_id ($instance->alt_id()->get_set()) {
			print $output_file_handle "\nalt_id: ", $alt_id;
		}
    	
		#
		# builtin
		#
		print $output_file_handle "\nbuiltin: true" if ($instance->builtin());

		#
		# comment
		#
		print $output_file_handle "\ncomment: ", $instance->comment() if (defined $instance->comment());
	
		#
		# subset
		#
		foreach my $sset_name (sort {$a cmp $b} $instance->subset()) {
			if ($self->subset_def_map()->contains_key($sset_name)) {
				print $output_file_handle "\nsubset: ", $sset_name;
			} else {
				print $error_file_handle "\nThe instance ", $instance->id(), " belongs to a non-defined subset ($sset_name).\nYou should add the missing subset definition.\n";
			}
		}

		#
		# synonym
		#
		my @sorted_defs = map { $_->[0] }        # restore original values
			sort { $a->[1] cmp $b->[1] }         # sort
			map  { [$_, lc($_->def()->text())] } # transform: value, sortkey
			$instance->synonym_set();
		foreach my $synonym (@sorted_defs) {
			my $stn = $synonym->synonym_type_name();
			if (defined $stn) {
				print $output_file_handle "\nsynonym: \"".$synonym->def()->text().'" '.$synonym->scope().' '.$stn.' '.$synonym->def()->dbxref_set_as_string();
			} else {
				print $output_file_handle "\nsynonym: \"".$synonym->def()->text().'" '.$synonym->scope().' '.$synonym->def()->dbxref_set_as_string();
			}
		}
    	
		#
		# xref
		#
		my @sorted_xrefs = __sort_by(sub {lc(shift)}, sub { OBO::Core::Dbxref::as_string(shift) }, $instance->xref_set_as_string());
		foreach my $xref (@sorted_xrefs) {
			print $output_file_handle "\nxref: ", $xref->as_string();
		}

		#
		# instance_of
		#
		my $class = $instance->instance_of();
		if ($class) {
			my $instance_of_txt = "\ninstance_of: ".$class->id();
			my $class_name      = $class->name();
			$instance_of_txt   .= ' ! '.$class_name if (defined $class_name);
			print $output_file_handle $instance_of_txt;
		}

		#
		# property_value
		#
		my @property_values = sort {$a->id() cmp $b->id()} $instance->property_value()->get_set();
		foreach my $value (@property_values) {
	    	# TODO Finalise this implementation
			print $output_file_handle "\nproperty_value: ".$value->type().' '.$value->head()->id();
		}

		#
		# intersection_of (at least 2 entries)
		#
		foreach my $tr ($instance->intersection_of()) {
			my $tr_head = $tr->head();
			my $tr_type = $tr->type();
			my $intersection_of_name = $tr_head->name();
			my $intersection_of_txt  = "\nintersection_of: ";
			$intersection_of_txt    .= $tr_type.' ' if ($tr_type ne 'nil');
			$intersection_of_txt    .= $tr_head->id();
			$intersection_of_txt    .= ' ! '.$intersection_of_name if (defined $intersection_of_name);
			print $output_file_handle $intersection_of_txt;
		}

		#
		# union_of (at least 2 entries)
		#
		foreach my $tr ($instance->union_of()) {
			print $output_file_handle "\nunion_of: ", $tr;
		}		
    	
		#
		# disjoint_from
		#
		foreach my $disjoint_instance_id ($instance->disjoint_from()) {
			my $disjoint_from_txt = "\ndisjoint_from: ".$disjoint_instance_id;
			my $dt                = $self->get_instance_by_id($disjoint_instance_id);
			my $dt_name           = $dt->name() if (defined $dt);
			$disjoint_from_txt   .= ' ! '.$dt_name if (defined $dt_name);
			print $output_file_handle $disjoint_from_txt;
		}
		
		#
		# relationship
		#
		my %saw1;
		my @sorted_rel_types = @{$self->get_relationship_types_sorted_by_id()};
		foreach my $rt (grep (!$saw1{$_}++, @sorted_rel_types)) { # use this foreach-line if there are duplicated rel's
			my $rt_id = $rt->id();
			if ($rt_id ne 'is_a') { # is_a is printed above
				my %saw2;
				my @sorted_heads = __sort_by_id(sub {lc(shift)}, @{$self->get_head_by_relationship_type($instance, $rt)});
				foreach my $head (grep (!$saw2{$_}++, @sorted_heads)) { # use this foreach-line if there are duplicated rel's
					my $relationship_txt  = "\nrelationship: ".$rt_id.' '.$head->id();
					my $relationship_name = $head->name();
					$relationship_txt    .= ' ! '.$relationship_name if (defined $relationship_name);
					print $output_file_handle $relationship_txt;
				}
			}
		}

		#
		# created_by
		#
		print $output_file_handle "\ncreated_by: ", $instance->created_by() if (defined $instance->created_by());

		#
		# creation_date
		#
		print $output_file_handle "\ncreation_date: ", $instance->creation_date() if (defined $instance->creation_date());
		
		#
		# modified_by
		#
		print $output_file_handle "\nmodified_by: ", $instance->modified_by() if (defined $instance->modified_by());

		#
		# modification_date
		#
		print $output_file_handle "\nmodification_date: ", $instance->modification_date() if (defined $instance->modification_date());
		
		#
		# is_obsolete
		#
		print $output_file_handle "\nis_obsolete: true" if ($instance->is_obsolete());

		#
		# replaced_by
		#
		foreach my $replaced_by ($instance->replaced_by()->get_set()) {
			print $output_file_handle "\nreplaced_by: ", $replaced_by;
		}
		
		#
		# consider
		#
		foreach my $consider ($instance->consider()->get_set()) {
			print $output_file_handle "\nconsider: ", $consider;
		}
		
		#
		# end
		#
		print $output_file_handle "\n";
	}

	#######################################################################
	#
	# relationship types
	#
	#######################################################################
	foreach my $relationship_type ( @{$self->get_relationship_types_sorted_by_id()} ) {
		
		print $output_file_handle "\n[Typedef]";
		
		#
		# id
		#
		print $output_file_handle "\nid: ", $relationship_type->id();
		
		#
		# is_anonymous
		#
		print $output_file_handle "\nis_anonymous: true" if ($relationship_type->is_anonymous());
		
		#
		# name
		#
		my $relationship_type_name = $relationship_type->name();
		if (defined $relationship_type_name) {
			print $output_file_handle "\nname: ", $relationship_type_name;
		}
		
		#
		# namespace
		#
		foreach my $ns ($relationship_type->namespace()) {
			print $output_file_handle "\nnamespace: ", $ns;
		}
		
		#
		# alt_id
		#
		foreach my $alt_id ($relationship_type->alt_id()->get_set()) {
			print $output_file_handle "\nalt_id: ", $alt_id;
		}
		
		#
		# builtin
		#
		print $output_file_handle "\nbuiltin: true" if ($relationship_type->builtin() == 1);
		
		#
		# def
		#
		print $output_file_handle "\ndef: ", $relationship_type->def_as_string() if (defined $relationship_type->def()->text());
		
		#
		# comment
		#
		print $output_file_handle "\ncomment: ", $relationship_type->comment() if (defined $relationship_type->comment());

		#
		# subset
		#
		foreach my $sset_name ($relationship_type->subset()) {
			if ($self->subset_def_map()->contains_key($sset_name)) {
				print $output_file_handle "\nsubset: ", $sset_name;
			} else {
				print $error_file_handle "\nThe relationship type ", $relationship_type->id(), " belongs to a non-defined subset ($sset_name).\nYou should add the missing subset definition.\n";
			}
		}
		
		#
		# synonym
		#
		foreach my $synonym ($relationship_type->synonym_set()) {
			print $output_file_handle "\nsynonym: \"".$synonym->def()->text().'" '.$synonym->scope().' '.$synonym->def()->dbxref_set_as_string();
		}
    	
    	#
    	# xref
    	#
    	my @sorted_xrefs = __sort_by(sub {lc(shift)}, sub { OBO::Core::Dbxref::as_string(shift) }, $relationship_type->xref_set_as_string());
    	foreach my $xref (@sorted_xrefs) {
			print $output_file_handle "\nxref: ", $xref->as_string();
		}

		#
		# domain
		#
		foreach my $domain ($relationship_type->domain()->get_set()) {
			print $output_file_handle "\ndomain: ", $domain;
		}
		
		#
		# range
		#
		foreach my $range ($relationship_type->range()->get_set()) {
			print $output_file_handle "\nrange: ", $range;
		}
		
		print $output_file_handle "\nis_anti_symmetric: true" if ($relationship_type->is_anti_symmetric() == 1);
		print $output_file_handle "\nis_cyclic: true" if ($relationship_type->is_cyclic() == 1);
		print $output_file_handle "\nis_reflexive: true" if ($relationship_type->is_reflexive() == 1);
		print $output_file_handle "\nis_symmetric: true" if ($relationship_type->is_symmetric() == 1);
		print $output_file_handle "\nis_transitive: true" if ($relationship_type->is_transitive() == 1);
    	
		#
		# is_a: TODO missing function to retrieve the rel types
		#
		my $rt = $self->get_relationship_type_by_id('is_a');
		if (defined $rt)  {
			my @heads = @{$self->get_head_by_relationship_type($relationship_type, $rt)};
			foreach my $head (@heads) {
				my $head_name = $head->name();
				if (defined $head_name) {
					print $output_file_handle "\nis_a: ", $head->id(), ' ! ', $head_name;
				} else {
					print $output_file_handle "\nis_a: ", $head->id();
				}
				
			}
		}
		
		#
		# intersection_of (at least 2 entries)
		#
		foreach my $tr ($relationship_type->intersection_of()) {
			my $tr_head = $tr->head();
			my $tr_type = $tr->type();
			my $intersection_of_name = $tr_head->name();
			my $intersection_of_txt  = "\nintersection_of: ";
			$intersection_of_txt    .= $tr_type.' ' if ($tr_type ne 'nil');
			$intersection_of_txt    .= $tr_head->id();
			$intersection_of_txt    .= ' ! '.$intersection_of_name if (defined $intersection_of_name);
			print $output_file_handle $intersection_of_txt;
		}
		
		#
		# union_of (at least 2 entries)
		#
		foreach my $tr ($relationship_type->union_of()) {
			print $output_file_handle "\nunion_of: ", $tr;
		}
		
		#
		# disjoint_from
		#
		foreach my $disjoint_relationship_type_id ($relationship_type->disjoint_from()) {
			my $disjoint_from_txt = "\ndisjoint_from: ".$disjoint_relationship_type_id;
			my $dt                = $self->get_relationship_type_by_id($disjoint_relationship_type_id);
			my $dt_name           = $dt->name() if (defined $dt);
			$disjoint_from_txt   .= ' ! '.$dt_name if (defined $dt_name);
			print $output_file_handle $disjoint_from_txt;
		}
    	    	
    	#
		# inverse_of
		#
		my $ir = $relationship_type->inverse_of();
		if (defined $ir) {
			my $inv_name = $ir->name();
			if (defined $inv_name) {
				print $output_file_handle "\ninverse_of: ", $ir->id(), ' ! ', $inv_name;
			} else {
				print $output_file_handle "\ninverse_of: ", $ir->id();
			}
		}
		
		#
		# transitive_over
		#
		foreach my $transitive_over ($relationship_type->transitive_over()->get_set()) {
			print $output_file_handle "\ntransitive_over: ", $transitive_over;
		}
		
		#
		# holds_over_chain
		#
		my @sorted_hocs = map { $_->[0] }                    # restore original values
						sort { $a->[1] cmp $b->[1] }         # sort
						map  { [$_, lc(@{$_}[0].@{$_}[1])] } # transform: value, sortkey
						$relationship_type->holds_over_chain();
		foreach my $holds_over_chain (@sorted_hocs) {
			print $output_file_handle "\nholds_over_chain: ", @{$holds_over_chain}[0], ' ', @{$holds_over_chain}[1];
		}
		
		#
    	# is_functional
    	#
		print $output_file_handle "\nis_functional: true" if ($relationship_type->is_functional() == 1);
		
		#
    	# is_inverse_functional
    	#
		print $output_file_handle "\nis_inverse_functional: true" if ($relationship_type->is_inverse_functional() == 1);

		#
		# created_by
		#
		print $output_file_handle "\ncreated_by: ", $relationship_type->created_by() if (defined $relationship_type->created_by());

		#
		# creation_date
		#
		print $output_file_handle "\ncreation_date: ", $relationship_type->creation_date() if (defined $relationship_type->creation_date());
		
		#
		# modified_by
		#
		print $output_file_handle "\nmodified_by: ", $relationship_type->modified_by() if (defined $relationship_type->modified_by());

		#
		# modification_date
		#
		print $output_file_handle "\nmodification_date: ", $relationship_type->modification_date() if (defined $relationship_type->modification_date());
		
		#
		# is_obsolete
		#
		print $output_file_handle "\nis_obsolete: true" if ($relationship_type->is_obsolete());
		
		#
		# replaced_by
		#
		foreach my $replaced_by ($relationship_type->replaced_by()->get_set()) {
			print $output_file_handle "\nreplaced_by: ", $replaced_by;
		}
		
		#
		# consider
		#
		foreach my $consider ($relationship_type->consider()->get_set()) {
			print $output_file_handle "\nconsider: ", $consider;
		}
		
    	#
    	# is_metadata_tag
    	#
		print $output_file_handle "\nis_metadata_tag: true" if ($relationship_type->is_metadata_tag() == 1);
		
		#
    	# is_class_level
    	#
		print $output_file_handle "\nis_class_level: true" if ($relationship_type->is_class_level() == 1);
		
		#
		# the end...
		#
		print $output_file_handle "\n";
	}
}

=head2 export2rdf

  See - OBO::Core::Ontology::export()
  
=cut

sub export2rdf {
	
	my ($self, $output_file_handle, $error_file_handle, $base, $namespace, $rdf_tc, $skip) = @_;
	
	if ($base && $base !~ /^http/) {
		croak "RDF export: you must provide a valid URL, e.g. export('rdf', \*STDOUT, \*STDERR, 'http://www.cellcycleontology.org/ontology/rdf/')";
	} elsif (!defined $namespace) {
		croak "RDF export: you must provide a valid namespace (e.g. 'SSB')";
	}

	my $default_URL = $base;
	my $NS          = uc ($namespace);
	my $ns          = lc ($namespace);
		
	#
	# Preamble: namespaces
	#
	print $output_file_handle "<?xml version=\"1.0\"?>\n";
	print $output_file_handle "<rdf:RDF\n";
	print $output_file_handle "\txmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"\n";
	print $output_file_handle "\txmlns:rdfs=\"http://www.w3.org/2000/01/rdf-schema#\"\n";
	print $output_file_handle "\txmlns:".$ns."=\"".$default_URL.$NS."#\">\n";
	#######################################################################
	#
	# Terms
	#
	#######################################################################
	my @all_terms = @{$self->get_terms_sorted_by_id()};
	foreach my $term (@all_terms) {
		my $term_id = $term->id();
		# vlmir - the 3 lines below make the export compatible with BFO, CCO and GenXO
		$term_id =~ tr/[_\-]//; # vlmir - trimming  (needed for CCO and GenXO, does not harm anyway)
		$term_id =~ /\A(\w+):/xms; # vlmir
		$1 ? my $rdf_subnamespace = $1:next; # vlmir - bad ID
		$term_id =~ tr/:/_/;
		print $output_file_handle "\t<",$ns,":".$rdf_subnamespace." rdf:about=\"#".$term_id."\">\n";
		
		#
		# is_anonymous
		#
		print $output_file_handle "\t\t<",$ns,":is_anonymous>true</",$ns,":is_anonymous>\n" if ($term->is_anonymous());

		#
		# name
		#
		my $term_name = $term->name();
		my $term_name_to_print = (defined $term_name)?$term_name:'no_name';
		print $output_file_handle "\t\t<rdfs:label xml:lang=\"en\">".&__char_hex_http($term_name_to_print)."</rdfs:label>\n";
			    	
		#
		# alt_id
		#
		foreach my $alt_id ($term->alt_id()->get_set()) {
			print $output_file_handle "\t\t<",$ns,":hasAlternativeId>", $alt_id, "</",$ns,":hasAlternativeId>\n";
		}
 		
 		#
		# builtin
		#
		print $output_file_handle "\t\t<",$ns,":builtin>true</",$ns,":builtin>\n" if ($term->builtin() == 1);
		
		#
		# property_value
		#
		my @property_values = sort {$a->id() cmp $b->id()} $term->property_value()->get_set();
		foreach my $value (@property_values) {
			if (defined $value->head()->instance_of()) {
				print $output_file_handle "\t\t<",$ns,":property_value>\n";
				print $output_file_handle "\t\t\t<rdf:Description>\n";
					print $output_file_handle "\t\t\t\t<",$ns,":property>", $value->type(),'</',$ns,":property>\n";
					print $output_file_handle "\t\t\t\t<",$ns,":value rdf:type=\"",$value->head()->instance_of()->id(),"\">", $value->head()->id(),'</',$ns,":value>\n";
				print $output_file_handle "\t\t\t</rdf:Description>\n";
				print $output_file_handle "\t\t</",$ns,":property_value>";
			} else {
				print $output_file_handle "\t\t<",$ns,":property_value>\n";
				print $output_file_handle "\t\t\t<rdf:Description>\n";
					print $output_file_handle "\t\t\t\t<",$ns,":property>", $value->type(),'</',$ns,":property>\n";
					print $output_file_handle "\t\t\t\t<",$ns,":value>", $value->head()->id(),'</',$ns,":value>\n";
				print $output_file_handle "\t\t\t</rdf:Description>\n";
				print $output_file_handle "\t\t</",$ns,":property_value>";
			}
		}

		#
		# def
		#
		if (defined $term->def()->text()) {
			print $output_file_handle "\t\t<",$ns,":Definition>\n";
			print $output_file_handle "\t\t\t<rdf:Description>\n";
				print $output_file_handle "\t\t\t\t<",$ns,":def>", &__char_hex_http($term->def()->text()), "</",$ns,":def>\n";
				for my $ref ($term->def()->dbxref_set()->get_set()) {
					print $output_file_handle "\t\t\t\t<",$ns,":DbXref>\n";
					print $output_file_handle "\t\t\t\t\t<rdf:Description>\n";
		        		print $output_file_handle "\t\t\t\t\t\t<",$ns,":acc>", $ref->acc(),"</",$ns,":acc>\n";
		        		print $output_file_handle "\t\t\t\t\t\t<",$ns,":dbname>", $ref->db(),"</",$ns,":dbname>\n";
					print $output_file_handle "\t\t\t\t\t</rdf:Description>\n";
					print $output_file_handle "\t\t\t\t</",$ns,":DbXref>\n";
				}

			print $output_file_handle "\t\t\t</rdf:Description>\n";
			print $output_file_handle "\t\t</",$ns,":Definition>\n";
		}
		
		#
		# comment
		#
		if(defined $term->comment()){
			print $output_file_handle "\t\t<rdfs:comment xml:lang=\"en\">".&__char_hex_http($term->comment())."</rdfs:comment>\n";
		}
		
		#
		# subset
		#
		foreach my $sset_name (sort {$a cmp $b} $term->subset()) {
			if ($self->subset_def_map()->contains_key($sset_name)) {
				print $output_file_handle "\t\t<",$ns,":subset>",$sset_name,"</",$ns,":subset>\n";
			} else {
				print $error_file_handle "\nThe term ", $term->id(), " belongs to a non-defined subset ($sset_name).\nYou should add the missing subset definition.\n";
			}
		}

		#
		# synonym
		#
		foreach my $synonym ($term->synonym_set()) {
			print $output_file_handle "\t\t<",$ns,":synonym>\n";
			print $output_file_handle "\t\t\t<rdf:Description>\n";

			print $output_file_handle "\t\t\t\t<",$ns,":syn>", &__char_hex_http($synonym->def()->text()), "</",$ns,":syn>\n";			
		        print $output_file_handle "\t\t\t\t<",$ns,":scope>", $synonym->scope(),"</",$ns,":scope>\n";

				for my $ref ($synonym->def()->dbxref_set()->get_set()) {
					print $output_file_handle "\t\t\t\t<",$ns,":DbXref>\n";
					print $output_file_handle "\t\t\t\t\t<rdf:Description>\n";
		        		print $output_file_handle "\t\t\t\t\t\t<",$ns,":acc>", $ref->acc(),"</",$ns,":acc>\n";
		        		print $output_file_handle "\t\t\t\t\t\t<",$ns,":dbname>", $ref->db(),"</",$ns,":dbname>\n";
					print $output_file_handle "\t\t\t\t\t</rdf:Description>\n";
					print $output_file_handle "\t\t\t\t</",$ns,":DbXref>\n";
				}

			print $output_file_handle "\t\t\t</rdf:Description>\n";
			print $output_file_handle "\t\t</",$ns,":synonym>\n";
		}
    	
		#
		# xref
		#
		my @sorted_xrefs = __sort_by(sub {lc(shift)}, sub { OBO::Core::Dbxref::as_string(shift) }, $term->xref_set_as_string());
		foreach my $xref (@sorted_xrefs) {
			print $output_file_handle "\t\t<",$ns,":xref>\n";
			print $output_file_handle "\t\t\t<rdf:Description>\n";
		        print $output_file_handle "\t\t\t\t<",$ns,":acc>", $xref->acc(),'</',$ns,":acc>\n";
		        print $output_file_handle "\t\t\t\t<",$ns,":dbname>", $xref->db(),'</',$ns,":dbname>\n";
			print $output_file_handle "\t\t\t</rdf:Description>\n";
			print $output_file_handle "\t\t</",$ns,":xref>\n";
		}

		#
		# is_a
		#
		my $rt = $self->get_relationship_type_by_id('is_a');
		if (defined $rt)  {
			print $output_file_handle "\t\t<",$ns,":is_a rdf:resource=\"#", $term_id, "\"/>\n" if ($rdf_tc); # workaround for the rdf_tc!!!
			my %saw_is_a; # avoid duplicated arrows (RelationshipSet?)
			my @sorted_heads = __sort_by_id(sub {lc(shift)}, @{$self->get_head_by_relationship_type($term, $rt)});
			foreach my $head (grep (!$saw_is_a{$_}++, @sorted_heads)) {
				my $head_id = $head->id();
				$head_id =~ tr/:/_/;
				print $output_file_handle "\t\t<",$ns,":is_a rdf:resource=\"#", $head_id, "\"/>\n";
			}
		}
		
		#
		# intersection_of (at least 2 entries)
		#
		foreach my $tr ($term->intersection_of()) {
			# TODO Improve this export
			my $tr_head = $tr->head();
			my $tr_type = $tr->type();
			my $tr_head_id = $tr_head->id();
			$tr_head_id =~ tr/:/_/;

			my $intersection_of_txt  = '';
			$intersection_of_txt    .= $tr_type.' ' if ($tr_type ne 'nil');
			$intersection_of_txt    .= $tr_head_id;
			print $output_file_handle "\t\t<",$ns,":intersection_of rdf:resource=\"#", $intersection_of_txt, "\"/>\n";
		}
		
		#
		# union_of (at least 2 entries)
		#
		foreach my $union_of_term_id ($term->union_of()) {
			$union_of_term_id =~ tr/:/_/;
			print $output_file_handle "\t\t<",$ns,":union_of rdf:resource=\"#", $union_of_term_id, "\"/>\n";
		}
		
		#
		# disjoint_from
		#
		foreach my $disjoint_term_id ($term->disjoint_from()) {
			$disjoint_term_id =~ tr/:/_/;
			print $output_file_handle "\t\t<",$ns,":disjoint_from rdf:resource=\"#", $disjoint_term_id, "\"/>\n";
		}

		#
		# relationship
		#
		foreach my $rt ( @{$self->get_relationship_types_sorted_by_id()} ) {
			my $rt_name = $rt->name();
			if ($rt_name && $rt_name ne 'is_a') { # is_a is printed above
				my $rt_name_clean = __get_name_without_whitespaces($rt_name);
				print $output_file_handle "\t\t<",$ns,":", $rt_name_clean, " rdf:resource=\"#", $term_id, "\"/>\n" if ($rdf_tc && $rt_name_clean eq 'part_of');  # workaround for the rdf_tc!!!
				my %saw_rel; # avoid duplicated arrows (RelationshipSet?)
				my @sorted_heads = __sort_by_id(sub {lc(shift)}, @{$self->get_head_by_relationship_type($term, $rt)});
				foreach my $head (grep (!$saw_rel{$_}++, @sorted_heads)) {
					my $head_id = $head->id();
					$head_id =~ tr/:/_/;
					print $output_file_handle "\t\t<",$ns,":", $rt_name_clean," rdf:resource=\"#", $head_id, "\"/>\n";
				}
			}
		}
				
		#
		# created_by
		#
		print $output_file_handle "\t\t<",$ns,':created_by>', $term->created_by(), '</',$ns,":created_by>\n" if (defined $term->created_by());

		#
		# creation_date
		#
		print $output_file_handle "\t\t<",$ns,':creation_date>', $term->creation_date(), '</',$ns,":creation_date>\n" if (defined $term->creation_date());
			
		#
		# modified_by
		#
		print $output_file_handle "\t\t<",$ns,':modified_by>', $term->modified_by(), '</',$ns,":modified_by>\n" if (defined $term->modified_by());

		#
		# modification_date
		#
		print $output_file_handle "\t\t<",$ns,':modification_date>', $term->modification_date(), '</',$ns,":modification_date>\n" if (defined $term->modification_date());
		
    	#
		# is_obsolete
		#
		print $output_file_handle "\t\t<",$ns,':is_obsolete>true</',$ns,":is_obsolete>\n" if ($term->is_obsolete() == 1);
			
		#
		# replaced_by
		#
		foreach my $replaced_by ($term->replaced_by()->get_set()) {
			print $output_file_handle "\t\t<",$ns,':replaced_by>', $replaced_by, '</',$ns,":replaced_by>\n";
		}
			
		#
		# consider
		#
		foreach my $consider ($term->consider()->get_set()) {
			print $output_file_handle "\t\t<",$ns,':consider>', $consider, '</',$ns,":consider>\n";
		}
		
		# 
		# end of term
		#
		print $output_file_handle "\t</",$ns,":".$rdf_subnamespace.">\n";
	}

	#######################################################################
	#
	# instances
	#
	#######################################################################
	my @all_instances = @{$self->get_instances_sorted_by_id()};
	foreach my $instance (@all_instances) {
		# TODO export instances
	}
	
	#######################################################################
	#
	# relationship types
	#
	#######################################################################
	unless ($skip) { # for integration processes and using biometarel for example.
		my @all_relationship_types = sort values(%{$self->{RELATIONSHIP_TYPES}});
		foreach my $relationship_type (@all_relationship_types) {
			my $relationship_type_id = $relationship_type->id();
			$relationship_type_id =~ tr/:/_/;
			print $output_file_handle "\t<",$ns,":rel_type rdf:about=\"#".$relationship_type_id."\">\n";
			
			#
			# is_anonymous
			#
			print $output_file_handle "\t\t<",$ns,':is_anonymous>true</',$ns,":is_anonymous>\n" if ($relationship_type->is_anonymous());

			#
			# namespace
			#
			foreach my $nspace ($relationship_type->namespace()) {
				print $output_file_handle "\t\t<",$ns,':namespace>', $nspace, '</',$ns,":namespace>\n";
			}
			
			#
			# alt_id
			#
			foreach my $alt_id ($relationship_type->alt_id()->get_set()) {
				print $output_file_handle "\t\t<",$ns,':alt_id>', $alt_id, '</',$ns,":alt_id>\n";
			}
			
			#
			# builtin
			#
			print $output_file_handle "\t\t<",$ns,':builtin>true</',$ns,":builtin>\n" if ($relationship_type->builtin() == 1);
			
			#
			# name
			#
			if (defined $relationship_type->name()) {
				print $output_file_handle "\t\t<rdfs:label xml:lang=\"en\">".&__char_hex_http($relationship_type->name())."</rdfs:label>\n";
			} else {
				print $output_file_handle "\t</",$ns,":rel_type>\n"; # close the relationship type tag! (skipping the rest of the data, contact those guys)
				next;
			}
			
			#
			# def
			#
			if (defined $relationship_type->def()->text()) {
				print $output_file_handle "\t\t<",$ns,":Definition>\n";
				print $output_file_handle "\t\t\t<rdf:Description>\n";
					print $output_file_handle "\t\t\t\t<",$ns,':def>', &__char_hex_http($relationship_type->def()->text()), "</",$ns,":def>\n";
					for my $ref ($relationship_type->def()->dbxref_set()->get_set()) {
						print $output_file_handle "\t\t\t\t<",$ns,":DbXref>\n";
						print $output_file_handle "\t\t\t\t\t<rdf:Description>\n";
			        		print $output_file_handle "\t\t\t\t\t\t<",$ns,':acc>', $ref->acc(),'</',$ns,":acc>\n";
			        		print $output_file_handle "\t\t\t\t\t\t<",$ns,':dbname>', $ref->db(),'</',$ns,":dbname>\n";
						print $output_file_handle "\t\t\t\t\t</rdf:Description>\n";
						print $output_file_handle "\t\t\t\t</",$ns,":DbXref>\n";
					}

				print $output_file_handle "\t\t\t</rdf:Description>\n";
				print $output_file_handle "\t\t</",$ns,":Definition>\n";
			}

			#
			# comment
			#
			if(defined $relationship_type->comment()){
				print $output_file_handle "\t\t<rdfs:comment xml:lang=\"en\">".&__char_hex_http($relationship_type->comment())."</rdfs:comment>\n";
			}
			
			#
			# subset
			#
			foreach my $sset_name ($relationship_type->subset()) {
				if ($self->subset_def_map()->contains_key($sset_name)) {
					print $output_file_handle "\t\t<",$ns,":subset>",$sset_name,"</",$ns,":subset>\n";
				} else {
					print $error_file_handle "\nThe relationship type ", $relationship_type->id(), " belongs to a non-defined subset ($sset_name).\nYou should add the missing subset definition.\n";
				}
			}
						
			#
			# synonym
			#
			foreach my $synonym ($relationship_type->synonym_set()) {
				print $output_file_handle "\t\t<",$ns,":synonym>\n";
				print $output_file_handle "\t\t\t<rdf:Description>\n";

				print $output_file_handle "\t\t\t\t<",$ns,':syn>', &__char_hex_http($synonym->def()->text()), "</",$ns,":syn>\n";			
			        print $output_file_handle "\t\t\t\t<",$ns,':scope>', $synonym->scope(),'</',$ns,":scope>\n";

					for my $ref ($synonym->def()->dbxref_set()->get_set()) {
						print $output_file_handle "\t\t\t\t<",$ns,":DbXref>\n";
						print $output_file_handle "\t\t\t\t\t<rdf:Description>\n";
			        		print $output_file_handle "\t\t\t\t\t\t<",$ns,':acc>', $ref->acc(),'</',$ns,":acc>\n";
			        		print $output_file_handle "\t\t\t\t\t\t<",$ns,':dbname>', $ref->db(),'</',$ns,":dbname>\n";
						print $output_file_handle "\t\t\t\t\t</rdf:Description>\n";
						print $output_file_handle "\t\t\t\t</",$ns,":DbXref>\n";
					}

				print $output_file_handle "\t\t\t</rdf:Description>\n";
				print $output_file_handle "\t\t</",$ns,":synonym>\n";
			}

			#
			# xref
			#
			my @sorted_xrefs = __sort_by(sub {lc(shift)}, sub { OBO::Core::Dbxref::as_string(shift) }, $relationship_type->xref_set_as_string());
			foreach my $xref (@sorted_xrefs) {
				print $output_file_handle "\t\t<",$ns,":xref>\n";
				print $output_file_handle "\t\t\t<rdf:Description>\n";
			        print $output_file_handle "\t\t\t\t<",$ns,':acc>', $xref->acc(),'</',$ns,":acc>\n";
			        print $output_file_handle "\t\t\t\t<",$ns,':dbname>', $xref->db(),'</',$ns,":dbname>\n";
				print $output_file_handle "\t\t\t</rdf:Description>\n";
				print $output_file_handle "\t\t</",$ns,":xref>\n";
			}

			#
			# domain
			#
			foreach my $domain ($relationship_type->domain()->get_set()) {
				print $output_file_handle "\t\t<",$ns,':domain>', $domain, '</',$ns,":domain>\n";
			}
			
			#
			# range
			#
			foreach my $range ($relationship_type->range()->get_set()) {
				print $output_file_handle "\t\t<",$ns,':range>', $range, '</',$ns,":range>\n";
			}

			print $output_file_handle "\t\t<",$ns,':is_anti_symmetric>true</',$ns,":is_anti_symmetric>\n" if ($relationship_type->is_anti_symmetric() == 1);
			print $output_file_handle "\t\t<",$ns,':is_cyclic>true</',$ns,":is_cyclic>\n" if ($relationship_type->is_cyclic() == 1);
			print $output_file_handle "\t\t<",$ns,':is_reflexive>true</',$ns,":is_reflexive>\n" if ($relationship_type->is_reflexive() == 1);
			print $output_file_handle "\t\t<",$ns,':is_symmetric>true</',$ns,":is_symmetric>\n" if ($relationship_type->is_symmetric() == 1);
			print $output_file_handle "\t\t<",$ns,':is_transitive>true</',$ns,":is_transitive>\n" if ($relationship_type->is_transitive() == 1);

			#
			# is_a
			#
			my $rt = $self->get_relationship_type_by_id('is_a');
			if (defined $rt)  {
				my @heads = @{$self->get_head_by_relationship_type($relationship_type, $rt)};
				foreach my $head (@heads) {
					my $head_id = $head->id();
					$head_id =~ tr/:/_/;
					print $output_file_handle "\t\t<",$ns,":is_a rdf:resource=\"#", $head_id, "\"/>\n";
				}
			}
	    	
	    	#
			# intersection_of (at least 2 entries)
			#
			foreach my $tr ($relationship_type->intersection_of()) {
				# TODO Improve this export
				my $tr_head = $tr->head();
				my $tr_type = $tr->type();
				my $tr_head_id = $tr_head->id();
				$tr_head_id =~ tr/:/_/;

				my $intersection_of_txt  = "";
				$intersection_of_txt    .= $tr_type.' ' if ($tr_type ne 'nil');
				$intersection_of_txt    .= $tr_head_id;
				print $output_file_handle "\t\t<",$ns,":intersection_of rdf:resource=\"#", $intersection_of_txt, "\"/>\n";
			}
			
	    	#
			# union_of (at least 2 entries)
			#
			foreach my $union_of_rt_id ($relationship_type->union_of()) {
				$union_of_rt_id =~ tr/:/_/;
				print $output_file_handle "\t\t<",$ns,":union_of rdf:resource=\"#", $union_of_rt_id, "\"/>\n";
			}
		
	    	#
			# disjoint_from
			#
			foreach my $df ($relationship_type->disjoint_from()) {
				print $output_file_handle "\t\t<",$ns,":disjoint_from rdf:resource=\"#", $df, "\"/>\n";
			}

	    	#
			# inverse_of
			#
			my $ir = $relationship_type->inverse_of();
			if (defined $ir) {
				print $output_file_handle "\t\t<",$ns,":inverse_of rdf:resource=\"#", $ir->id(), "\"/>\n";
			}
			
	    	#
			# transitive_over
			#
			foreach my $transitive_over ($relationship_type->transitive_over()->get_set()) {
				print $output_file_handle "\t\t<",$ns,':transitive_over>', $transitive_over, '</',$ns,":transitive_over>\n";
			}
			
			#
			# holds_over_chain
			#
			foreach my $holds_over_chain ($relationship_type->holds_over_chain()) {
				print $output_file_handle "\t\t<",$ns,":holds_over_chain>\n";
				print $output_file_handle "\t\t\t<",$ns,':r1>', @{$holds_over_chain}[0], '</',$ns,":r1>\n";
				print $output_file_handle "\t\t\t<",$ns,':r2>', @{$holds_over_chain}[1], '</',$ns,":r2>\n";
				print $output_file_handle "\t\t<",$ns,":/holds_over_chain>\n";
			}

			#
	    	# is_functional
	    	#
	    	print $output_file_handle "\t\t<",$ns,':is_functional>true</',$ns,":is_functional>\n" if ($relationship_type->is_functional() == 1);
			
			#
	    	# is_inverse_functional
	    	#
			print $output_file_handle "\t\t<",$ns,':is_inverse_functional>true</',$ns,":is_inverse_functional>\n" if ($relationship_type->is_inverse_functional() == 1);
		
			#
			# created_by
			#
			print $output_file_handle "\t\t<",$ns,':created_by>', $relationship_type->created_by(), '</',$ns,":created_by>\n" if (defined $relationship_type->created_by());

			#
			# creation_date
			#
			print $output_file_handle "\t\t<",$ns,':creation_date>', $relationship_type->creation_date(), '</',$ns,":creation_date>\n" if (defined $relationship_type->creation_date());
			
			#
			# modified_by
			#
			print $output_file_handle "\t\t<",$ns,':modified_by>', $relationship_type->modified_by(), '</',$ns,":modified_by>\n" if (defined $relationship_type->modified_by());

			#
			# modification_date
			#
			print $output_file_handle "\t\t<",$ns,':modification_date>', $relationship_type->modification_date(), "</",$ns,":modification_date>\n" if (defined $relationship_type->modification_date());
		
			#
			# is_obsolete
			#
			print $output_file_handle "\t\t<",$ns,':is_obsolete>true</',$ns,":is_obsolete>\n" if ($relationship_type->is_obsolete() == 1);
			
			#
			# replaced_by
			#
			foreach my $replaced_by ($relationship_type->replaced_by()->get_set()) {
				print $output_file_handle "\t\t<",$ns,':replaced_by>', $replaced_by, '</',$ns,":replaced_by>\n";
			}
			
			#
			# consider
			#
			foreach my $consider ($relationship_type->consider()->get_set()) {
				print $output_file_handle "\t\t<",$ns,':consider>', $consider, '</',$ns,":consider>\n";
			}
			
			#
    		# is_metadata_tag
    		#
	    	print $output_file_handle "\t\t<",$ns,':is_metadata_tag>true</',$ns,":is_metadata_tag>\n" if ($relationship_type->is_metadata_tag() == 1);
	    	
	    	#
    		# is_class_level
    		#
	    	print $output_file_handle "\t\t<",$ns,':is_class_level>true</',$ns,":is_class_level>\n" if ($relationship_type->is_class_level() == 1);
	    	
			# 
			# end of relationship type
			#
			print $output_file_handle "\t</",$ns,":rel_type>\n";
		}
	}
	
	#
	# EOF:
	#
	print $output_file_handle "</rdf:RDF>\n\n";
	print $output_file_handle "<!--\nGenerated with ONTO-PERL ($VERSION): ".$0.", ".__date()."\n-->";
}

=head2 export2owl

  See - OBO::Core::Ontology::export()
  
=cut

sub export2owl {
	
	my ($self, $output_file_handle, $error_file_handle, $oboContentUrl, $oboInOwlUrl) = @_;
	
	if ($oboContentUrl !~ /^http/) {
		croak "OWL export: you must provide a valid URL, e.g. export('owl', \*STDOUT, \*STDERR, 'http://www.cellcycleontology.org/ontology/owl/')";
	}
	
	if ($oboInOwlUrl !~ /^http/) {
		( $oboInOwlUrl = $oboContentUrl ) =~ s{/\w+/owl/\z}{/formats/oboInOwl#}xms;
		warn "Using a default URI for OboInOwl '$oboInOwlUrl' ";
	}

	#
	# preambule
	#
	print $output_file_handle '<?xml version="1.0"?>'                                        ."\n";
	print $output_file_handle '<rdf:RDF'                                                     ."\n";
	print $output_file_handle "\t".'xmlns="'.$oboContentUrl.'"'                              ."\n";
	print $output_file_handle "\t".'xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"' ."\n";
	print $output_file_handle "\t".'xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"'      ."\n";
	print $output_file_handle "\t".'xmlns:owl="http://www.w3.org/2002/07/owl#"'              ."\n";
	print $output_file_handle "\t".'xmlns:xsd="http://www.w3.org/2001/XMLSchema#"'           ."\n";
	print $output_file_handle "\t".'xmlns:oboInOwl="'.$oboInOwlUrl.'"'                       ."\n";
	print $output_file_handle "\t".'xmlns:oboContent="'.$oboContentUrl.'"'                   ."\n";
	
	my $ontology_id_space = $self->id() || $self->get_terms_idspace();
	print $output_file_handle "\t".'xml:base="'.$oboContentUrl.$ontology_id_space.'"'        ."\n";

	#print $output_file_handle "\txmlns:p1=\"http://protege.stanford.edu/plugins/owl/dc/protege-dc.owl#\"\n";
	#print $output_file_handle "\txmlns:dcterms=\"http://purl.org/dc/terms/\"\n";
	#print $output_file_handle "\txmlns:xsp=\"http://www.owl-ontologies.com/2005/08/07/xsp.owl#\"\n";
	#print $output_file_handle "\txmlns:dc=\"http://purl.org/dc/elements/1.1/\"\n";
	
	print $output_file_handle '>'."\n"; # rdf:RDF

	#
	# meta-data: oboInOwl elements
	#
	foreach my $ap ('hasURI', 'hasAlternativeId', 'hasDate', 'hasVersion', 'hasDbXref', 'hasDefaultNamespace', 'hasNamespace', 'hasDefinition', 'hasExactSynonym', 'hasNarrowSynonym', 'hasBroadSynonym', 'hasRelatedSynonym', 'hasSynonymType', 'hasSubset', 'inSubset', 'savedBy', 'replacedBy', 'consider') {
		print $output_file_handle "<owl:AnnotationProperty rdf:about=\"".$oboInOwlUrl.$ap."\"/>\n";
	}
	foreach my $c ('DbXref', 'Definition', 'Subset', 'Synonym', 'SynonymType', 'ObsoleteClass') {
		print $output_file_handle "<owl:Class rdf:about=\"".$oboInOwlUrl.$c."\"/>\n";
	}
	print $output_file_handle "<owl:ObjectProperty rdf:about=\"".$oboInOwlUrl."ObsoleteProperty\"/>\n";
	print $output_file_handle "\n";

	#
	# header: http://oe0.spreadsheets.google.com/ccc?id=o06770842196506107736.4732937099693365844.03735622766900057712.3276521997699206495#
	#
	print $output_file_handle "<owl:Ontology rdf:about=\"\">\n";
	foreach my $import_obo ($self->imports()->get_set()) {
		# As Ontology.pm is independant of the format (OBO, OWL) it will import the ID of the ontology
		(my $import_owl = $import_obo) =~ s/\.obo/\.owl/;
		print $output_file_handle "\t<owl:imports rdf:resource=\"", $import_owl, "\"/>\n";
	}
	# format-version is not treated
	print $output_file_handle "\t<oboInOwl:hasDate>", $self->date(), "</oboInOwl:hasDate>\n" if ($self->date());
	print $output_file_handle "\t<oboInOwl:hasDate>", $self->data_version(), "</oboInOwl:hasDate>\n" if ($self->data_version());
	print $output_file_handle '\t\t<oboInOwl:ontology>', $self->id(), "</oboInOwl:ontology>\n" if ($self->id());
	print $output_file_handle "\t<oboInOwl:savedBy>", $self->saved_by(), "</oboInOwl:savedBy>\n" if ($self->saved_by());
	#print $output_file_handle "\t<rdfs:comment>autogenerated-by: ", $0, "</rdfs:comment>\n";
	print $output_file_handle "\t<oboInOwl:hasDefaultRelationshipIDPrefix>", $self->default_relationship_id_prefix(), "</oboInOwl:hasDefaultRelationshipIDPrefix>\n" if ($self->default_relationship_id_prefix());
	print $output_file_handle "\t<oboInOwl:hasDefaultNamespace>", $self->default_namespace(), "</oboInOwl:hasDefaultNamespace>\n" if ($self->default_namespace());
	foreach my $remark ($self->remarks()->get_set()) {
		print $output_file_handle "\t<rdfs:comment>", $remark, "</rdfs:comment>\n";
	}
	
	# treat-xrefs-as-equivalent
	foreach my $id_space_xref_eq (sort {lc($a) cmp lc($b)} $self->treat_xrefs_as_equivalent()->get_set()) {
		print $output_file_handle '\t\t<oboInOwl:treat-xrefs-as-equivalent>', $id_space_xref_eq, "</oboInOwl:treat-xrefs-as-equivalent>\n";
	}
	
	# treat_xrefs_as_is_a
	foreach my $id_space_xref_eq (sort {lc($a) cmp lc($b)} $self->treat_xrefs_as_is_a()->get_set()) {
		print $output_file_handle '\t\t<oboInOwl:treat-xrefs-as-is_a>', $id_space_xref_eq, "</oboInOwl:treat-xrefs-as-is_a>\n";
	}
		
	# subsetdef
	foreach my $subsetdef (sort {lc($a->name()) cmp lc($b->name())} $self->subset_def_map()->values()) {
		print $output_file_handle "\t<oboInOwl:hasSubset>\n";
		print $output_file_handle "\t\t<oboInOwl:Subset rdf:about=\"", $oboContentUrl, $subsetdef->name(), "\">\n";
		print $output_file_handle "\t\t\t<rdfs:comment rdf:datatype=\"http://www.w3.org/2001/XMLSchema#string\">", $subsetdef->description(), "</rdfs:comment>\n";
		print $output_file_handle "\t\t</oboInOwl:Subset>\n";
		print $output_file_handle "\t</oboInOwl:hasSubset>\n";
	}
 
	# synonyntypedef
	foreach my $st ($self->synonym_type_def_set()->get_set()) {
		print $output_file_handle "\t<oboInOwl:hasSynonymType>\n";
		print $output_file_handle "\t\t<oboInOwl:SynonymType rdf:about=\"", $oboContentUrl, $st->name(), "\">\n";
		print $output_file_handle "\t\t\t<rdfs:comment rdf:datatype=\"http://www.w3.org/2001/XMLSchema#string\">", $st->description(), "</rdfs:comment>\n";
		my $scope = $st->scope();
		print $output_file_handle "\t\t\t<rdfs:comment rdf:datatype=\"http://www.w3.org/2001/XMLSchema#string\">", $scope, "</rdfs:comment>\n" if (defined $scope);
		print $output_file_handle "\t\t</oboInOwl:SynonymType>\n";
		print $output_file_handle "\t</oboInOwl:hasSynonymType>\n";
	}
	
	# idspace
	my $ids = $self->idspaces()->get_set();
	my $local_idspace = undef;
	if (defined $ids) {
		$local_idspace = $ids->local_idspace(); 
		if ($local_idspace) {
			print $output_file_handle "\t<oboInOwl:IDSpace>\n";
			print $output_file_handle "\t\t<oboInOwl:local>\n";
			print $output_file_handle "\t\t\t<rdfs:comment rdf:datatype=\"http://www.w3.org/2001/XMLSchema#string\">", $local_idspace, "</rdfs:comment>\n";
			print $output_file_handle "\t\t</oboInOwl:local>\n";
			print $output_file_handle "\t\t<oboInOwl:global>\n";
			print $output_file_handle "\t\t\t<rdfs:comment rdf:datatype=\"http://www.w3.org/2001/XMLSchema#string\">", $self->idspace()->uri(), "</rdfs:comment>\n";
			print $output_file_handle "\t\t</oboInOwl:global>\n";
			my $desc = $ids->description();
			print $output_file_handle "\t\t<rdfs:comment rdf:datatype=\"http://www.w3.org/2001/XMLSchema#string\">", $desc, "</rdfs:comment>\n";
			print $output_file_handle "\t</oboInOwl:IDSpace>\n";
		}
	}
	
	# Ontology end tag
	print $output_file_handle "</owl:Ontology>\n\n";
		
	#######################################################################
	#
	# term
	#
	#######################################################################
	my @all_terms = @{$self->get_terms_sorted_by_id()};
	# visit the terms
	foreach my $term (@all_terms){
		
		# for the URLs
		my $term_id = $term->id();
		$local_idspace = $local_idspace || (split(':', $term_id))[0]; # the idspace or the space from the term itself. e.g. APO
	
		#
		# Class name
		#
		print $output_file_handle "<owl:Class rdf:about=\"", $oboContentUrl, $local_idspace, "#", obo_id2owl_id($term_id), "\">\n";
		
		#
		# label name = class name
		#
		print $output_file_handle "\t<rdfs:label xml:lang=\"en\">", &__char_hex_http($term->name()), "</rdfs:label>\n" if ($term->name());
		
		#
		# comment
		#
		print $output_file_handle "\t<rdfs:comment rdf:datatype=\"http://www.w3.org/2001/XMLSchema#string\">", $term->comment(), "</rdfs:comment>\n" if ($term->comment());
		
		#
		# subset
		#
		foreach my $sset_name (sort {$a cmp $b} $term->subset()) {
			if ($self->subset_def_map()->contains_key($sset_name)) {
				print $output_file_handle "\t<oboInOwl:inSubset rdf:resource=\"", $oboContentUrl, &__get_name_without_whitespaces($sset_name), "\"/>\n";
			} else {
				print $error_file_handle "\nThe term ", $term->id(), " belongs to a non-defined subset ($sset_name).\nYou should add the missing subset definition.\n";
			}
		}
			
		#
		# Def
		#      
		if (defined $term->def()->text()) {
			print $output_file_handle "\t<oboInOwl:hasDefinition>\n";
			print $output_file_handle "\t\t<oboInOwl:Definition>\n";
			print $output_file_handle "\t\t\t<rdfs:label xml:lang=\"en\">", &__char_hex_http($term->def()->text()), "</rdfs:label>\n";
			
			__print_hasDbXref_for_owl($output_file_handle, $term->def()->dbxref_set(), $oboContentUrl, 3);
			
			print $output_file_handle "\t\t</oboInOwl:Definition>\n";
			print $output_file_handle "\t</oboInOwl:hasDefinition>\n";
		}
		
		#
		# synonym:
		#
		foreach my $synonym ($term->synonym_set()) {
			my $st = $synonym->scope();
			my $synonym_type;
			if ($st eq 'EXACT') {
				$synonym_type = 'hasExactSynonym';
			} elsif ($st eq 'BROAD') {
				$synonym_type = 'hasBroadSynonym';
			} elsif ($st eq 'NARROW') {
				$synonym_type = 'hasNarrowSynonym';
			} elsif ($st eq 'RELATED') {
				$synonym_type = 'hasRelatedSynonym';
			} else {
				# TODO Consider the synonym types defined in the header: 'synonymtypedef' tag
				croak 'A non-valid synonym type has been found ($synonym). Valid types: EXACT, BROAD, NARROW, RELATED';
			}
			print $output_file_handle "\t<oboInOwl:", $synonym_type, ">\n";
			print $output_file_handle "\t\t<oboInOwl:Synonym>\n";
			print $output_file_handle "\t\t\t<rdfs:label xml:lang=\"en\">", $synonym->def()->text(), "</rdfs:label>\n";
			
			__print_hasDbXref_for_owl($output_file_handle, $synonym->def()->dbxref_set(), $oboContentUrl, 3);
			
			print $output_file_handle "\t\t</oboInOwl:Synonym>\n";
			print $output_file_handle "\t</oboInOwl:", $synonym_type, ">\n";
		}
			
		#
		# namespace
		#
		foreach my $ns ($term->namespace()) {
			print $output_file_handle "\t<oboInOwl:hasOBONamespace>", $ns, "</oboInOwl:hasOBONamespace>\n";
		}

		#
		# alt_id:
		#
		foreach my $alt_id ($term->alt_id()->get_set()) {
			print $output_file_handle "\t<oboInOwl:hasAlternativeId>", $alt_id, "</oboInOwl:hasAlternativeId>\n";
		}

		#
		# xref's
		#
		__print_hasDbXref_for_owl($output_file_handle, $term->xref_set(), $oboContentUrl, 1);
    	
		#
		# is_a:
		#
#			my @disjoint_term = (); # for collecting the disjoint terms of the running term
		my $rt = $self->get_relationship_type_by_id('is_a');
		if (defined $rt)  {
		    		my %saw_is_a; # avoid duplicated arrows (RelationshipSet?)
		    		my @sorted_heads = __sort_by_id(sub {lc(shift)}, @{$self->get_head_by_relationship_type($term, $rt)});
		    		foreach my $head (grep (!$saw_is_a{$_}++, @sorted_heads)) {
						print $output_file_handle "\t<rdfs:subClassOf rdf:resource=\"", $oboContentUrl, $local_idspace, '#', obo_id2owl_id($head->id()), "\"/>\n"; # head->name() not used
		    		
#					#
#					# Gathering for the Disjointness (see below, after the bucle)
#					#
#		#			my $child_rels = $graph->get_child_relationships($rel->object_acc);
#		#			foreach my $r (@{$child_rels}){
#		#				if ($r->scope eq 'is_a') { # Only consider the children playing a role in the is_a realtionship
#		#					my $already_in_array = grep /$r->subject_acc/, @disjoint_term;
#		#					push @disjoint_term, $r->subject_acc if (!$already_in_array && $r->subject_acc ne $rel->subject_acc());
#		#				}
#		#			}

					}
#				#
#				# Disjointness (array filled up while treating the is_a relation)
#				#
#				#	foreach my $disjoint (@disjoint_term){
#				#		$disjoint =~ tr/:/_/;
#				#		print $output_file_handle "\t<owl:disjointWith rdf:resource=\"#", $disjoint, "\"/>\n";
#				#	}
		}
		#
		# intersection_of
		#
		my @intersection_of = $term->intersection_of();
		if (@intersection_of) {
			print $output_file_handle "\t<owl:equivalentClass>\n";
			print $output_file_handle "\t\t<owl:Class>\n";
			print $output_file_handle "\t\t\t<owl:intersectionOf rdf:parseType=\"Collection\">\n";
			foreach my $tr (@intersection_of) {
				# TODO Improve the parsing of the 'interection_of' elements
				my @inter = split(/\s+/, $tr);
				# TODO Check the idspace of the terms in the set 'intersection_of' and optimize the code: only one call to $self->idspace()->local_idspace()
				my $idspace = ($tr =~ /([A-Z]+):/)?$1:$local_idspace;      
				if (scalar @inter == 1) {
					my $idspace = ($tr =~ /([A-Z]+):/)?$1:$local_idspace;
					print $output_file_handle "\t\t\t<owl:Class rdf:about=\"", $oboContentUrl, $idspace, "/", obo_id2owl_id($tr), "\"/>\n";
				} elsif (scalar @inter == 2) { # restriction
					print $output_file_handle "\t\t<owl:Restriction>\n";
					print $output_file_handle "\t\t\t<owl:onProperty>\n";
					print $output_file_handle "\t\t\t\t<owl:ObjectProperty rdf:about=\"", $oboContentUrl, $local_idspace, "#", $inter[0], "\"/>\n";
					print $output_file_handle "\t\t\t</owl:onProperty>\n";
					print $output_file_handle "\t\t\t<owl:someValuesFrom rdf:resource=\"", $oboContentUrl, $local_idspace, "#", obo_id2owl_id($inter[1]), "\"/>\n";
					print $output_file_handle "\t\t</owl:Restriction>\n";
				} else {
					croak "Parsing error: 'intersection_of' tag has an unknown argument";
				}
			}
			print $output_file_handle "\t\t\t</owl:intersectionOf>\n";
			print $output_file_handle "\t\t</owl:Class>\n";
			print $output_file_handle "\t</owl:equivalentClass>\n";
		}
			
		#
		# union_of
		#
		my @union_of = $term->union_of();
		if (@union_of) {
			print $output_file_handle "\t<owl:equivalentClass>\n";
			print $output_file_handle "\t\t<owl:Class>\n";
			print $output_file_handle "\t\t\t<owl:unionOf rdf:parseType=\"Collection\">\n";
			foreach my $tr (@union_of) {
				# TODO Check the idspace of the terms in the set 'union_of'
				my $idspace = ($tr =~ /([A-Z]+):/)?$1:$local_idspace; 
				print $output_file_handle "\t\t\t<owl:Class rdf:about=\"", $oboContentUrl, $idspace, "/", obo_id2owl_id($tr), "\"/>\n";
			}
			print $output_file_handle "\t\t\t</owl:unionOf>\n";
			print $output_file_handle "\t\t</owl:Class>\n";
			print $output_file_handle "\t</owl:equivalentClass>\n";
		}
		
		#
		# disjoint_from:
		#
		foreach my $disjoint_term_id ($term->disjoint_from()) {
			print $output_file_handle "\t<owl:disjointWith rdf:resource=\"", $oboContentUrl, $local_idspace, "#", obo_id2owl_id($disjoint_term_id), "\"/>\n";
		}
					
		#	
		# relationships:
		#
		foreach $rt ( @{$self->get_relationship_types_sorted_by_id()} ) {
			if ($rt->id() ne 'is_a') { # is_a is printed above
				my %saw_rel; # avoid duplicated arrows (RelationshipSet?)
				my @sorted_heads = __sort_by_id(sub {lc(shift)}, @{$self->get_head_by_relationship_type($term, $rt)});
				foreach my $head (grep (!$saw_rel{$_}++, @sorted_heads)) {
					print $output_file_handle "\t<rdfs:subClassOf>\n";
					print $output_file_handle "\t\t<owl:Restriction>\n";
					print $output_file_handle "\t\t\t<owl:onProperty>\n"; 
					print $output_file_handle "\t\t\t\t<owl:ObjectProperty rdf:about=\"", $oboContentUrl, $local_idspace, "#", $rt->id(), "\"/>\n";
					print $output_file_handle "\t\t\t</owl:onProperty>\n";
					print $output_file_handle "\t\t\t<owl:someValuesFrom rdf:resource=\"", $oboContentUrl, $local_idspace, "#", obo_id2owl_id($head->id()), "\"/>\n"; # head->name() not used
					print $output_file_handle "\t\t</owl:Restriction>\n";
					print $output_file_handle "\t</rdfs:subClassOf>\n";
				}
			}
		}
	
		#
		# obsolete
		#
		print $output_file_handle "\t<rdfs:subClassOf rdf:resource=\"", $oboInOwlUrl, "ObsoleteClass\"/>\n" if ($term->is_obsolete());
	
		#
		# builtin:
		#
		#### Not used in OWL.####
			
		#
		# replaced_by
		#
		foreach my $replaced_by ($term->replaced_by()->get_set()) {
			print $output_file_handle "\t<oboInOwl:replacedBy rdf:resource=\"", $oboContentUrl, $local_idspace, "#", obo_id2owl_id($replaced_by), "\"/>\n";
		}
		
		#
		# consider
		#
		foreach my $consider ($term->consider()->get_set()) {
			print $output_file_handle "\t<oboInOwl:consider rdf:resource=\"", $oboContentUrl, $local_idspace, "#", obo_id2owl_id($consider), "\"/>\n";
		}

		#
   		# End of the term
   		#
		print $output_file_handle "</owl:Class>\n\n";
	}
		
	#
	# relationship types: properties
	#
	# TODO
#		print $output_file_handle "<owl:TransitiveProperty rdf:about=\"", $oboContentUrl, "part_of\">\n";
# 		print $output_file_handle "\t<rdfs:label xml:lang=\"en\">part of</rdfs:label>\n";
#		print $output_file_handle "\t<oboInOwl:hasNamespace>", $self->default_namespace(), "</oboInOwl:hasNamespace>\n" if ($self->default_namespace());
#		print $output_file_handle "</owl:TransitiveProperty>\n";
		
	foreach my $relationship_type ( @{$self->get_relationship_types_sorted_by_id()} ) {

		my $relationship_type_id = $relationship_type->id();

		next if ($relationship_type_id eq 'is_a'); # rdfs:subClassOf covers this property (relationship)
			
		#
		# Object property
		#
		print $output_file_handle "<owl:ObjectProperty rdf:about=\"", $oboContentUrl, $local_idspace, "#", $relationship_type_id, "\">\n";
		
		#
		# name:
		#
		my $relationship_type_name = $relationship_type->name();
		if (defined $relationship_type_name) {
			print $output_file_handle "\t<rdfs:label xml:lang=\"en\">", $relationship_type_name, "</rdfs:label>\n";
		}
		
		#
		# comment:
		#
		print $output_file_handle "\t<rdfs:comment rdf:datatype=\"http://www.w3.org/2001/XMLSchema#string\">", $relationship_type->comment(), "</rdfs:comment>\n" if ($relationship_type->comment());
		
		#
		# Def:
		#
		if (defined $relationship_type->def()->text()) {
			print $output_file_handle "\t<oboInOwl:hasDefinition>\n";
			print $output_file_handle "\t\t<oboInOwl:Definition>\n";
			print $output_file_handle "\t\t\t<rdfs:label xml:lang=\"en\">", &__char_hex_http($relationship_type->def()->text()), "</rdfs:label>\n";
			
			__print_hasDbXref_for_owl($output_file_handle, $relationship_type->def()->dbxref_set(), $oboContentUrl, 3);
			
			print $output_file_handle "\t\t</oboInOwl:Definition>\n";
			print $output_file_handle "\t</oboInOwl:hasDefinition>\n";
		}
			
		#
		# Synonym:
		#
		foreach my $synonym ($relationship_type->synonym_set()) {
			my $st = $synonym->scope();
			my $synonym_type;
			if ($st eq 'EXACT') {
				$synonym_type = 'hasExactSynonym';
			} elsif ($st eq 'BROAD') {
				$synonym_type = 'hasBroadSynonym';
			} elsif ($st eq 'NARROW') {
				$synonym_type = 'hasNarrowSynonym';
			} elsif ($st eq 'RELATED') {
				$synonym_type = 'hasRelatedSynonym';
			} else {
				# TODO Consider the synonym types defined in the header: 'synonymtypedef' tag
				croak 'A non-valid synonym type has been found ($synonym). Valid types: EXACT, BROAD, NARROW, RELATED';
			}
			print $output_file_handle "\t<oboInOwl:", $synonym_type, ">\n";
			print $output_file_handle "\t\t<oboInOwl:Synonym>\n";
			print $output_file_handle "\t\t\t<rdfs:label xml:lang=\"en\">", $synonym->def()->text(), "</rdfs:label>\n";
			
			__print_hasDbXref_for_owl($output_file_handle, $synonym->def()->dbxref_set(), $oboContentUrl, 3);
			
			print $output_file_handle "\t\t</oboInOwl:Synonym>\n";
			print $output_file_handle "\t</oboInOwl:", $synonym_type, ">\n";
		}
		#
		# namespace: TODO implement namespace in relationship
		#
		foreach my $ns ($relationship_type->namespace()) {
			print $output_file_handle "\t<oboInOwl:hasOBONamespace>", $ns, "</oboInOwl:hasOBONamespace>\n";
		}
			
		#
		# alt_id: TODO implement alt_id in relationship
		#
		foreach my $alt_id ($relationship_type->alt_id()->get_set()) {
			print $output_file_handle "\t<oboInOwl:hasAlternativeId>", $alt_id, "</oboInOwl:hasAlternativeId>\n";
		}
		
		#
		# is_a:
		#
		my $rt = $self->get_relationship_type_by_id('is_a');
		if (defined $rt)  {
	    		my @sorted_heads = __sort_by_id(sub {lc(shift)}, @{$self->get_head_by_relationship_type($relationship_type, $rt)});
	    		foreach my $head (@sorted_heads) {
					print $output_file_handle "\t<rdfs:subPropertyOf rdf:resource=\"", $oboContentUrl, $local_idspace, "#", obo_id2owl_id($head->id()), "\"/>\n"; # head->name() not used
	    		}
		}
		
		#
		# Properties:
		#
		print $output_file_handle "\t<rdf:type rdf:resource=\"http://www.w3.org/2002/07/owl#TransitiveProperty\"/>\n" if ($relationship_type->is_transitive());
		print $output_file_handle "\t<rdf:type rdf:resource=\"http://www.w3.org/2002/07/owl#SymmetricProperty\"/>\n" if ($relationship_type->is_symmetric()); # No cases so far
		print $output_file_handle "\t<rdf:type rdf:resource=\"http://www.w3.org/2002/07/owl#AnnotationProperty\"/>\n" if ($relationship_type->is_metadata_tag());
		print $output_file_handle "\t<rdf:type rdf:resource=\"http://www.w3.org/2002/07/owl#AnnotationProperty\"/>\n" if ($relationship_type->is_class_level());
		#print $output_file_handle "\t<is_reflexive rdf:datatype=\"http://www.w3.org/2001/XMLSchema#string\">true</is_reflexive>\n" if ($relationship_type->is_reflexive());
		#print $output_file_handle "\t<is_anti_symmetric rdf:datatype=\"http://www.w3.org/2001/XMLSchema#string\">true</is_anti_symmetric>\n" if ($relationship_type->is_anti_symmetric()); # anti-symmetric <> not symmetric
		
		#
		# xref's
		#
		__print_hasDbXref_for_owl($output_file_handle, $relationship_type->xref_set(), $oboContentUrl, 1);
			
		## There is no way to code these rel's in OBO
		##print $output_file_handle "\t<rdf:type rdf:resource=\"&owl;FunctionalProperty\"/>\n" if (${$relationship{$_}}{"TODO"});
		##print $output_file_handle "\t<rdf:type rdf:resource=\"&owl;InverseFunctionalProperty\"/>\n" if (${$relationship{$_}}{"TODO"});
		##print $output_file_handle "\t<owl:inverseOf rdf:resource=\"#has_authors\"/>\n" if (${$relationship{$_}}{"TODO"});
		print $output_file_handle "</owl:ObjectProperty>\n\n";
		
		#
		# replaced_by
		#
		foreach my $replaced_by ($relationship_type->replaced_by()->get_set()) {
			print $output_file_handle "\t<oboInOwl:replacedBy rdf:resource=\"", $oboContentUrl, $local_idspace, "#", obo_id2owl_id($replaced_by), "\"/>\n";
		}
		
		#
		# consider
		#
		foreach my $consider ($relationship_type->consider()->get_set()) {
			print $output_file_handle "\t<oboInOwl:consider rdf:resource=\"", $oboContentUrl, $local_idspace, "#", obo_id2owl_id($consider), "\"/>\n";
		}
	}	
#				
#		#
#		# Datatype annotation properties: todo: AnnotationProperty or not?
#		#
#
#		# autoGeneratedBy
#		#print $output_file_handle "<owl:DatatypeProperty rdf:ID=\"autoGeneratedBy\">\n";
#		#print $output_file_handle "\t<rdf:type rdf:resource=\"http://www.w3.org/2002/07/owl#AnnotationProperty\"/>\n";
#		#print $output_file_handle "\t<rdfs:range rdf:resource=\"http://www.w3.org/2001/XMLSchema#string\"/>\n";
#		#print $output_file_handle "\t<rdfs:comment rdf:datatype=\"http://www.w3.org/2001/XMLSchema#string\">", "The program that generated this ontology.", "</rdfs:comment>\n";
#		#print $output_file_handle "</owl:DatatypeProperty>\n\n";
#		
#		# is_anti_symmetric
#		print $output_file_handle "<owl:DatatypeProperty rdf:ID=\"is_anti_symmetric\">\n";
#		print $output_file_handle "\t<rdf:type rdf:resource=\"http://www.w3.org/2002/07/owl#AnnotationProperty\"/>\n";
#		print $output_file_handle "</owl:DatatypeProperty>\n\n";
#		
#		# is_reflexive
#		print $output_file_handle "<owl:DatatypeProperty rdf:ID=\"is_reflexive\">\n";
#		print $output_file_handle "\t<rdf:type rdf:resource=\"http://www.w3.org/2002/07/owl#AnnotationProperty\"/>\n";
#		print $output_file_handle "</owl:DatatypeProperty>\n\n";
		
	#
	# EOF:
	#
	print $output_file_handle "</rdf:RDF>\n\n";
	print $output_file_handle "<!--\nGenerated with ONTO-PERL ($VERSION): ".$0.", ".__date()."\n-->";
}

=head2 export2xml

  See - OBO::Core::Ontology::export()
  
=cut

sub export2xml {
	
	my ($self, $output_file_handle, $error_file_handle) = @_;
	
	# terms
	my @all_terms = @{$self->get_terms_sorted_by_id()};
    
    # terms idspace
    my $NS = lc ($self->get_terms_idspace());
    
	# preambule: OBO header tags
	print $output_file_handle "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\n";
	print $output_file_handle "<".$NS.">\n";
	
	print $output_file_handle "\t<header>\n";
	print $output_file_handle "\t\t<format-version>1.4</format-version>\n";

	my $data_version = $self->data_version();
	print $output_file_handle "\t\t<data-version>", $data_version, "</data-version>\n" if ($data_version);
	
	my $ontology_id_space = $self->id();
	print $output_file_handle '\t\t<ontology>', $ontology_id_space, "</ontology>\n" if ($ontology_id_space);
	
	chomp(my $date = (defined $self->date())?$self->date():__date()); #`date '+%d:%m:%Y %H:%M'`);
	print $output_file_handle "\t\t<date>", $date, "</date>\n";
	
	my $saved_by = $self->saved_by();
	print $output_file_handle "\t\t<saved-by>", $saved_by, "</saved-by>\n" if ($saved_by);

	print $output_file_handle "\t\t<auto-generated-by>ONTO-PERL ", $VERSION, "</auto-generated-by>\n";
	
	# import
	foreach my $import ($self->imports()->get_set()) {
		print $output_file_handle "\t\t<import>", $import, "</import>\n";
	}
	
	# subsetdef
	foreach my $subsetdef (sort {lc($a->name()) cmp lc($b->name())} $self->subset_def_map()->values()) {
		print $output_file_handle "\t\t<subsetdef>\n";
		print $output_file_handle "\t\t\t<name>", $subsetdef->name(), "</name>\n";
		print $output_file_handle "\t\t\t<description>", $subsetdef->description(), "</description>\n";
		print $output_file_handle "\t\t</subsetdef>\n";
	}
	
	# synonyntypedef
	foreach my $st ($self->synonym_type_def_set()->get_set()) {
		print $output_file_handle "\t\t<synonymtypedef>\n";
		print $output_file_handle "\t\t\t<name>", $st->name(), "</name>\n";
		print $output_file_handle "\t\t\t<scope>", $st->scope(), "</scope>\n";
		print $output_file_handle "\t\t\t<description>", $st->description(), "</description>\n";
		print $output_file_handle "\t\t</synonymtypedef>\n";
	}

	# idspace's		
	foreach my $idspace ($self->idspaces()->get_set()) {
		print $output_file_handle "\t\t<idspace>", $idspace->as_string(), "</idspace>\n";
	}
	
	# default_relationship_id_prefix
	my $dris = $self->default_relationship_id_prefix();
	print $output_file_handle "\t\t<default-relationship-id-prefix>", $dris, "</default-relationship-id-prefix>\n" if (defined $dris);
	
	# default_namespace
	my $dns = $self->default_namespace();
	print $output_file_handle "\t\t<default-namespace>", $dns, "</default-namespace>\n" if (defined $dns);
	
	# remark's
	foreach my $remark ($self->remarks()->get_set()) {
		print $output_file_handle "\t\t<remark>", $remark, "</remark>\n";
	}
	
	# treat-xrefs-as-equivalent
	foreach my $id_space_xref_eq (sort {lc($a) cmp lc($b)} $self->treat_xrefs_as_equivalent()->get_set()) {
		print $output_file_handle '\t\t<treat-xrefs-as-equivalent>', $id_space_xref_eq, "</treat-xrefs-as-equivalent>\n";
	}
	
	# treat_xrefs_as_is_a
	foreach my $id_space_xref_eq (sort {lc($a) cmp lc($b)} $self->treat_xrefs_as_is_a()->get_set()) {
		print $output_file_handle '\t\t<treat-xrefs-as-is_a>', $id_space_xref_eq, "</treat-xrefs-as-is_a>\n";
	}
		
	print $output_file_handle "\t</header>\n\n";
	
	#######################################################################
	#
	# terms
	#
	#######################################################################
	foreach my $term (@all_terms) {
		#
		# [Term]
		#
		print $output_file_handle "\t<term>\n";
    	
		#
		# id
		#
		print $output_file_handle "\t\t<id>", $term->id(), "</id>\n";
		
		#
		# is_anonymous
		#
		print $output_file_handle "\t\t<is_anonymous>true</is_anonymous>\n" if ($term->is_anonymous());
    	
		#
		# name
		#
		print $output_file_handle "\t\t<name>", &__char_hex_http($term->name()), "</name>\n" if (defined $term->name());
    	
    	#
		# namespace
		#
		foreach my $ns ($term->namespace()) {
			print $output_file_handle "\t\t<namespace>", $ns, "</namespace>\n";
		}
    	
		#
		# alt_id
		#
		foreach my $alt_id ($term->alt_id()->get_set()) {
			print $output_file_handle "\t\t<alt_id>", $alt_id, "</alt_id>\n";
		}

		#
		# builtin
		#
		print $output_file_handle "\t\t<builtin>true</builtin>\n" if ($term->builtin() == 1);
		
		#
		# property_value
		#
		my @property_values = sort {$a->id() cmp $b->id()} $term->property_value()->get_set();
		foreach my $value (@property_values) {
			if (defined $value->head()->instance_of()) {
				print $output_file_handle "\t\t<property_value>\n";
					print $output_file_handle "\t\t\t<property>", $value->type(),"</property>\n";
					print $output_file_handle "\t\t\t<value rdf:type=\"",$value->head()->instance_of()->id(),"\">", $value->head()->id(),"</value>\n";
				print $output_file_handle "\t\t</property_value>";
			} else {
				print $output_file_handle "\t\t<property_value>\n";
					print $output_file_handle "\t\t\t<property>", $value->type(),"</:property>\n";
					print $output_file_handle "\t\t\t<value>", $value->head()->id(),"</value>\n";
				print $output_file_handle "\t\t</property_value>";
			}
	    	# TODO Finalise this implementation
			print $output_file_handle "\t\t<property_value type=".$value->type().'>'.$value->head()->id()."</property_value>\n";
		}

		#
		# def
		#
		my $term_def = $term->def();
		if (defined $term_def->text()) {
			print $output_file_handle "\t\t<def>\n";
			print $output_file_handle "\t\t\t<def_text>", &__char_hex_http($term_def->text()), "</def_text>\n";				
			for my $ref ($term_def->dbxref_set()->get_set()) {
		        print $output_file_handle "\t\t\t<dbxref xref=\"", $ref->name(), "\">\n";
		        print $output_file_handle "\t\t\t\t<acc>", $ref->acc(),"</acc>\n";
		        print $output_file_handle "\t\t\t\t<dbname>", $ref->db(),"</dbname>\n";
		        print $output_file_handle "\t\t\t</dbxref>\n";
			}
			print $output_file_handle "\t\t</def>\n";
		}
		
		#
		# comment
		#
		my $comment = $term->comment();
		print $output_file_handle "\t\t<comment>", &__char_hex_http($comment), "</comment>\n" if (defined $comment);

		#
		# subset
		#
		foreach my $sset_name (sort {$a cmp $b} $term->subset()) {
			if ($self->subset_def_map()->contains_key($sset_name)) {
				print $output_file_handle "\t\t<subset>", $sset_name, "</subset>\n";
			} else {
				print $error_file_handle "\nThe term ", $term->id(), " belongs to a non-defined subset ($sset_name).\nYou should add the missing subset definition.\n";
			}
		}

		#
		# synonym:
		#
		foreach my $synonym ($term->synonym_set()) {
			print $output_file_handle "\t\t<synonym>\n";
			print $output_file_handle "\t\t\t<syn_text>", &__char_hex_http($synonym->def()->text()), "</syn_text>\n";
		    print $output_file_handle "\t\t\t<scope>", $synonym->scope(),"</scope>\n";
			for my $ref ($synonym->def()->dbxref_set()->get_set()) {
				print $output_file_handle "\t\t\t<DbXref>\n";
		        	print $output_file_handle "\t\t\t\t<acc>", $ref->acc(),"</acc>\n";
		        	print $output_file_handle "\t\t\t\t<dbname>", $ref->db(),"</dbname>\n";
				print $output_file_handle "\t\t\t</DbXref>\n";
			}
			print $output_file_handle "\t\t</synonym>\n";
		}

		#
		# xref
		#
		my @sorted_xrefs = __sort_by(sub {lc(shift)}, sub { OBO::Core::Dbxref::as_string(shift) }, $term->xref_set_as_string());
		foreach my $xref (@sorted_xrefs) {
			print $output_file_handle "\t\t<xref>", $xref->as_string(), "</xref>\n";
		}
					
		#
		# is_a
		#
		my $rt = $self->get_relationship_type_by_id('is_a');
		if (defined $rt)  {
			my %saw_is_a; # avoid duplicated arrows (RelationshipSet?)
			my @sorted_heads = __sort_by_id(sub {lc(shift)}, @{$self->get_head_by_relationship_type($term, $rt)});
			foreach my $head (grep (!$saw_is_a{$_}++, @sorted_heads)) {
				my $head_name = $head->name();
				my $head_name_to_print = (defined $head_name)?$head_name:"no_name";
				print $output_file_handle "\t\t<is_a id=\"".$head->id()."\">".$head_name_to_print."</is_a>\n";
			}
		}
		
		#
		# intersection_of (at least 2 entries)
		#
		foreach my $tr ($term->intersection_of()) {
			# TODO Improve this export
			my $tr_head = $tr->head();
			my $tr_type = $tr->type();
			my $tr_head_id = $tr_head->id();
			$tr_head_id =~ tr/:/_/;
				my $intersection_of_txt  = "";
			$intersection_of_txt    .= $tr_type.' ' if ($tr_type ne 'nil');
			$intersection_of_txt    .= $tr_head_id;
			print $output_file_handle "\t\t<intersection_of>", $intersection_of_txt, "</intersection_of>\n";
		}

		#
		# union_of (at least 2 entries)
		#
		foreach my $union_of_term_id ($term->union_of()) {
			$union_of_term_id =~ tr/:/_/;
			print $output_file_handle "\t\t<union_of>", $union_of_term_id, "</union_of>\n";
		}
			
		#
		# disjoint_from:
		#
		foreach my $disjoint_term_id ($term->disjoint_from()) {
			print $output_file_handle "\t\t<disjoint_from>", $disjoint_term_id, "</disjoint_from>\n";
		}
					
		#
		# relationship
		#
		foreach $rt ( @{$self->get_relationship_types_sorted_by_id()} ) {
			if ($rt->name() ne 'is_a') { # is_a is printed above
				my %saw_rel; # avoid duplicated arrows (RelationshipSet?)
				my @sorted_heads = __sort_by_id(sub {lc(shift)}, @{$self->get_head_by_relationship_type($term, $rt)});
				foreach my $head (grep (!$saw_rel{$_}++, @sorted_heads)) {
					print $output_file_handle "\t\t<relationship>\n";
					print $output_file_handle "\t\t\t<type>", $rt->name(), "</type>\n";
					print $output_file_handle "\t\t\t<target id=\"", $head->id(), "\">", $head->name(),"</target>\n";
					print $output_file_handle "\t\t</relationship>\n";
				}
			}
		}

		#
		# created_by
		#
		print $output_file_handle "\t\t<created_by>", $term->created_by(), "</created_by>\n" if (defined $term->created_by());

		#
		# creation_date
		#
		print $output_file_handle "\t\t<creation_date>", $term->creation_date(), "</creation_date>\n" if (defined $term->creation_date());
		
		#
		# modified_by
		#
		print $output_file_handle "\t\t<modified_by>", $term->modified_by(), "</modified_by>\n" if (defined $term->modified_by());

		#
		# modification_date
		#
		print $output_file_handle "\t\t<modification_date>", $term->modification_date(), "</modification_date>\n" if (defined $term->modification_date());
		
		#
		# is_obsolete
		#
		print $output_file_handle "\t\t<is_obsolete>true</is_obsolete>\n" if ($term->is_obsolete());

		#
		# replaced_by
		#
		foreach my $replaced_by ($term->replaced_by()->get_set()) {
			print $output_file_handle "\t\t<replaced_by>", $replaced_by, "</replaced_by>\n";
		}
		
		#
		# consider
		#
		foreach my $consider ($term->consider()->get_set()) {
			print $output_file_handle "\t\t<consider>", $consider, "</consider>\n";
		}

		#
		# end
		#
		print $output_file_handle "\t</term>\n\n";
	}
	
	#######################################################################
	#
	# instances
	#
	#######################################################################
	my @all_instances = @{$self->get_instances_sorted_by_id()};
	foreach my $instance (@all_instances) {
		# TODO export instances
	}
	
	#######################################################################
	#
	# relationship types
	#
	#######################################################################
	foreach my $relationship_type ( @{$self->get_relationship_types_sorted_by_id()} ) {
		print $output_file_handle "\t<typedef>\n";
		
		#
		# id
		#
		print $output_file_handle "\t\t<id>", $relationship_type->id(), "</id>\n";
		
		#
		# is_anonymous
		#
		print $output_file_handle "\t\t<is_anonymous>true</is_anonymous>\n" if ($relationship_type->is_anonymous());
		
		#
		# name
		#
		my $relationship_type_name = $relationship_type->name();
		if (defined $relationship_type_name) {
			print $output_file_handle "\t\t<name>", &__char_hex_http($relationship_type_name), "</name>\n";
		}
		
		#
		# namespace
		#
		foreach my $nasp ($relationship_type->namespace()) {
			print $output_file_handle "\t\t<namespace>", $nasp, "</namespace>\n";
		}
		
		#
		# alt_id
		#
		foreach my $alt_id ($relationship_type->alt_id()->get_set()) {
			print $output_file_handle "\t\t<alt_id>", $alt_id, "</alt_id>\n";
		}
		
		#
		# builtin
		#
		print $output_file_handle "\t\t<builtin>true</builtin>\n" if ($relationship_type->builtin() == 1);
		
		#
		# def
		#
		my $relationship_type_def = $relationship_type->def();
		if (defined $relationship_type_def->text()) {
			print $output_file_handle "\t\t<def label=\"", &__char_hex_http($relationship_type_def->text()), "\">\n";				
			for my $ref ($relationship_type_def->dbxref_set()->get_set()) {
		        print $output_file_handle "\t\t\t<dbxref xref=\"", $ref->name(), "\">\n";
		        print $output_file_handle "\t\t\t\t<acc>", $ref->acc(),"</acc>\n";
		        print $output_file_handle "\t\t\t\t<dbname>", $ref->db(),"</dbname>\n";
		        print $output_file_handle "\t\t\t</dbxref>\n";
			}
			print $output_file_handle "\t\t</def>\n";
		}
		
		#
		# comment
		#
		print $output_file_handle "\t\t<comment>", &__char_hex_http($relationship_type->comment()), "</comment>\n" if (defined $relationship_type->comment());
		
		#
		# subset
		#
		foreach my $sset_name ($relationship_type->subset()) {
			if ($self->subset_def_map()->contains_key($sset_name)) {
				print $output_file_handle "\t\t<subset>",$sset_name,"</subset>\n";
			} else {
				print $error_file_handle "\nThe relationship type ", $relationship_type->id(), " belongs to a non-defined subset ($sset_name).\nYou should add the missing subset definition.\n";
			}
		}
					
		#
		# synonym
		#
		foreach my $rt_synonym ($relationship_type->synonym_set()) {
			print $output_file_handle "\t\t<synonym>\n";
			print $output_file_handle "\t\t\t<syn_text>", &__char_hex_http($rt_synonym->def()->text()), "</syn_text>\n";			
		    print $output_file_handle "\t\t\t<scope>", $rt_synonym->scope(),"</scope>\n";
			for my $ref ($rt_synonym->def()->dbxref_set()->get_set()) {
				print $output_file_handle "\t\t\t<DbXref>\n";
		        	print $output_file_handle "\t\t\t\t<acc>", $ref->acc(),"</acc>\n";
		        	print $output_file_handle "\t\t\t\t<dbname>", $ref->db(),"</dbname>\n";
				print $output_file_handle "\t\t\t</DbXref>\n";
			}
			print $output_file_handle "\t\t</synonym>\n";
		}
		
		#
		# xref
		#
		my @sorted_xrefs = __sort_by(sub {lc(shift)}, sub { OBO::Core::Dbxref::as_string(shift) }, $relationship_type->xref_set_as_string());
		foreach my $xref (@sorted_xrefs) {
			print $output_file_handle "\t\t<xref>", $xref->as_string(), "</xref>\n";
		}
		
		#
		# domain
		#
		foreach my $domain ($relationship_type->domain()->get_set()) {
			print $output_file_handle "\t\t<domain>", $domain, "</domain>\n";
		}
		
		#
		# range
		#
		foreach my $range ($relationship_type->range()->get_set()) {
			print $output_file_handle "\t\t<range>", $range, "</range>\n";
		}
		
		print $output_file_handle "\t\t<is_anti_symmetric>true</is_anti_symmetric>\n" if ($relationship_type->is_anti_symmetric() == 1);
		print $output_file_handle "\t\t<is_cyclic>true</is_cyclic>\n" if ($relationship_type->is_cyclic() == 1);
		print $output_file_handle "\t\t<is_reflexive>true</is_reflexive>\n" if ($relationship_type->is_reflexive() == 1);
		print $output_file_handle "\t\t<is_symmetric>true</is_symmetric>\n" if ($relationship_type->is_symmetric() == 1);
		print $output_file_handle "\t\t<is_transitive>true</is_transitive>\n" if ($relationship_type->is_transitive() == 1);
		
		#
		# is_a: TODO missing function to retieve the rel types 
		#
		my $rt = $self->get_relationship_type_by_id('is_a');
		if (defined $rt)  {
			my @heads = @{$self->get_head_by_relationship_type($relationship_type, $rt)};
			foreach my $head (@heads) {
				print $output_file_handle "\t\t<is_a>", $head->id(), "</is_a>\n";
			}
		}
		
		#
		# intersection_of (at least 2 entries)
		#
		foreach my $tr ($relationship_type->intersection_of()) {
			# TODO Improve this export
			my $tr_head = $tr->head();
			my $tr_type = $tr->type();
			my $tr_head_id = $tr_head->id();
			$tr_head_id =~ tr/:/_/;
				my $intersection_of_txt  = "";
			$intersection_of_txt    .= $tr_type.' ' if ($tr_type ne 'nil');
			$intersection_of_txt    .= $tr_head_id;
			print $output_file_handle "\t\t<intersection_of>", $intersection_of_txt, "</intersection_of>\n";
		}
		
		#
		# union_of (at least 2 entries)
		#
		foreach my $union_of_rt_id ($relationship_type->union_of()) {
			$union_of_rt_id =~ tr/:/_/;
			print $output_file_handle "\t\t<union_of>", $union_of_rt_id, "</union_of>\n";
		}
			
		#
		# disjoint_from
		#
		my $df = $relationship_type->disjoint_from();
		if (defined $df) {
			print $output_file_handle "\t\t<disjoint_from>", $df, "</disjoint_from>\n";
		}
		
		#
		# inverse_of
		#
		my $ir = $relationship_type->inverse_of();
		if (defined $ir) {
			print $output_file_handle "\t\t<inverse_of>", $ir->id(), "</inverse_of>\n";
		}
		
    	#
		# transitive_over
		#
		foreach my $transitive_over ($relationship_type->transitive_over()->get_set()) {
			print $output_file_handle "\t\t<transitive_over>", $transitive_over, "</transitive_over>\n";
		}
		
		#
		# holds_over_chain
		#
		foreach my $holds_over_chain ($relationship_type->holds_over_chain()) {
			print $output_file_handle "\t\t<holds_over_chain>\n";
			print $output_file_handle "\t\t\t<r1>", @{$holds_over_chain}[0], "</r1>\n";
			print $output_file_handle "\t\t\t<r2>", @{$holds_over_chain}[1], "</r2>\n";
			print $output_file_handle "\t\t</holds_over_chain>\n";
		}

		#
	    # is_functional
	    #
	    print $output_file_handle "\t\t<is_functional>true</is_functional>\n" if ($relationship_type->is_functional() == 1);
			
		#
	    # is_inverse_functional
	    #
		print $output_file_handle "\t\t<is_inverse_functional>true</is_inverse_functional>\n" if ($relationship_type->is_inverse_functional() == 1);
			
		#
		# created_by
		#
		print $output_file_handle "\t\t<created_by>", $relationship_type->created_by(), "</created_by>\n" if (defined $relationship_type->created_by());

		#
		# creation_date
		#
		print $output_file_handle "\t\t<creation_date>", $relationship_type->creation_date(), "</creation_date>\n" if (defined $relationship_type->creation_date());
		
		#
		# is_obsolete
		#
		print $output_file_handle "\t\t<is_obsolete>true</is_obsolete>\n" if ($relationship_type->is_obsolete());
		
		#
		# replaced_by
		#
		foreach my $replaced_by ($relationship_type->replaced_by()->get_set()) {
			print $output_file_handle "\t\t<replaced_by>", $replaced_by, "</replaced_by>\n";
		}
		
		#
		# consider
		#
		foreach my $consider ($relationship_type->consider()->get_set()) {
			print $output_file_handle "\t\t<consider>", $consider, "</consider>\n";
		}
    	
    	#
    	# is_metadata_tag
    	#
		print $output_file_handle "\t\t<is_metadata_tag>true</is_metadata_tag>\n" if ($relationship_type->is_metadata_tag() == 1);
		
		#
    	# is_class_level
    	#
		print $output_file_handle "\t\t<is_class_level>true</is_class_level>\n" if ($relationship_type->is_class_level() == 1);
		
		#
		# end typedef
		#
		print $output_file_handle "\t</typedef>\n\n";
	}
	print $output_file_handle "</".$NS.">\n";	
}

=head2 export2dot

  See - OBO::Core::Ontology::export()
  
=cut

sub export2dot {
	
	my ($self, $output_file_handle, $error_file_handle) = @_;
	
	#
	# begin DOT format
	#
	print $output_file_handle 'digraph Ontology {';
	print $output_file_handle "\n\tpage=\"11,17\";";
	#print $output_file_handle "\n\tratio=auto;";
    	
	# terms
	my @all_terms = @{$self->get_terms_sorted_by_id()};
	print $output_file_handle "\n\tedge [label=\"is a\"];";
	foreach my $term (@all_terms) {
    	
		my $term_id = $term->id();
    	
		#
		# is_a: term1 -> term2
		#
		my $rt = $self->get_relationship_type_by_id('is_a');
		if (defined $rt)  {
			my %saw_is_a; # avoid duplicated arrows (RelationshipSet?)
			my @sorted_heads = __sort_by_id(sub {lc(shift)}, @{$self->get_head_by_relationship_type($term, $rt)});
			foreach my $head (grep (!$saw_is_a{$_}++, @sorted_heads)) {
				if (!defined $term->name()) {
					warn 'Warning: The term with id: ', $term_id, ' has no name!' ;
				} elsif (!defined $head->name()) {
					warn 'Warning: The term with id: ', $head->id(), ' has no name!' ;
				} else {
					# TODO Write down the name() instead of the id()
					print $output_file_handle "\n\t", obo_id2owl_id($term_id), ' -> ', obo_id2owl_id($head->id()), ';';
				}
			}
		}	    	
		#
		# relationships: terms1 -> term2
		#
		foreach $rt ( @{$self->get_relationship_types_sorted_by_id()} ) {
			if ($rt->name() ne 'is_a') { # is_a is printed above
				my @heads = @{$self->get_head_by_relationship_type($term, $rt)};
				print $output_file_handle "\n\tedge [label=\"", $rt->name(), "\"];" if (@heads);
				my %saw_rel; # avoid duplicated arrows (RelationshipSet?)
				my @sorted_heads = __sort_by_id(sub {lc(shift)}, @heads);
				foreach my $head (grep (!$saw_rel{$_}++, @sorted_heads)) {
					if (!defined $term->name()) {
			    		warn 'Warning: The term with id: ', $term_id, ' has no name!' ;
			    	} elsif (!defined $head->name()) {
			    		warn 'Warning: The term with id: ', $head->id(), ' has no name!' ;
			    	} else {	
						print $output_file_handle "\n\t", obo_id2owl_id($term_id), ' -> ', obo_id2owl_id($head->id()), ';';
					}
				}
			}
		}
	}
    
	#
	# end DOT format
	#
	print $output_file_handle "\n}";
}

=head2 export2gml

  See - OBO::Core::Ontology::export()
  
=cut

sub export2gml {
	
	my ($self, $output_file_handle, $error_file_handle) = @_;
	
	#
	# begin GML format
	#
	print $output_file_handle "Creator \"ONTO-PERL, $VERSION\"\n";
	print $output_file_handle "Version	1.0\n";
	print $output_file_handle "graph [\n";
	#print $output_file_handle "\tVendor \"ONTO-PERL\"\n";
	#print $output_file_handle "\tdirected 1\n";
	#print $output_file_handle "\tcomment 1"
	#print $output_file_handle "\tlabel 1"
    	
	my %id = ('C'=>1, 'P'=>2, 'F'=>3, 'R'=>4, 'T'=>5, 'I'=>6, 'B'=>7, 'U'=>8, 'G'=>9, 'X'=>4);
	my %color_id = ('C'=>'fff5f5', 'P'=>'b7ffd4', 'F'=>'d7ffe7', 'R'=>'ceffe1', 'T'=>'ffeaea', 'I'=>'f4fff8', 'B'=>'f0fff6', 'G'=>'f0fee6', 'U'=>'e0ffec', 'X'=>'ffcccc', 'Y'=>'fecccc');
	my %gml_id;
	# terms
	my @all_terms = @{$self->get_terms_sorted_by_id()};
	foreach my $term (@all_terms) {
	    	
		my $term_id = $term->id();
		#
		# Class name
		#
		print $output_file_handle "\tnode [\n";
		my $term_sns = $term->subnamespace();
		$term_sns    = 'X' if !$term_sns;
		my $id = $id{$term_sns};
		$gml_id{$term_id} = 100000000 * (defined($id)?$id:1) + $term->code();
		#$id{$term->id()} = $gml_id;
		print $output_file_handle "\t\troot_index	-", $gml_id{$term_id}, "\n";
		print $output_file_handle "\t\tid			-", $gml_id{$term_id}, "\n";
		print $output_file_handle "\t\tgraphics	[\n";
		#print $output_file_handle "\t\t\tx	1656.0\n";
		#print $output_file_handle "\t\t\ty	255.0\n";
		print $output_file_handle "\t\t\tw	40.0\n";
		print $output_file_handle "\t\t\th	40.0\n";
		print $output_file_handle "\t\t\tfill	\"#".$color_id{$term_sns}."\"\n" if $color_id{$term_sns};
		print $output_file_handle "\t\t\toutline	\"#000000\"\n";
		print $output_file_handle "\t\t\toutline_width	1.0\n";
		print $output_file_handle "\t\t]\n";
		print $output_file_handle "\t\tlabel		\"", $term_id, "\"\n";
		print $output_file_handle "\t\tname		\"", $term->name(), "\"\n";
		print $output_file_handle "\t\tcomment		\"", $term->def()->text(), "\"\n" if (defined $term->def()->text());
		print $output_file_handle "\t]\n";
			
    	#
    	# relationships: terms1 -> term2
    	#
    	foreach my $rt ( @{$self->get_relationship_types_sorted_by_id()} ) {
			my %saw_rel; # avoid duplicated arrows (RelationshipSet?)
			my @sorted_heads = __sort_by_id(sub {lc(shift)}, @{$self->get_head_by_relationship_type($term, $rt)});
			foreach my $head (grep (!$saw_rel{$_}++, @sorted_heads)) {
				if (!defined $term->name()) {
			   		croak 'The term with id: ', $term_id, ' has no name!' ;
			   	} elsif (!defined $head->name()) {
			   		croak 'The term with id: ', $head->id(), ' has no name!' ;
			   	} else {
		    		print $output_file_handle "\tedge [\n";
		    		print $output_file_handle "\t\troot_index	-", $gml_id{$term_id}, "\n";
	    			print $output_file_handle "\t\tsource		-", $gml_id{$term_id}, "\n";
	    			$gml_id{$head->id()} = 100000000 * (defined($id{$head->subnamespace()})?$id{$head->subnamespace()}:1) + $head->code();
	    			print $output_file_handle "\t\ttarget		-", $gml_id{$head->id()}, "\n";
	    			print $output_file_handle "\t\tlabel		\"", $rt->name(),"\"\n";
	    			print $output_file_handle "\t]\n";
				}
			}
		}
	}
	    
	#
	# end GML format
	#
	print $output_file_handle "\n]";
}

=head2 export

  Usage    - $ontology->export($export_format, $output_file_handle, $error_file_handle)
  Returns  - exports this ontology
  Args     - the format: obo, xml, owl, dot, gml, xgmml, sbml
           - the output file handle (e.g. STDOUT), and
           - the error file handle (STDERR by default; if not writable, STDOUT is used)
  Function - exports this ontology
  Remark   - warning and errors are printed to the STDERR (by default)
  Remark   - you may use this method to check your OBO file syntax and/or to clean it up
  Remark   - Standard arguments:
           -   1. Format, one of 'obo', 'rdf', 'xml', 'owl', 'dot', 'gml', 'xgmml', 'sbml'
           -   2. Otput filehandle \*OUT
           -   3. Error filehandle \*ERR ( default \*STDERR, but for RDF or OWL )
           - Extra arguments:
           -   'rdf':
           -     1. base URI (e.g. 'http://www.semantic-systems-biology.org/')
           -     2. name space (e.g. 'SSB')
           -     3. Flag, 1=construct closures, 0=no closures (default)
           -     4. Flag, 1=skip exporting Typedefs, 0=export Typedefs (default)
           -   'owl':
           -     1. URI for content
           -     2. URI for OboInOwl (optional)
           -     3. note: the OWL export is broken!

=cut

sub export {
	
	my $self   = shift;
	my $format = lc(shift);
    
	my $possible_formats = OBO::Util::Set->new();
	$possible_formats->add_all('obo', 'rdf', 'xml', 'owl', 'dot', 'gml', 'xgmml', 'sbml');
	if (!$possible_formats->contains($format)) {
		croak "The export format must be one of the following: 'obo', 'rdf', 'xml', 'owl', 'dot', 'gml', 'xgmml', 'sbml'";
	}
	
	my $stderr_fh          = \*STDERR;
	my $output_file_handle = shift;
	my $error_file_handle  = shift || $stderr_fh;
	
    # check the file_handle's
	if (!-w $output_file_handle) {
		croak "export: you must provide a valid output handle, e.g. export('$format', \\*STDOUT)";
	} elsif (!-e $error_file_handle) {
		croak "export: you must provide a valid error handle, e.g. export('$format', \\*STDOUT, \\*STDERR)";
	}
	
	if (($error_file_handle eq $stderr_fh) && (!-w $error_file_handle)) {
		$error_file_handle = $output_file_handle;
		# TODO A few CPAN test platforms (e.g. solaris) don't have this handle open for testing 
		#warn  "export: the STDERR is not writable!";
	}

	if ($format eq 'obo') {
		
		$self->export2obo($output_file_handle, $error_file_handle);
		
	} elsif ($format eq 'rdf') {
		
		my $base      = shift;
		my $namespace = shift;		
		my $rdf_tc    = shift || 0; # Set this according to your needs: 1=reflexive relations for each term
		my $skip      = shift || 0; # Set this according to your needs: 1=skip exporting the rel types, 0=do not skip (default)
	
		$self->export2rdf($output_file_handle, $error_file_handle, $base, $namespace, $rdf_tc, $skip);
		
	} elsif ($format eq 'xml') {
		
		$self->export2xml($output_file_handle, $error_file_handle);
		
	} elsif ($format eq 'owl') {

		my $oboContentUrl = shift; # e.g. 'http://www.cellcycleontology.org/ontology/owl/'; # "http://purl.org/obo/owl/"; 
		my $oboInOwlUrl   = shift; # e.g. 'http://www.cellcycleontology.org/formats/oboInOwl#'; # "http://www.geneontology.org/formats/oboInOwl#";

		$self->export2owl($output_file_handle, $error_file_handle, $oboContentUrl, $oboInOwlUrl);
		
	} elsif ($format eq 'dot') {
		
		$self->export2dot($output_file_handle, $error_file_handle);
		
	} elsif ($format eq 'gml') {
		
		$self->export2gml($output_file_handle, $error_file_handle);
		
	} elsif ($format eq 'xgmml') {
		warn 'Not implemented yet';
	} elsif ($format eq 'sbml') {
		warn 'Not implemented yet';
	}
    
    return 0;
}

=head2 subontology_by_terms

  Usage    - $ontology->subontology_by_terms($term_set)
  Returns  - a subontology with the given terms from this ontology 
  Args     - the terms (OBO::Util::TermSet) that will be included in the subontology
  Function - creates a subontology based on the given terms from this ontology
  Remark   - instances of terms (classes) are added to the resulting ontology
  
=cut

sub subontology_by_terms {
	my ($self, $term_set) = @_;

	# Future improvement: performance of this algorithm
	my $result = OBO::Core::Ontology->new();
	foreach my $term ($term_set->get_set()) {
		#
		# add term
		#
		if (!$result->has_term($term)) {
			$result->add_term($term);              # add term
			foreach my $ins ($term->class_of()->get_set()) {
				$result->add_instance($ins);       # add its instances
			}
		}
		
		#
		# add descendents
		#
		foreach my $descendent (@{$self->get_descendent_terms($term)}) {
			if (!$result->has_term($descendent)) {
				$result->add_term($descendent);              # add descendent
				foreach my $ins ($descendent->class_of()->get_set()) {
					$result->add_instance($ins);             # add its instances
				}
			}
		}
		#
		# rel's
		#
		foreach my $rel (@{$self->get_relationships_by_target_term($term)}){
			$result->add_relationship($rel);
			my $rel_type = $self->get_relationship_type_by_id($rel->type());
			$result->has_relationship_type($rel_type) || $result->add_relationship_type($rel_type);
		}
	}
	return $result;
}

=head2 get_subontology_from

  Usage    - $ontology->get_subontology_from($new_root_term) or $ontology->get_subontology_from($new_root_term, $rel_type_ids)
  Returns  - a subontology of this ontology starting at the given term (new root) 
  Args     - the term (OBO::Core::Term) that will be the root of the subontology, and optionally, a reference (hash) to relationship type ids ($relationship_type_id, $relationship_type_name)
  Function - creates a subontology having as root the given term
  
=cut

sub get_subontology_from {
	my ($self, 
	    $root_term,
	    $rel_type_ids # vlmir - ref {relationsship type id => relationship type name}; optional
	) = @_;
	
	my $result = OBO::Core::Ontology->new();
	if ($root_term) {
		$self->has_term($root_term) || croak "The term '", $root_term,"' does not belong to this ontology";

		$result->data_version($self->data_version());
		$result->id($self->id());
		$result->imports($self->imports()->get_set());
		$result->idspaces($self->idspaces()->get_set());
		$result->subset_def_map($self->subset_def_map()); # add (by default) all the subset_def_map's
		$result->synonym_type_def_set($self->synonym_type_def_set()->get_set()); # add all synonym_type_def_set by default
		$result->default_relationship_id_prefix($self->default_relationship_id_prefix());
		$result->default_namespace($self->default_namespace());
		$result->remarks($self->remarks()->get_set());
		$result->treat_xrefs_as_equivalent($self->treat_xrefs_as_equivalent->get_set());
		$result->treat_xrefs_as_is_a($self->treat_xrefs_as_is_a->get_set());
		
		if ( $rel_type_ids ) { # vlmir
			foreach my $rel_type_id ( sort keys %{$rel_type_ids} ) {
				$result->add_relationship_type_as_string( $rel_type_id, $rel_type_ids->{$rel_type_id} );
			} # vlmir
		}
		
		my @queue = ($root_term);
		while (scalar(@queue) > 0) {
			my $unqueued = shift @queue;
			$result->add_term($unqueued);
			foreach my $rel (@{$self->get_relationships_by_target_term($unqueued)}){
				if ( $rel_type_ids ) { # vlmir					
					$rel_type_ids->{$rel->type()} ? $result->add_relationship($rel) : next;					
				} else { # vlmir
					$result->add_relationship($rel);
					my $rel_type = $self->get_relationship_type_by_id($rel->type()); # vlmir OBO::Core::RelationshipType
					$result->has_relationship_type($rel_type) || $result->add_relationship_type($rel_type);
				}
			}
			my @children = @{$self->get_child_terms($unqueued)};
			@queue = (@queue, @children);
		}
	}
	return $result;
}

=head2 get_terms_idspace

  Usage    - $ontology->get_terms_idspace()
  Returns  - the idspace (e.g. GO) of the terms held by this ontology (or 'NN' is there is no idspace)
  Args     - none
  Function - look for the idspace of the terms held by this ontology
  Remark   - it is assumed that most of the terms share the same idspace (e.g. GO)
  
=cut

sub get_terms_idspace {
	my ($self) = @_;
	if ($self->id()) {
		return $self->id();
	} else {
		# TODO Find an efficient way to get it...
		#my $is = (sort values(%{$self->{TERMS}}))[0]->idspace();
		my $NS = undef;
		my @all_terms = __sort_by_id(sub {shift}, values(%{$self->{TERMS}}));
		foreach my $term (@all_terms) {
			$NS = $term->idspace();
			last if(defined $NS);
		}
		return ($NS)?$NS:'NN';
	}
}

=head2 get_instances_idspace

  Usage    - $ontology->get_instances_idspace()
  Returns  - the idspace (e.g. GO) of the instances held by this ontology (or 'NN' is there is no idspace)
  Args     - none
  Function - look for the idspace of the instances held by this ontology
  Remark   - it is assumed that most of the instances share the same idspace (e.g. GO)
  
=cut

sub get_instances_idspace {
	my ($self) = @_;
	if ($self->id()) {
		return $self->id();
	} else {
		# TODO Find an efficient way to get it...
		#my $is = (sort values(%{$self->{INSTANCES}}))[0]->idspace();
		my $NS = undef;
		my @all_instances = sort values(%{$self->{INSTANCES}});
		foreach my $instance (@all_instances) {
			$NS = $instance->idspace();
			last if(defined $NS);
		}
		return ($NS)?$NS:'NN';
	}
}

=head2 get_descendent_terms

  Usage    - $ontology->get_descendent_terms($term) or $ontology->get_descendent_terms($term_id)
  Returns  - a set with the descendent terms (OBO::Core::Term) of the given term
  Args     - the term, as an object (OBO::Core::Term) or string (e.g. GO:0003677), for which all the descendents will be found
  Function - returns recursively all the child terms of the given term
  
=cut

sub get_descendent_terms {
	my ($self, $term) = @_;
	my $result = OBO::Util::TermSet->new();
	if ($term) {
		if (!eval { $term->isa('OBO::Core::Term') }) {
			# term is a string representing its (unique) ID (e.g. GO:0034544)
			$term = $self->get_term_by_id($term);
		}
		my @queue = @{$self->get_child_terms($term)};
		while (scalar(@queue) > 0) {
			my $unqueued = pop @queue;
			$result->add($unqueued); 
			my @children = @{$self->get_child_terms($unqueued)};
			@queue = (@children, @queue);
		}
	}
	my @arr = $result->get_set();
	return \@arr;
}

=head2 get_ancestor_terms

  Usage    - $ontology->get_ancestor_terms($term)
  Returns  - a set with the ancestor terms (OBO::Core::Term) of the given term
  Args     - the term (OBO::Core::Term) for which all the ancestors will be found
  Function - returns recursively all the parent terms of the given term
  
=cut

sub get_ancestor_terms {
	my ($self, $term) = @_;
	my $result = OBO::Util::TermSet->new();
	if ($term) {
		my @queue = @{$self->get_parent_terms($term)};
		while (scalar(@queue) > 0) {
			my $unqueued = pop @queue;
			$result->add($unqueued);
			my @parents = @{$self->get_parent_terms($unqueued)};
			@queue = (@parents, @queue);
		}
	}
	my @arr = $result->get_set();
	return \@arr;
}

=head2 get_descendent_terms_by_subnamespace

  Usage    - $ontology->get_descendent_terms_by_subnamespace($term, subnamespace)
  Returns  - a set with the descendent terms (OBO::Core::Term) of the given subnamespace 
  Args     - the term (OBO::Core::Term), the subnamespace (string, e.g. 'P', 'R', 'Ia' etc)
  Function - returns recursively the given term's children of the given subnamespace
  
=cut

sub get_descendent_terms_by_subnamespace {
	my $self = shift;
	my $result = OBO::Util::TermSet->new();
	if (@_) {
		my ($term, $subnamespace) = @_;
		my @queue = @{$self->get_child_terms($term)};
		while (scalar(@queue) > 0) {
			my $unqueued = shift @queue;
			$result->add($unqueued) if substr($unqueued->id(), 4, length($subnamespace)) eq $subnamespace;
			my @children = @{$self->get_child_terms($unqueued)};
			@queue = (@queue, @children);
		}
	}
	my @arr = $result->get_set();
	return \@arr;
}

=head2 get_ancestor_terms_by_subnamespace

  Usage    - $ontology->get_ancestor_terms_by_subnamespace($term, subnamespace)
  Returns  - a set with the ancestor terms (OBO::Core::Term) of the given subnamespace 
  Args     - the term (OBO::Core::Term), the subnamespace (string, e.g. 'P', 'R', 'Ia' etc)
  Function - returns recursively the given term's parents of the given subnamespace
  
=cut

sub get_ancestor_terms_by_subnamespace {
	my $self = shift;
	my $result = OBO::Util::TermSet->new();
	if (@_) {
		my ($term, $subnamespace) = @_;
		my @queue = @{$self->get_parent_terms($term)};
		while (scalar(@queue) > 0) {
			my $unqueued = shift @queue;
			$result->add($unqueued) if substr($unqueued->id(), 4, length($subnamespace)) eq $subnamespace;
			my @parents = @{$self->get_parent_terms($unqueued)};
			@queue = (@queue, @parents);
		}
	}
	my @arr = $result->get_set();
	return \@arr;
}

=head2 get_descendent_terms_by_relationship_type

  Usage    - $ontology->get_descendent_terms_by_relationship_type($term, $rel_type)
  Returns  - a set with the descendent terms (OBO::Core::Term) of the given term linked by the given relationship type
  Args     - OBO::Core::Term object, OBO::Core::RelationshipType object
  Function - returns recursively all the child terms of the given term linked by the given relationship type
  
=cut

sub get_descendent_terms_by_relationship_type {
	my $self = shift;
	my $result = OBO::Util::TermSet->new();
	if (@_) {
		my ($term, $type) = @_;
		my @queue = @{$self->get_tail_by_relationship_type($term, $type)};
		while (scalar(@queue) > 0) {
			my $unqueued = shift @queue;
			$result->add($unqueued);
			my @children = @{$self->get_tail_by_relationship_type($unqueued, $type)}; 
			@queue = (@queue, @children);
		}
	}
	my @arr = $result->get_set();
	return \@arr;
}

=head2 get_ancestor_terms_by_relationship_type

  Usage    - $ontology->get_ancestor_terms_by_relationship_type($term, $rel_type)
  Returns  - a set with the ancestor terms (OBO::Core::Term) of the given term linked by the given relationship type
  Args     - OBO::Core::Term object, OBO::Core::RelationshipType object
  Function - returns recursively the parent terms of the given term linked by the given relationship type
  
=cut

sub get_ancestor_terms_by_relationship_type {
	my $self = shift;
	my $result = OBO::Util::TermSet->new();
	if (@_) {
		my ($term, $type) = @_;
		my @queue = @{$self->get_head_by_relationship_type($term, $type)};
		while (scalar(@queue) > 0) {
			my $unqueued = shift @queue;
			$result->add($unqueued);
			my @parents = @{$self->get_head_by_relationship_type($unqueued, $type)};
			@queue = (@queue, @parents);
		}
	}
	my @arr = $result->get_set();
	return \@arr;
}

=head2 get_term_by_xref

  Usage    - $ontology->get_term_by_xref($db, $acc)
  Returns  - the term (OBO::Core::Term) associated with the given external database ID. 'undef' is returned if there is no term for the given arguments.	
  Args     - the name of the external database and the ID (strings)
  Function - returns the term associated with the given external database ID
  
=cut

sub get_term_by_xref {
	my ($self, $db, $acc) = @_;
	my $result;
	if ($db && $acc) {		
		foreach my $term (@{$self->get_terms()}) { # return the exact occurrence
			$result = $term; 
			foreach my $xref ($term->xref_set_as_string()) {
				return $result if (($xref->db() eq $db) && ($xref->acc() eq $acc));
			}
		}
	}
	return undef;
}

=head2 get_instance_by_xref

  Usage    - $ontology->get_instance_by_xref($db, $acc)
  Returns  - the instance (OBO::Core::Instance) associated with the given external database ID. 'undef' is returned if there is no instance for the given arguments.	
  Args     - the name of the external database and the ID (strings)
  Function - returns the instance associated with the given external database ID
  
=cut

sub get_instance_by_xref {
	my ($self, $db, $acc) = @_;
	my $result;
	if ($db && $acc) {		
		foreach my $instance (@{$self->get_instances()}) { # return the exact occurrence
			$result = $instance; 
			foreach my $xref ($instance->xref_set_as_string()) {
				return $result if (($xref->db() eq $db) && ($xref->acc() eq $acc));
			}
		}
	}
	return undef;
}

=head2 get_paths_term1_term2

  Usage    - $ontology->get_paths_term1_term2($term1_id, $term2_id)
  Returns  - an array of references to the paths between term1 and term2
  Args     - the IDs of the terms for which a path (or paths) will be found
  Function - returns the path(s) linking term1 and term2, where term1 is more specific than term2
  
=cut
sub get_paths_term1_term2 () {
	my ($self, $v, $bstop) = @_;
	
	my @nei  = __sort_by_id(sub {shift}, @{$self->get_parent_terms($self->get_term_by_id($v))});
	
	my $path = $v;
	my @bk   = ($v);
	my $p_id = $v;
	
	my %hijos;	
	my %drop;
	my %banned;
	
	my @ruta;
	my @result;
	
	my $target_source_rels = $self->{TARGET_SOURCE_RELATIONSHIPS};
	
	while ($#nei > -1) {
		my @back;
		my $n          = pop @nei; # neighbours
		my $n_id       = $n->id();

		next if (!defined $p_id);  # TODO investigate cases where $p_id might not be defined
		my $p          = $self->get_term_by_id($p_id);
		 
		my @ps         = __sort_by_id(sub {shift}, @{$self->get_parent_terms($n)});
		my @hi         = __sort_by_id(sub {shift}, @{$self->get_parent_terms($p)});
		
		$hijos{$p_id}  = $#hi + 1;
		$hijos{$n_id}  = $#ps + 1;
		push @bk, $n_id;
		
		# add the (candidate) relationship
		push @ruta, __sort_by_id(sub {shift}, values(%{$target_source_rels->{$p}->{$n}}));

		if ($bstop eq $n_id) {
			
			#print STDERR "\n\nSTOP FOUND : ", $n_id if ($v == 103 && $bstop == 265); # DEBUG
			#print STDERR "\nPATH       : ", $path if ($v == 103); # DEBUG
			#print STDERR "\nBK         : ", map {$_.'->'} @bk if ($v == 103); # DEBUG
			#print STDERR "\nRUTA       : ", map {$_->id()} @ruta if ($v == 103); # DEBUG
						
			$path .= '->'.$n_id;
			push @result, [@ruta];
		}
		
		if ($#ps == -1) { # leaf
			my $sou = $p_id;		
			$p_id   = pop @bk;
			pop @ruta;
			
			#push @back, $p_id; # hold the un-stacked ones

			# NOTE: The following 3 lines of code are misteriously not used anymore...
			# banned relationship
			#my $source = $self->get_term_by_id($sou);
			#my $target = $self->get_term_by_id($p_id);
			#my $rr     = sort values(%{$self->{TARGET_SOURCE_RELATIONSHIPS}->{$source}->{$target}});
			
			$banned{$sou}++;
			my $hijos_sou  = $hijos{$sou};
			my $banned_sou = $banned{$sou};
			if (defined $banned_sou && $banned_sou > $hijos_sou){ # banned rel's from source
				$banned{$sou} = $hijos_sou;
			}
			
			$drop{$bk[$#bk]}++; # if (defined $drop{$bk[$#bk]}  && $drop{$bk[$#bk]} < $hijos{$p_id});
			
			my $w = $#bk;
			my $bk_ww;
			while ( $w > -1 
					&& 
					(  $bk_ww = $bk[$w], ($hijos{$bk_ww} == 1 )
					   || (defined $drop{$bk_ww}   && $hijos{$bk_ww}  == $drop{$bk_ww})
					   || (defined $banned{$bk_ww} && $banned{$bk_ww} == $hijos{$bk_ww})
					)
			      ) {
				$p_id = pop @bk;
				push @back, $p_id; # hold the un-stacked ones
				
				pop @ruta;
				$banned{$p_id}++ if ($banned{$p_id} < $hijos{$p_id}); # more banned rel's
				
				$w--;
				if ($w > -1) {
					my $bk_w = $bk[$w];

					$banned{$bk_w}++;
					my $hijos_bk_w  = $hijos{$bk_w};
					my $banned_bk_w = $banned{$bk_w};
					if (defined $banned_bk_w && $banned_bk_w > $hijos_bk_w) {
						$banned{$bk_w} = $hijos_bk_w;
					}				
				}
				
			}				
		} else {
			$p_id = $n_id;
		}
		
		push @nei, @ps; # add next level
		
		$p_id  = $bk[$#bk];
		$path .= '->'.$n_id;

		#
		# clean banned using the back (unstacked)
		#
		map {$banned{$_} = 0} @back;		
	} # while
	
	return @result;
}

=head2 get_paths_term_terms

  Usage    - $ontology->get_paths_term_terms($term, $set_of_terms)
  Returns  - an array of references to the paths between a given term ID and a given set of terms IDs 
  Args     - the ID of the term (string) for which a path (or paths) will be found and a set of terms (OBO::Util::Set)
  Function - returns the path(s) linking the given term and the given set of terms
  
=cut
sub get_paths_term_terms () {
	my ($self, $v, $bstop) = @_;
	
	#
	# Arguments validation
	#
	return if (!defined $v || !$self->has_term_id($v));
	return if (!defined $bstop || $bstop->size == 0);
	
	my @nei = @{$self->get_parent_terms($self->get_term_by_id($v))};
	
	my $path = $v;
	my @bk   = ($v);
	my $p_id = $v;
	
	my %hijos;	
	my %drop;
	my %banned;
	
	my @ruta;
	my @result;
	
	my $target_source_rels = $self->{TARGET_SOURCE_RELATIONSHIPS};
	while ($#nei > -1) {
		my @back;	

		my $n          = pop @nei; # neighbours
		my $n_id       = $n->id();

		next if (!defined $p_id);  # TODO investigate cases where $p_id might not be defined
		my $p          = $self->get_term_by_id($p_id);
		 
		my @ps         = @{$self->get_parent_terms($n)};
		my @hi         = @{$self->get_parent_terms($p)};
		
		$hijos{$p_id}  = $#hi + 1;
		$hijos{$n_id}  = $#ps + 1;
		push @bk, $n_id;
		
		# add the (candidate) relationship
		push @ruta, sort values(%{$target_source_rels->{$p}->{$n}});
		
		if ($bstop->contains($n_id)) {
			#warn "\nSTOP FOUND : ", $n_id;			
			$path .= '->'.$n_id;
			#warn 'PATH       : ', $path;
			#warn 'BK         : ', map {$_.'->'} @bk;
			#warn 'RUTA       : ', map {$_->id()} @ruta;
			push @result, [@ruta];
		}
		
		if ($#ps == -1) { # leaf
			my $sou = $p_id;		
			$p_id   = pop @bk;
			pop @ruta;
			
			#push @back, $p_id; # hold the un-stacked ones
			
			# NOTE: The following 3 lines of code are misteriously not used...
			# banned relationship
			#my $source = $self->get_term_by_id($sou);
			#my $target = $self->get_term_by_id($p_id);
			#my $rr     = sort values(%{$self->{TARGET_SOURCE_RELATIONSHIPS}->{$source}->{$target}});
			
			$banned{$sou}++;
			my $hijos_sou  = $hijos{$sou};
			my $banned_sou = $banned{$sou};
			if (defined $banned_sou && $banned_sou > $hijos_sou){ # banned rel's from source
				$banned{$sou} = $hijos_sou;
			}
			
			$drop{$bk[$#bk]}++; # if (defined $drop{$bk[$#bk]}  && $drop{$bk[$#bk]} < $hijos{$p_id});
			
			my $w = $#bk;
			my $bk_ww;
			while ( $w > -1 
					&& 
					(  $bk_ww = $bk[$w], ($hijos{$bk_ww} == 1 )
					   || (defined $drop{$bk_ww}   && $hijos{$bk_ww}  == $drop{$bk_ww})
					   || (defined $banned{$bk_ww} && $banned{$bk_ww} == $hijos{$bk_ww})
					)
			      ) {
				$p_id = pop @bk;
				push @back, $p_id; # hold the un-stacked ones
				
				pop @ruta;
				$banned{$p_id}++ if ($banned{$p_id} < $hijos{$p_id}); # more banned rel's
				
				$w--;
				if ($w > -1) {
					my $bk_w = $bk[$w];
				
					$banned{$bk_w}++;
					my $hijos_bk_w  = $hijos{$bk_w};
					my $banned_bk_w = $banned{$bk_w};
					if (defined $banned_bk_w && $banned_bk_w > $hijos_bk_w) {
						$banned{$bk_w} = $hijos_bk_w;
					}				
				}
				
			}				
		} else {
			$p_id = $n_id;
		}
		push @nei, @ps; # add next level
		$p_id  = $bk[$#bk];
		$path .= '->'.$n_id;
		
		#
		# clean banned using the back (unstacked)
		#
		map {$banned{$_} = 0} @back;
	} # while
	
	return @result;
}

=head2 get_paths_term_terms_same_rel

  Usage    - $ontology->get_paths_term_terms_same_rel($term_id, $set_of_terms, $type_of_relationship)
  Returns  - an array of references to the paths between a given term ID and a given set of terms IDs 
  Args     - the ID of the term (string) for which a path (or paths) will be found, a set of terms (OBO::Util::Set) and the ID of the relationship type 
  Function - returns the path(s) linking the given term (term ID) and the given set of terms along the same relationship (e.g. is_a)
  
=cut
sub get_paths_term_terms_same_rel () {
	my ($self, $v, $bstop, $rel) = @_;
	
	# TODO Check the case where there are reflexive relationships (e.g. GO:0000011_is_a_GO:0000011)
	
	#
	# Arguments validation
	#
	return if (!defined $v || !$self->has_term_id($v));
	return if (!defined $bstop || $bstop->size == 0);
	return if (!defined $rel || !$self->has_relationship_type_id($rel));
	
	my $r_type = $self->get_relationship_type_by_id($rel);
	my @nei    = @{$self->get_head_by_relationship_type($self->get_term_by_id($v), $r_type)};
	
	my $path = $v;
	my @bk   = ($v);
	my $p_id = $v;
	
	my %hijos;	
	my %drop;
	my %banned;
	
	my @ruta;
	my @result;
	
	my $target_source_rels = $self->{TARGET_SOURCE_RELATIONSHIPS};
	while ($#nei > -1) {
		
		my @back;

		my $n          = pop @nei; # neighbours
		my $n_id       = $n->id();

		next if (!defined $p_id);  # TODO investigate cases where $p_id might not be defined
		my $p          = $self->get_term_by_id($p_id);

		my @ps         = @{$self->get_head_by_relationship_type($n, $r_type)};
		my @hi         = @{$self->get_head_by_relationship_type($p, $r_type)};

		$hijos{$p_id}  = $#hi + 1;
		$hijos{$n_id}  = $#ps + 1;
		
		push @bk, $n_id;
		
		# add the (candidate) relationship
		push @ruta, sort values(%{$target_source_rels->{$p}->{$n}});
		
		if ($bstop->contains($n_id)) {
			#warn "\nSTOP FOUND : ", $n_id;			
			$path .= '->'.$n_id;
			#warn 'PATH       : ', $path;
			#warn 'BK         : ', map {$_.'->'} @bk;
			#warn 'RUTA       : ', map {$_->id().'->'} @ruta;
			push @result, [@ruta];
		}
		
		if ($#ps == -1) { # leaf
			my $sou = $p_id;		
			$p_id   = pop @bk;
			pop @ruta;
			
			#push @back, $p_id; # hold the un-stacked ones
			
			# NOTE: The following 3 lines of code are misteriously not used...
			# banned relationship
			#my $source = $self->get_term_by_id($sou);
			#my $target = $self->get_term_by_id($p_id);
			#my $rr     = sort values(%{$self->{TARGET_SOURCE_RELATIONSHIPS}->{$source}->{$target}});
			
			$banned{$sou}++;
			my $hijos_sou  = $hijos{$sou};
			my $banned_sou = $banned{$sou};
			if (defined $banned_sou && $banned_sou > $hijos_sou){ # banned rel's from source
				$banned{$sou} = $hijos_sou;
			}
			
			$drop{$bk[$#bk]}++; # if (defined $drop{$bk[$#bk]} && $drop{$bk[$#bk]} < $hijos{$p_id});
			
			my $w = $#bk;
			my $bk_ww;
			while ( $w > -1 
					&& 
					(  $bk_ww = $bk[$w], ($hijos{$bk_ww} == 1 )
					   || (defined $drop{$bk_ww}   && $hijos{$bk_ww}  == $drop{$bk_ww})
					   || (defined $banned{$bk_ww} && $banned{$bk_ww} == $hijos{$bk_ww})
					)
			      ) {
				$p_id = pop @bk;
				push @back, $p_id; # hold the un-stacked ones

				pop @ruta;
				$banned{$p_id}++ if ($banned{$p_id} < $hijos{$p_id}); # more banned rel's

				$w--;
				if ($w > -1) {
					my $bk_w = $bk[$w];

					$banned{$bk_w}++;
					my $hijos_bk_w  = $hijos{$bk_w};
					my $banned_bk_w = $banned{$bk_w};
					if (defined $banned_bk_w && $banned_bk_w > $hijos_bk_w) {
						$banned{$bk_w} = $hijos_bk_w;
					}
				}
			}
		} else {
			$p_id = $n_id;
		}
		push @nei, @ps; # add next level
		$p_id  = $bk[$#bk];
		$path .= '->'.$n_id;
		
		#
		# clean banned using the back (unstacked)
		#
		map {$banned{$_} = 0} @back;
	} # while
	
	return @result;
}

=head2 obo_id2owl_id

  Usage    - $ontology->obo_id2owl_id($term)
  Returns  - the ID for OWL representation.
  Args     - the OBO-type ID.
  Function - Transform an OBO-type ID into an OWL-type one. E.g. APO:I1234567 -> APO_I1234567
  
=cut

sub obo_id2owl_id {
	$_[0] =~ tr/:/_/;
	return $_[0];
}

=head2 owl_id2obo_id

  Usage    - $ontology->owl_id2obo_id($term)
  Returns  - the ID for OBO representation.
  Args     - the OWL-type ID.
  Function - Transform an OWL-type ID into an OBO-type one. E.g. APO_I1234567 -> APO:I1234567
  
=cut

sub owl_id2obo_id {
	$_[0] =~ tr/_/:/;
	return $_[0];
}

sub __date {
	caller eq __PACKAGE__ or croak;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	my $result = sprintf "%02d:%02d:%4d %02d:%02d", $mday,$mon+1,$year+1900,$hour,$min; # e.g. 11:05:2008 12:52
}

sub __dfs () {
	caller eq __PACKAGE__ or croak;
	my ($self, $onto, $v) = @_;
	
	my $blist = OBO::Util::Set->new();
	my $brels = OBO::Util::Set->new();
	
	my $explored_set = OBO::Util::Set->new();
	$explored_set->add($v);	
	my @nei = @{$onto->get_parent_terms($onto->get_term_by_id($v))};
	
	my $path = $v;
	my @bk   = ($v);
	my $i    = 0;
	my $p_id = $v;
	while ($#nei > -1) {
		my $n    = pop @nei; # neighbors
		my $n_id = $n->id();
		if ($blist->contains($n_id) || 
			$brels->contains(sort values(%{$onto->{TARGET_SOURCE_RELATIONSHIPS}->
				                     {$onto->get_term_by_id($p_id)}->
				                     {$onto->get_term_by_id($n_id)}}))) {
			next;
		}
		my @ps = @{$onto->get_parent_terms($n)};
		
		if (!$blist->contains($n_id) || !$explored_set->contains($n_id)) {
			$explored_set->add($n_id);
			push @nei, @ps; # add next level
			$path .= '->'.$n_id;
			push @bk, $n_id;
			$i++;
		}
		if (!@ps) { # if leaf
		
			last if (!@nei);
			
			for (my $j = 0; $j < $i; $j++) {
				my $e = shift @bk;
				$explored_set->remove($e);
			}
			@nei  = @{$onto->get_parent_terms($onto->get_term_by_id($v))};
			$i    = 0;
			$path = $v; # init
			
			my $l      = pop @bk;
			my $source = $onto->get_term_by_id($p_id);
			my $target = $onto->get_term_by_id($n_id);
			my $rr     = values(%{$onto->{TARGET_SOURCE_RELATIONSHIPS}->{$source}->{$target}});
			$brels->add($rr->id());
			
			# banned terms
			my @crels = @{$onto->get_relationships_by_target_term($target)};
			my $all_banned = 1; # assume yes...
			foreach my $crel (@crels) {
				if (!$brels->contains($crel->id())) {
					$all_banned = 0;
					last;
				}
			}
			if ($all_banned) {
				$blist->add($l);
			}

			# banned rels
			my @drels  = @{$onto->get_relationships_by_source_term($source)};
			my $all_rels_banned = 1;
			foreach my $drel (@drels) {
				if (!$brels->contains($drel->id())) {
					$all_rels_banned = 0;
					last;
				}
			}
			if ($all_rels_banned) {
				$blist->add($p_id);
			}
			
			@bk = ($v);
			
			$p_id = $v;
			next;
		}
		$p_id = $n_id;
	}
}

sub __get_name_without_whitespaces() {
	caller eq __PACKAGE__ or croak;
	$_[0] =~ s/\s+/_/g;
	return $_[0];
}

sub __idspace_as_string {
	caller eq __PACKAGE__ or croak;
	my ($self, $local_id, $uri, $description) = @_;
	if ($local_id && $uri) {
		my $new_idspace = OBO::Core::IDspace->new();
		$new_idspace->local_idspace($local_id);
		$new_idspace->uri($uri);
		$new_idspace->description($description) if (defined $description);
		$self->idspaces($new_idspace);
		return $new_idspace;
	}
	my @idspaces = $self->idspaces()->get_set();
	my @idspaces_as_string = ();
	foreach my $idspace (@idspaces) {
		my $idspace_as_string          = $idspace->local_idspace();
		$idspace_as_string            .= ' '.$idspace->uri();
		my $idspace_description_string = $idspace->description();
		$idspace_as_string            .= ' "'.$idspace_description_string.'"' if (defined $idspace_description_string);
		
		push @idspaces_as_string, $idspace_as_string;
	}
	if (!@idspaces_as_string) {
		return ''; # empty string
	} else {
		return @idspaces_as_string
	}
}

sub __sort_by {
	caller eq __PACKAGE__ or croak;
	my ($subRef1, $subRef2, @input) = @_;
	my @result = map { $_->[0] }                           # restore original values
				sort { $a->[1] cmp $b->[1] }               # sort
				map  { [$_, &$subRef1($_->$subRef2())] }   # transform: value, sortkey
				@input;
}

sub __sort_by_id {
	caller eq __PACKAGE__ or croak;
	my ($subRef, @input) = @_;
	my @result = map { $_->[0] }                           # restore original values
				sort { $a->[1] cmp $b->[1] }               # sort
				map  { [$_, &$subRef($_->id())] }          # transform: value, sortkey
				@input;
}

sub __print_hasDbXref_for_owl {
	caller eq __PACKAGE__ or croak;
	my ($output_file_handle, $set, $oboContentUrl, $tab_times) = @_;
	my $tab0 = "\t"x$tab_times;
	my $tab1 = "\t"x($tab_times + 1);
	my $tab2 = "\t"x($tab_times + 2);
	for my $ref ($set->get_set()) {
		print $output_file_handle $tab0."<oboInOwl:hasDbXref>\n";
		print $output_file_handle $tab1."<oboInOwl:DbXref>\n";
		my $db = $ref->db();
		my $acc = $ref->acc();

		# Special case when db=http and acc=www.domain.com
		# <rdfs:label>URL:http%3A%2F%2Fwww2.merriam-webster.com%2Fcgi-bin%2Fmwmednlm%3Fbook%3DMedical%26va%3Dforebrain</rdfs:label>
		# <oboInOwl:hasURI rdf:datatype="http://www.w3.org/2001/XMLSchema#anyURI">http%3A%2F%2Fwww2.merriam-webster.com%2Fcgi-bin%2Fmwmednlm%3Fbook%3DMedical%26va%3Dforebrain</oboInOwl:hasURI>
		if ($db eq 'http') {
			my $http_location = &__char_hex_http($acc);
			print $output_file_handle $tab2."<rdfs:label>URL:http%3A%2F%2F", $http_location, "</rdfs:label>\n";
			print $output_file_handle $tab2."<oboInOwl:hasURI rdf:datatype=\"http://www.w3.org/2001/XMLSchema#anyURI\">",$http_location,"</oboInOwl:hasURI>\n";	
		} else {
			print $output_file_handle $tab2."<rdfs:label>", $db, ":", $acc, "</rdfs:label>\n";
			print $output_file_handle $tab2."<oboInOwl:hasURI rdf:datatype=\"http://www.w3.org/2001/XMLSchema#anyURI\">",$oboContentUrl,$db,'#',$db,'_',$acc,"</oboInOwl:hasURI>\n";
		}
		print $output_file_handle $tab1."</oboInOwl:DbXref>\n";
		print $output_file_handle $tab0."</oboInOwl:hasDbXref>\n";
	}
}

=head2 __char_hex_http

  Usage    - $ontology->__char_hex_http($seq)
  Returns  - the sequence with the numeric HTML representation for the given special character
  Args     - the sequence of characters
  Function - Transforms a character into its equivalent HTML number, e.g. : -> &#58;
  
=cut

sub __char_hex_http {
	caller eq __PACKAGE__ or croak;
	
	$_[0] =~ s/:/&#58;/g;  # colon
	$_[0] =~ s/;/&#59;/g;  # semicolon
	$_[0] =~ s/</&#60;/g;  # less than sign
	$_[0] =~ s/=/&#61;/g;  # equal sign
	$_[0] =~ s/>/&#62;/g;  # greater than sign
	$_[0] =~ s/\?/&#63;/g; # question mark
	$_[0] =~ s/\//&#47;/g; # slash
	$_[0] =~ s/&/&#38;/g;  # ampersand
	$_[0] =~ s/"/&#34;/g;  # double quotes
	$_[0] =~ s/±/&#177;/g; # plus-or-minus sign

	return $_[0];
}

1;

__END__

=head1 NAME

OBO::Core::Ontology  - An ontology of terms/concepts/universals, instances/individuals and relationships/properties.
 
=head1 SYNOPSIS

use OBO::Core::Ontology;

use OBO::Core::Term;

use OBO::Core::Relationship;

use OBO::Core::RelationshipType;

use strict;


# three new terms

my $n1 = OBO::Core::Term->new();

my $n2 = OBO::Core::Term->new();

my $n3 = OBO::Core::Term->new();


# new ontology

my $onto = OBO::Core::Ontology->new;


$n1->id("APO:P0000001");

$n2->id("APO:P0000002");

$n3->id("APO:P0000003");


$n1->name("One");

$n2->name("Two");

$n3->name("Three");


my $def1 = OBO::Core::Def->new();

$def1->text("Definition of One");

my $def2 = OBO::Core::Def->new();

$def2->text("Definition of Two");

my $def3 = OBO::Core::Def->new();

$def3->text("Definition of Three");


$n1->def($def1);

$n2->def($def2);

$n3->def($def3);


$onto->add_term($n1);

$onto->add_term($n2);

$onto->add_term($n3);


$onto->delete_term($n1);


$onto->add_term($n1);

# new term

my $n4 = OBO::Core::Term->new();

$n4->id("APO:P0000004");

$n4->name("Four");

my $def4 = OBO::Core::Def->new();

$def4->text("Definition of Four");

$n4->def($def4);

$onto->delete_term($n4);

$onto->add_term($n4);


# add term as string

my $new_term = $onto->add_term_as_string("APO:P0000005", "Five");

$new_term->def_as_string("This is a dummy definition", '[APO:vm, APO:ls, APO:ea "Erick Antezana"]');

my $n5 = $new_term; 


# five new relationships

my $r12 = OBO::Core::Relationship->new();

my $r23 = OBO::Core::Relationship->new();

my $r13 = OBO::Core::Relationship->new();

my $r14 = OBO::Core::Relationship->new();

my $r35 = OBO::Core::Relationship->new();


$r12->id("APO:P0000001_is_a_APO:P0000002");

$r23->id("APO:P0000002_part_of_APO:P0000003");

$r13->id("APO:P0000001_participates_in_APO:P0000003");

$r14->id("APO:P0000001_participates_in_APO:P0000004");

$r35->id("APO:P0000003_part_of_APO:P0000005");


$r12->type('is_a');

$r23->type('part_of');

$r13->type("participates_in");

$r14->type("participates_in");

$r35->type('part_of');


$r12->link($n1, $n2); 

$r23->link($n2, $n3);

$r13->link($n1, $n3);

$r14->link($n1, $n4);

$r35->link($n3, $n5);


# get all terms

my $c = 0;

my %h;

foreach my $t (@{$onto->get_terms()}) {
	
	$h{$t->id()} = $t;
	
	$c++;
	
}


# get terms with argument

my @processes = sort {$a->id() cmp $b->id()} @{$onto->get_terms("APO:P.*")};

my @odd_processes = sort {$a->id() cmp $b->id()} @{$onto->get_terms("APO:P000000[35]")};

$onto->idspace_as_string("APO", "http://www.cellcycle.org/ontology/APO");

my @same_processes = @{$onto->get_terms_by_subnamespace("P")};

my @no_processes = @{$onto->get_terms_by_subnamespace("p")};


# add relationships

$onto->add_relationship($r12);

$onto->add_relationship($r23);

$onto->add_relationship($r13);

$onto->add_relationship($r14);

$onto->add_relationship($r35);



# add relationships and terms linked by this relationship

my $n11 = OBO::Core::Term->new();

my $n21 = OBO::Core::Term->new();

$n11->id("APO:P0000011"); $n11->name("One one"); $n11->def_as_string("Definition One one", "");

$n21->id("APO:P0000021"); $n21->name("Two one"); $n21->def_as_string("Definition Two one", "");

my $r11_21 = OBO::Core::Relationship->new();

$r11_21->id("APO:R0001121"); $r11_21->type("r11-21");

$r11_21->link($n11, $n21);

$onto->add_relationship($r11_21); # adds to the ontology the terms linked by this relationship


# get all relationships

my %hr;

foreach my $r (@{$onto->get_relationships()}) {
	
	$hr{$r->id()} = $r;
	
}

# get children

my @children = @{$onto->get_child_terms($n1)}; 

@children = @{$onto->get_child_terms($n3)}; 

my %ct;

foreach my $child (@children) {
	
	$ct{$child->id()} = $child;
	
} 


@children = @{$onto->get_child_terms($n2)};


# get parents

my @parents = @{$onto->get_parent_terms($n3)};

@parents = @{$onto->get_parent_terms($n1)};

@parents = @{$onto->get_parent_terms($n2)};


# get all descendents

my @descendents1 = @{$onto->get_descendent_terms($n1)};

my @descendents2 = @{$onto->get_descendent_terms($n2)};

my @descendents3 = @{$onto->get_descendent_terms($n3)};

my @descendents5 = @{$onto->get_descendent_terms($n5)};


# get all ancestors

my @ancestors1 = @{$onto->get_ancestor_terms($n1)};

my @ancestors2 = @{$onto->get_ancestor_terms($n2)};

my @ancestors3 = @{$onto->get_ancestor_terms($n3)};


# get descendents by term subnamespace

my @descendents4 = @{$onto->get_descendent_terms_by_subnamespace($n1, 'P')};

my @descendents5 = @{$onto->get_descendent_terms_by_subnamespace($n2, 'P')}; 

my @descendents6 = @{$onto->get_descendent_terms_by_subnamespace($n3, 'P')};

my @descendents6 = @{$onto->get_descendent_terms_by_subnamespace($n3, 'R')};


# get ancestors by term subnamespace

my @ancestors4 = @{$onto->get_ancestor_terms_by_subnamespace($n1, 'P')};

my @ancestors5 = @{$onto->get_ancestor_terms_by_subnamespace($n2, 'P')}; 

my @ancestors6 = @{$onto->get_ancestor_terms_by_subnamespace($n3, 'P')};

my @ancestors6 = @{$onto->get_ancestor_terms_by_subnamespace($n3, 'R')};



# three new relationships types

my $r1 = OBO::Core::RelationshipType->new();

my $r2 = OBO::Core::RelationshipType->new();

my $r3 = OBO::Core::RelationshipType->new();


$r1->id("APO:R0000001");

$r2->id("APO:R0000002");

$r3->id("APO:R0000003");


$r1->name('is_a');

$r2->name('part_of');

$r3->name("participates_in");


# add relationship types

$onto->add_relationship_type($r1);

$onto->add_relationship_type($r2);

$onto->add_relationship_type($r3);


# get descendents or ancestors linked by a particular relationship type 

my $rel_type1 = $onto->get_relationship_type_by_name('is_a');

my $rel_type2 = $onto->get_relationship_type_by_name('part_of');

my $rel_type3 = $onto->get_relationship_type_by_name("participates_in");


my @descendents7 = @{$onto->get_descendent_terms_by_relationship_type($n5, $rel_type1)};

@descendents7 = @{$onto->get_descendent_terms_by_relationship_type($n5, $rel_type2)};

@descendents7 = @{$onto->get_descendent_terms_by_relationship_type($n2, $rel_type1)};

@descendents7 = @{$onto->get_descendent_terms_by_relationship_type($n3, $rel_type3)};


my @ancestors7 = @{$onto->get_ancestor_terms_by_relationship_type($n1, $rel_type1)};

@ancestors7 = @{$onto->get_ancestor_terms_by_relationship_type($n1, $rel_type2)};

@ancestors7 = @{$onto->get_ancestor_terms_by_relationship_type($n1, $rel_type3)};

@ancestors7 = @{$onto->get_ancestor_terms_by_relationship_type($n2, $rel_type2)};



# add relationship type as string

my $relationship_type = $onto->add_relationship_type_as_string("APO:R0000004", "has_participant");


# get relationship types

my @rt = @{$onto->get_relationship_types()};

my %rrt;

foreach my $relt (@rt) {
	
	$rrt{$relt->name()} = $relt;
	
}



my @rtbt = @{$onto->get_relationship_types_by_term($n1)};


my %rtbth;

foreach my $relt (@rtbt) {
	
	$rtbth{$relt} = $relt;
	
}


# get_head_by_relationship_type

my @heads_n1 = @{$onto->get_head_by_relationship_type($n1, $onto->get_relationship_type_by_name("participates_in"))};

my %hbrt;

foreach my $head (@heads_n1) {
	
	$hbrt{$head->id()} = $head;
	
}


=head1 DESCRIPTION

This module supports the manipulation of OBO-formatted ontologies, such as the 
Gene Ontology (http://www.geneontology.org/) or the Cell Cycle Ontology (http://www.cellcycleontology.org).
For a longer list of OBO-formatted ontologies, look at http://www.obofoundry.org/.

This module basically provides a representation of a directed acyclic graph (DAG) holding 
terms (OBO::Core::Term) which in turn are linked by relationships (OBO::Core::Relationship).
Those relationships have an associated relationship type (OBO::Core::RelationshipType).

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
