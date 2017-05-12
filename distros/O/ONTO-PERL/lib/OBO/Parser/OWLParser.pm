# $Id: OWLParser.pm 2013-02-20 erick.antezana $
#
# Module  : OWLParser.pm
# Purpose : Parse OWL files (oboInOwl mapping).
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#
package OBO::Parser::OWLParser;

use OBO::Core::Term;
use OBO::Core::Ontology;
use OBO::Core::Dbxref;
use OBO::Core::Relationship;
use OBO::Core::RelationshipType;

use Carp;
use strict;
use warnings;

use open qw(:std :utf8); # Make All I/O Default to UTF-8

sub new {
	my $class = shift;
	my $self  = {};
        
	bless ($self, $class);
	return $self;
}

##############################################################################
#
# Constant OWL tags
#
##############################################################################
use constant RDF_RDF                         => 'rdf:RDF';
use constant RDF_TYPE                        => 'rdf:type';
use constant OWL_ONTOLOGY                    => 'owl:Ontology';
use constant OWL_CLASS                       => 'owl:Class';
use constant RDFS_LABEL                      => 'rdfs:label';
use constant RDFS_COMMENT                    => 'rdfs:comment';
use constant RDFS_SUBCLASSOF                 => 'rdfs:subClassOf';
use constant RDF_RESOURCE                    => 'rdf:resource';
use constant OWL_SOMEVALUESFROM              => 'owl:someValuesFrom';
use constant OWL_ONPROPERTY                  => 'owl:onProperty';
use constant OWL_RESTRICTION                 => 'owl:Restriction';
use constant OWL_OBJECT_PROPERTY             => 'owl:ObjectProperty';
use constant DISJOINT_WITH                   => 'owl:disjointWith';
use constant RDFS_SUBPROPERTYOF              => 'rdfs:subPropertyOf';
#
# oboInOwl
#
use constant OBOINOWL_HAS_DATE               => 'oboInOwl:hasDate';
use constant OBOINOWL_HAS_DEFAULT_RELATIONSHIP_ID_PREFIX => 'oboInOwl:hasDefaultRelationshipIDPrefix';
use constant OBOINOWL_HAS_DEFAULT_NAME_SPACE => 'oboInOwl:hasDefaultNamespace';
use constant OBOINOWL_SUBSET                 => 'oboInOwl:Subset';
use constant OBOINOWL_HAS_DEFINITION         => 'oboInOwl:hasDefinition';
use constant OBOINOWL_DEFINITION             => 'oboInOwl:Definition';
use constant OBOINOWL_HAS_DBXREF             => 'oboInOwl:hasDbXref';
use constant OBOINOWL_DBXREF                 => 'oboInOwl:DbXref';
use constant OBOINOWL_HAS_URI                => 'oboInOwl:hasURI';
use constant OBOINOWL_IN_SUBSET              => 'oboInOwl:inSubset';
use constant OBOINOWL_SYNONYM                => 'oboInOwl:Synonym';
use constant OBOINOWL_HAS_EXACT_SYNONYM      => 'oboInOwl:hasExactSynonym';
use constant OBOINOWL_HAS_BROAD_SYNONYM      => 'oboInOwl:hasBroadSynonym';
use constant OBOINOWL_HAS_NARROW_SYNONYM     => 'oboInOwl:hasNarrowSynonym';
use constant OBOINOWL_HAS_RELATED_SYNONYM    => 'oboInOwl:hasRelatedSynonym';
use constant OBOINOWL_HAS_ALTERNATIVE_ID     => 'oboInOwl:hasAlternativeId';
use constant OBOINOWL_REPLACED_BY            => 'oboInOwl:replacedBy';
use constant OBOINOWL_CONSIDER               => 'oboInOwl:consider';
use constant OBOINOWL_HAS_NAMESPACE          => 'oboInOwl:hasNamespace';

#
# contexts
#
use constant CLASS_CONTEXT            => 'rdf:RDFowl:Class';
use constant CLASS_XREF_LABEL         => 'rdf:RDFowl:ClassoboInOwl:hasDbXrefoboInOwl:DbXrefrdfs:label';
use constant CLASS_XREF               => 'rdf:RDFowl:ClassoboInOwl:hasDbXrefoboInOwl:DbXref';
use constant CLASS_DEF_DBXREF_LABEL   => 'rdf:RDFowl:ClassoboInOwl:hasDefinitionoboInOwl:DefinitionoboInOwl:hasDbXrefoboInOwl:DbXrefrdfs:label';
use constant CLASS_DEF_DBXREF         => 'rdf:RDFowl:ClassoboInOwl:hasDefinitionoboInOwl:DefinitionoboInOwl:hasDbXrefoboInOwl:DbXref';

use constant PROPERTY_XREF_LABEL      => 'rdf:RDFowl:ObjectPropertyoboInOwl:hasDbXrefoboInOwl:DbXrefrdfs:label';
use constant PROPERTY_XREF            => 'rdf:RDFowl:ObjectPropertyoboInOwl:hasDbXrefoboInOwl:DbXref';
use constant PROP_DEF_DBXREF_LABEL    => 'rdf:RDFowl:ObjectPropertyoboInOwl:hasDefinitionoboInOwl:DefinitionoboInOwl:hasDbXrefoboInOwl:DbXrefrdfs:label';
use constant PROP_DEF_DBXREF          => 'rdf:RDFowl:ObjectPropertyoboInOwl:hasDefinitionoboInOwl:DefinitionoboInOwl:hasDbXrefoboInOwl:DbXref';

use constant EXACT_SYNONYM_LABEL      => 'rdf:RDFowl:ClassoboInOwl:hasExactSynonymoboInOwl:Synonymrdfs:label';
use constant EXACT_SYNONYM            => 'rdf:RDFowl:ClassoboInOwl:hasExactSynonymoboInOwl:Synonym';
use constant BROAD_SYNONYM_LABEL      => 'rdf:RDFowl:ClassoboInOwl:hasBroadSynonymoboInOwl:Synonymrdfs:label';
use constant BROAD_SYNONYM            => 'rdf:RDFowl:ClassoboInOwl:hasBroadSynonymoboInOwl:Synonym';
use constant NARROW_SYNONYM_LABEL     => 'rdf:RDFowl:ClassoboInOwl:hasNarrowSynonymoboInOwl:Synonymrdfs:label';
use constant NARROW_SYNONYM           => 'rdf:RDFowl:ClassoboInOwl:hasNarrowSynonymoboInOwl:Synonym';
use constant RELATED_SYNONYM_LABEL    => 'rdf:RDFowl:ClassoboInOwl:hasRelatedSynonymoboInOwl:Synonymrdfs:label';
use constant RELATED_SYNONYM          => 'rdf:RDFowl:ClassoboInOwl:hasRelatedSynonymoboInOwl:Synonym';
use constant SYNONYM_DBXREF_LABEL     => 'SYNONYM_DBXREF_LABEL';
use constant SYNONYM_DBXREF           => 'SYNONYM_DBXREF';

#
# Global variables
#
my %data_current_tag;      # for gathering the chars stream
my $result;                # The ontology
my $count            = 0;  # count terms
my $tag              = ''; # current tag
my $parent_tag       = ''; # parent tag
my $grant_parent_tag = ''; # grant parent tag
my $great_parent_tag = ''; # great parent tag

my $current_term_id;                   # current term ID
my $relationship_type_id;
my $def_char                      = 0; # defintion characters streamed
my $current_relationship_type_id;      # current relationship ID
my $attr                          = '';# current relationship
my $current_line                  = 0; # current line in the parsed file
my $is_metadata                   = 0; # if the element is aprt of the metadata (e.g. oboInOwl:DbXref)
my @dbxref                        = ();# current dbxrefs
my $owl_ontology_tag              = 0; # inside the ontology data
my $owl_class_tag                 = 0; # Am I parsing a class?
my $owl_object_property_tag       = 0; # Am I parsing a property?
my $oboinowl_has_definition_tag   = 0; # 
my $oboinowl_definition_tag       = 0; # Am I parsing a definition chunk?
my $oboinowl_synonym_tag          = 0; # Am I parsing a synonym chunk?
my $type_of_synonym;
my $whitin_a_synonym              = 0;

=head2 work

  Usage    - $OWLParser->work($owl_file_path)
  Returns  - the parsed OWL ontology
  Args     - the OWL file to be parsed
  Function - parses an OWL file (oboInOwl mapping)
  
=cut
sub work {
	# TODO "This Parser needs to be updated (reworked) to coply with the latest OBO spec as well as the latest OBO2OWL mapping.\n";
	# TODO "You are more than welcome to contribute to this module.\n";
	
	my $self = shift;
	$self->{OWL_FILE} = shift if (@_);
	$result = OBO::Core::Ontology->new();
	
	#
	# Stream-based processing
	#
	my $my_parser = new XML::Parser();
	$my_parser->setHandlers(
						#Init    => \&init,
						Start   => \&startElement,
						End     => \&endElement,
						Char    => \&characterData
						#Default => \&default,
						#Final   => \&final
						);
	$my_parser->parsefile($self->{OWL_FILE});
	
	open (OWL_FILE, $self->{OWL_FILE}) || croak "The OWL file cannot be opened: $!";
	
	close OWL_FILE;

	return $result;
}

sub init {
	my $e = $_[0];
	#print "autogenerated-by: $0\n";
}

sub startElement {

	my( $parseinst, $element, %attrs ) = @_;
	$tag = $element;
	SWITCH: {
		$current_line = $parseinst->current_line();
		$is_metadata = 0;
		if ($tag eq OWL_ONTOLOGY) {
			$parent_tag = $parseinst->current_element();
			$owl_ontology_tag = 1;
			last SWITCH;
		}
		if ($tag eq OBOINOWL_HAS_DATE) {
			$parent_tag = $parseinst->current_element();
			last SWITCH;
		}
		if ($tag eq OBOINOWL_HAS_DEFAULT_NAME_SPACE) {
			$parent_tag = $parseinst->current_element();
			last SWITCH;
		}
		if ($tag eq OWL_CLASS) {
			my $term;
			$current_term_id = $2, $is_metadata = (defined $3)?1:0 if ($attrs{"rdf:about"} =~ m/.*\#((\w*_\w*\d*)|(\w*))$/); # Ontology terms or Metadata
			if ($current_term_id) {
				my $obo_like_id = owl_id2obo_id($current_term_id);
				$term = $result->get_term_by_id($obo_like_id); # does this term is already in the ontology?		
				if (!defined $term){
					$term = OBO::Core::Term->new();  # if not, create a new term
					$term->id($obo_like_id);
					$result->add_term($term);        # add it to the ontology
				} elsif (defined $term->def()->text() && $term->def()->text() ne "") {
					# the term is already in the ontology since it has a definition! (maybe empty?)
					croak "The term with id '", $obo_like_id, "' is duplicated in the OWL file.";
				}
			}			
			$parent_tag = $parseinst->current_element();
			$owl_class_tag = 1;
			last SWITCH;
		}
		if ($tag eq OBOINOWL_HAS_NAMESPACE) {
			$parent_tag = $parseinst->current_element();
			last SWITCH;
		}
		if ($tag eq RDFS_COMMENT) {
			$parent_tag = $parseinst->current_element();
			last SWITCH;
		} 
		if ($tag eq RDFS_LABEL) {
			$parent_tag = $parseinst->current_element();
			last SWITCH;
		} 
		if ($tag eq RDFS_SUBCLASSOF){
			if (defined $attrs{"rdf:resource"} && $attrs{"rdf:resource"} =~ m/.*\#((\w*_\w*\d*)|(ObsoleteClass)|(\w*))$/) {
				if ($3) { # ObsoleteClass
					my $term = $result->get_term_by_id($current_term_id);
					$term->is_obsolete(1);
				} else {
					my $term = $result->get_term_by_id($current_term_id);
					my $rel = OBO::Core::Relationship->new();
					my $target_id = $2;
					$target_id = owl_id2obo_id($target_id);
					$rel->id($term->id().'_is_a_'.$target_id);
					$rel->type('is_a');
					my $target = $result->get_term_by_id($target_id); # does this term is already in the ontology?
					if (!defined $target) {
						$target = OBO::Core::Term->new(); # if not, create a new term
						$target->id($target_id);
						$result->add_term($target);
					}
					$rel->link($term, $target);
					$result->add_relationship($rel);
				}
			}
			$parent_tag = $parseinst->current_element();
			last SWITCH;
		}
		if ($tag eq DISJOINT_WITH){
			if (defined $attrs{"rdf:resource"} && $attrs{"rdf:resource"} =~ m/.*\#((\w*_\w*\d*)|(\w*))$/) {
				if ($2) {
					my $disjoint_term_id = $2;
					my $term = $result->get_term_by_id($current_term_id);
					$term->disjoint_from(owl_id2obo_id($disjoint_term_id));
				}
			}
			$parent_tag = $parseinst->current_element();
			last SWITCH;
		}
		if ($tag eq OBOINOWL_DBXREF) {
			$parent_tag = $parseinst->current_element();
			last SWITCH;
		}
		if ($tag eq OBOINOWL_HAS_DEFINITION) {
			$parent_tag = $parseinst->current_element();
			$oboinowl_has_definition_tag = 1;
			last SWITCH;
		}
		if ($tag eq OBOINOWL_DEFINITION) {
			$parent_tag = $parseinst->current_element();
			$oboinowl_definition_tag = 1;
			last SWITCH;
		}
		if ($tag eq OBOINOWL_SYNONYM) {
			$parent_tag = $parseinst->current_element();
			$oboinowl_synonym_tag = 1;
			last SWITCH;
		}
		if ($tag eq OBOINOWL_HAS_EXACT_SYNONYM) {
			$parent_tag = $parseinst->current_element();
			$whitin_a_synonym = 1;
			last SWITCH;
		}
		if ($tag eq OBOINOWL_HAS_BROAD_SYNONYM) {
			$parent_tag = $parseinst->current_element();
			$whitin_a_synonym = 1;
			last SWITCH;
		}
		if ($tag eq OBOINOWL_HAS_NARROW_SYNONYM) {
			$parent_tag = $parseinst->current_element();
			$whitin_a_synonym = 1;
			last SWITCH;
		}
		if ($tag eq OBOINOWL_HAS_RELATED_SYNONYM) {
			$parent_tag = $parseinst->current_element();
			$whitin_a_synonym = 1;
			last SWITCH;
		}
		if ($tag eq OWL_OBJECT_PROPERTY && !$owl_class_tag) {
			my $type;
			$current_relationship_type_id = $3 if ($attrs{"rdf:about"} =~ m/.*\#((ObsoleteProperty)|(.*))$/); # Ontology terms or Metadata
			if ($current_relationship_type_id) {
				$type = $result->get_relationship_type_by_id($3); # does this relationship type is already in the ontology?
				if (!defined $type){
					$type = OBO::Core::RelationshipType->new();  # if not, create a new type
					$type->id($3);
					$result->add_relationship_type($type);        # add it to the ontology
				} elsif (defined $type->def()->text() && $type->def()->text() ne "") {
					# the type is already in the ontology since it has a definition! (maybe empty?)
					croak "The relationship type with id '", $3, "' is duplicated in the OWL file.";
				}
				$owl_object_property_tag = 1;
			}
			$parent_tag = $parseinst->current_element();
			last SWITCH;
		}
		if ($tag eq OWL_OBJECT_PROPERTY && $owl_class_tag && $owl_class_tag) { # e.g. relationship: participates_in
			$relationship_type_id = $1 if ($attrs{"rdf:about"} =~ m/.*\#(.*)$/);
			$parent_tag = $parseinst->current_element();
			last SWITCH;
		}
		if ($tag eq OWL_SOMEVALUESFROM && $owl_class_tag && $relationship_type_id) {
			my $target_term_id = $1 if ($attrs{"rdf:resource"} =~ m/.*\#(.*)$/);
			$target_term_id = owl_id2obo_id($target_term_id);
			my $term = $result->get_term_by_id($current_term_id);
			my $id = $term->id().'_'.$relationship_type_id.'_'.$target_term_id;
			my $rel = OBO::Core::Relationship->new();
			$rel->id($id);
			$rel->type($relationship_type_id);
			my $target = $result->get_term_by_id($target_term_id); # does this term is already in the ontology?
			if (!defined $target) {
				$target = OBO::Core::Term->new(); # if not, create a new term
				$target->id($target_term_id);
				$result->add_term($target);
			}
			$rel->link($term, $target);
			$result->add_relationship($rel);
			$relationship_type_id = undef;
			$parent_tag = $parseinst->current_element();
			last SWITCH;
		}
		if ($tag eq RDFS_SUBPROPERTYOF){
			if (defined $attrs{'rdf:resource'} && $attrs{'rdf:resource'} =~ m/.*\#(.*)$/) {
				my $target_id = $1;
				if ($target_id) {
					my $current_relationship_type_type = $result->get_relationship_type_by_id($current_relationship_type_id);
					my $rel = OBO::Core::Relationship->new();
					$rel->id($current_relationship_type_type->id().'_is_a_'.$target_id);
					$rel->type('is_a');
					my $target = $result->get_relationship_type_by_id($target_id); # does this relationship type is already in the ontology?
					if (!defined $target) {
						$target = OBO::Core::RelationshipType->new(); # if not, create a new relationship type
						$target->id($target_id);
						$result->add_relationship_type($target);
					}
					$rel->link($current_relationship_type_type, $target);
					$result->add_relationship($rel);
				}
			}
			$parent_tag = $parseinst->current_element();
			last SWITCH;
		}
		if ($tag eq OBOINOWL_HAS_ALTERNATIVE_ID) {
			$parent_tag = $parseinst->current_element();
			last SWITCH;
		}
		if ($tag eq OBOINOWL_SUBSET) {
			if (defined $attrs{'rdf:about'}) {
				my @ss = split(/\//, $attrs{'rdf:about'});
				my $ss = $ss[$#ss];
				$data_current_tag{'subsets_and_comments'} .= $ss.' ' if ($ss); # WHITESPACE: workaround to have a separation between the subset name and its comment
			}
			$parent_tag = $parseinst->current_element();
			last SWITCH;
		}
		if ($tag eq OBOINOWL_IN_SUBSET) {
			if (defined $attrs{'rdf:resource'}) {
				my @ss = split(/\//, $attrs{'rdf:resource'});
				my $ss = $ss[$#ss];
				if ($ss) {
					my $term = $result->get_term_by_id($current_term_id);
					$term->subset($ss);
				}
			}
			$parent_tag = $parseinst->current_element();
			last SWITCH;
		}
		if ($tag eq RDF_TYPE && $owl_object_property_tag) { # TransitiveProperty et al.
			if (defined $attrs{'rdf:resource'} && $attrs{'rdf:resource'} =~ m/.*\#(.*)$/) {
				my $current_relationship_type = $result->get_relationship_type_by_id($current_relationship_type_id);
				if ($1 eq 'TransitiveProperty') {
					$current_relationship_type->is_transitive(1);					
				} elsif ($1 eq 'SymmetricProperty') {
					$current_relationship_type->is_symmetric(1);
				}
			}
			$parent_tag = $parseinst->current_element();
			last SWITCH;
		}
	}
}

sub characterData {

	my ($parseinst, $data) = @_;
	
	return unless $tag;
	
	my $bk = $data;
	my $current_term;
	my $current_relationship_type;
	if ($owl_class_tag) { # if we are parsing a class (no metadata elements like DbXref)
		$current_term = $result->get_term_by_id($current_term_id);
	} elsif ($owl_object_property_tag) {
		$current_relationship_type = $result->get_relationship_type_by_id($current_relationship_type_id);
	}
	
	$data =~ s/\n|\t|\r|\\//g;
	return unless $data;
	my $context = join('', $parseinst->context());
	SWITCH : {
		#
		# Ontology data
		#
		if ($parent_tag eq OWL_ONTOLOGY) {
			if ($tag eq OBOINOWL_HAS_DATE) {
				$data_current_tag{'has_date'} .= $data;
				last SWITCH;
			}
			if ($tag eq OBOINOWL_HAS_DEFAULT_NAME_SPACE) {
				$data_current_tag{'default_name_space'} .= $data;
				last SWITCH;
			}
			if ($tag eq RDFS_COMMENT) {
				$data_current_tag{'comment'} .= $data;
				last SWITCH;
			}
			last SWITCH;
		}
		if ($parent_tag eq OBOINOWL_SUBSET) {
			if ($tag eq RDFS_COMMENT) {
				$data_current_tag{'subsets_and_comments'} .= $data;
				last SWITCH;
			}
			last SWITCH;
		}
		#
		# Classes
		#
		if ($parent_tag eq OWL_CLASS) {
			if ($tag eq RDFS_LABEL) {
				$data_current_tag{'name'} .= $data;
				last SWITCH;
			}
			if ($tag eq OBOINOWL_HAS_NAMESPACE) {
				$current_term->namespace($data);
				last SWITCH;
			}
			if ($tag eq RDFS_COMMENT) {
				$data_current_tag{'comment'} .= $data;
				last SWITCH;
			}
			if ($tag eq OBOINOWL_HAS_ALTERNATIVE_ID) {
				$data_current_tag{'alt_id'} .= $data;
				last SWITCH;
			}
			if ($tag eq OBOINOWL_REPLACED_BY) {
				$data_current_tag{'replaced_by'} .= $data;
				last SWITCH;
			}
			if ($tag eq OBOINOWL_CONSIDER) {
				$data_current_tag{'consider'} .= $data;
				last SWITCH;
			}
			last SWITCH;
		}
		if (($parent_tag eq OBOINOWL_DEFINITION) && ($tag eq RDFS_LABEL)) { # is it needed to check that '$tag eq RDFS_LABEL' ?
			$data_current_tag{'def'} .= $data, $def_char = 1 if ($owl_class_tag);
			$data_current_tag{'def'} .= $data, $def_char = 1 if ($owl_object_property_tag);
			last SWITCH;
		}
		if ($context eq CLASS_DEF_DBXREF_LABEL){
			$data_current_tag{+CLASS_DEF_DBXREF_LABEL} .= $data;
			last SWITCH;
		}
		if ($context eq PROP_DEF_DBXREF_LABEL){
			$data_current_tag{+PROP_DEF_DBXREF_LABEL} .= $data;
			last SWITCH;
		}
		if ($context eq CLASS_XREF_LABEL) {
			$data_current_tag{+CLASS_XREF_LABEL} .= $data;
			last SWITCH;	
		}
		if ($context eq PROPERTY_XREF_LABEL) {
			$data_current_tag{+PROPERTY_XREF_LABEL} .= $data;
			last SWITCH;	
		}
		if (($parent_tag eq OBOINOWL_SYNONYM) && ($tag eq RDFS_LABEL)) {
			$type_of_synonym = uc($1) if ($context =~ /(Exact|Broad|Narrow|Related)/);
			$data_current_tag{$type_of_synonym} .= $data;
			last SWITCH;
		}
		if (($context =~ /rdf:RDF(owl:Class|owl:ObjectProperty)oboInOwl:has(Exact|Broad|Narrow|Related)SynonymoboInOwl:Synonym/) && ($tag eq RDFS_LABEL)){
			$data_current_tag{'xref'} .= $data;
			last SWITCH;
		}
		#
		# Properties
		#
		if ($parent_tag eq OWL_OBJECT_PROPERTY) {
			if ($tag eq RDFS_LABEL) {
				$current_relationship_type->name($data);
				last SWITCH;
			}
			if ($tag eq OBOINOWL_HAS_NAMESPACE) {
				$current_relationship_type->namespace($data);
				last SWITCH;
			}
			if ($tag eq RDFS_COMMENT) {
				$current_relationship_type->comment($data);
				last SWITCH;
			}
			if ($tag eq OBOINOWL_HAS_ALTERNATIVE_ID) {
				$data_current_tag{'alt_id'} .= $data;
				last SWITCH;
			}
			if ($tag eq OBOINOWL_REPLACED_BY) {
				$data_current_tag{'replaced_by'} .= $data;
				last SWITCH;
			}
			if ($tag eq OBOINOWL_CONSIDER) {
				$data_current_tag{'consider'} .= $data;
				last SWITCH;
			}
			last SWITCH;
			# TODO Wait until the mapping is more stable, then implement: union, intersection, transitive over, ...
		}
	} # SWITCH
}

sub endElement {

	my( $parseinst, $element ) = @_;
    
	$tag = undef;
	my $current_term;
	my $current_relationship_type;
	if ($owl_class_tag && $current_term_id) { # if we are parsing a class (no metadata elements like DbXref)
		$current_term = $result->get_term_by_id($current_term_id);
	} elsif ($owl_object_property_tag && $current_relationship_type_id) {
		$current_relationship_type = $result->get_relationship_type_by_id($current_relationship_type_id);
	}
	my $context = join('', $parseinst->context());
		      
	SWITCH: {
		if ($element eq OWL_ONTOLOGY) {
			$owl_ontology_tag = 0;
			last SWITCH;
		}
		if ($element eq OBOINOWL_HAS_DATE) {
			my $date = $data_current_tag{'has_date'};
			$result->date($date) if (defined $date);
			$data_current_tag{'has_date'} = undef;
			last SWITCH;
		}
		if ($element eq OBOINOWL_HAS_DEFAULT_NAME_SPACE) {
			my $default_namespace = $data_current_tag{'default_name_space'};
			$result->default_namespace($default_namespace) if (defined $default_namespace);
			$data_current_tag{'default_name_space'} = undef;
			last SWITCH;
		}
		if ($element eq RDFS_LABEL && $context eq CLASS_CONTEXT) {
			$current_term->name($data_current_tag{'name'});
			$data_current_tag{'name'} = undef;
			last SWITCH;
		}
		if ($element eq OWL_CLASS) {
			$owl_class_tag = 0; # not parsing a class anymore
			last SWITCH;
		} 
		if ($element eq OWL_OBJECT_PROPERTY) {
			$owl_object_property_tag = 0; # not parsing a property anymore
			last SWITCH;
		} 
		if ($element eq OBOINOWL_HAS_DEFINITION) {
			$oboinowl_has_definition_tag = 0;
			last SWITCH;
		} 
		if ($element eq OBOINOWL_DEFINITION && $def_char) {
			my $def = char_hex2ascii($data_current_tag{'def'});
			$def =~ s/"/\\"/g;
			$current_term->def()->text($def) if ($owl_class_tag);
			$current_relationship_type->def()->text($def) if ($owl_object_property_tag);
			$oboinowl_definition_tag = 0;
			$def_char = 0;
			$data_current_tag{'def'} = undef;
			last SWITCH;
		} 
		if ($context eq CLASS_DEF_DBXREF) {
			my $label = $data_current_tag{+CLASS_DEF_DBXREF_LABEL};
			if ($label) {
				$label = 'http:'.char_hex2ascii($1) if ($label =~ /URL:http%3A%2F%2F(.*)/);
				$current_term->def()->dbxref_set_as_string('['.$label.']') if (defined $label);
			}
			$data_current_tag{+CLASS_DEF_DBXREF_LABEL} = undef;
			last SWITCH;
		} 
		if ($context eq PROP_DEF_DBXREF) {
			my $label = $data_current_tag{+PROP_DEF_DBXREF_LABEL};
			if ($label) {
				$label = 'http:'.char_hex2ascii($1) if ($label =~ /URL:http%3A%2F%2F(.*)/);
				$current_relationship_type->def()->dbxref_set_as_string('['.$label.']') if (defined $label);
			}
			$data_current_tag{+PROP_DEF_DBXREF_LABEL} = undef;
			last SWITCH;
		} 
		if ($context eq CLASS_XREF) {
			my $label = $data_current_tag{+CLASS_XREF_LABEL};
			$current_term->xref_set_as_string($label) if (defined $label);
			$data_current_tag{+CLASS_XREF_LABEL} = undef;
			last SWITCH;
		} 
		if ($context eq PROPERTY_XREF) {
			my $label = $data_current_tag{+PROPERTY_XREF_LABEL};
			$current_relationship_type->xref_set_as_string($label) if (defined $label);
			$data_current_tag{+PROPERTY_XREF_LABEL} = undef;
			last SWITCH;
		} 
		if ($element eq RDFS_COMMENT) {
			my $comment = $data_current_tag{'comment'};
			my $subsets_and_comment = $data_current_tag{'subsets_and_comments'};
			if (defined $comment) {
				if ($owl_class_tag) {
					$current_term->comment($comment);
				} elsif ($owl_object_property_tag) {
					$current_relationship_type->comment($comment);
				} elsif ($owl_ontology_tag) {
					$result->remarks($comment);
				}
			} elsif (defined $subsets_and_comment) {
				$result->subset_def_set($subsets_and_comment);
			}
			$data_current_tag{'comment'} = undef;
			$data_current_tag{'subsets_and_comments'} = undef;
			last SWITCH;
		} 
		if ($element eq OBOINOWL_HAS_ALTERNATIVE_ID) {
			my $alt_id = $data_current_tag{'alt_id'};
			$current_term->alt_id($alt_id) if (defined $alt_id);
			$data_current_tag{'alt_id'} = undef;
			last SWITCH;
		} 
		if ($element eq OBOINOWL_REPLACED_BY) {
			my $replaced_by = $data_current_tag{'replaced_by'};
			$current_term->alt_id($replaced_by) if (defined $replaced_by);
			$data_current_tag{'replaced_by'} = undef;
			last SWITCH;
		} 
		if ($element eq OBOINOWL_CONSIDER) {
			my $consider = $data_current_tag{'consider'};
			$current_term->alt_id($consider) if (defined $consider);
			$data_current_tag{'consider'} = undef;
			last SWITCH;
		} 
		if ($element eq OBOINOWL_SYNONYM) { # && $context =~ /rdf:RDFowl:ClassoboInOwl:has(Exact|Broad|Narrow|Related)SynonymoboInOwl:Synonym/
			my $ref_label = $data_current_tag{'xref'};
			my $data_syn  = $data_current_tag{$type_of_synonym};
			my $sref = ($ref_label)?'['.$ref_label.']':'[]';
			if (defined $data_syn) {
				# Future improvement: get the 'synonym type name' and process it
				$current_term->synonym_as_string($data_syn, $sref, $type_of_synonym) if (defined $current_term);
				$current_relationship_type->synonym_as_string($data_syn, $sref, $type_of_synonym) if (defined $current_relationship_type);
			}
			$data_current_tag{$type_of_synonym} = undef;
			$data_current_tag{'xref'} = undef;			
			last SWITCH;
		} 
		if ($element eq OBOINOWL_HAS_EXACT_SYNONYM) {
			$whitin_a_synonym = 0;
			last SWITCH;
		} 
		if ($element eq OBOINOWL_HAS_BROAD_SYNONYM) {
			$whitin_a_synonym = 0;
			last SWITCH;
		} 
		if ($element eq OBOINOWL_HAS_NARROW_SYNONYM) {
			$whitin_a_synonym = 0;
			last SWITCH;
		} 
		if ($element eq OBOINOWL_HAS_RELATED_SYNONYM) {
			$whitin_a_synonym = 0;
			last SWITCH;
		}		
	}
}

=head2 owl_id2obo_id

  Usage    - $obj->owl_id2obo_id($term)
  Returns  - the ID for OBO representation.
  Args     - the OWL-type ID.
  Function - Transform an OWL-type ID into an OBO-type one. E.g. APO_I1234567 -> APO:I1234567
  
=cut

sub owl_id2obo_id {
	croak "owl_id2obo_id: Invalid argument: '", $_[0], "'", if ($_[0] !~ /_/);
	$_[0] =~ tr/_/:/;
	return $_[0];
}

=head2 char_hex_http

  Usage    - $obj->char_hex_http($seq)
  Returns  - the sequence with the hexadecimal representation for the http special characters
  Args     - the sequence of characters
  Function - Transforms a http character to its equivalent one in hexadecimal. E.g. : -> %3A
  
=cut

sub char_hex2ascii {
	my $param = $_[0];
	$param =~ s/%3A/:/g;
	$param =~ s/%3B/;/g;
	$param =~ s/%3C/</g;
	$param =~ s/%3D/=/g;
	$param =~ s/%3E/>/g;
	$param =~ s/%3F/\?/g;
	
#number sign                    #     23   &#035; --> #   &num;      --> &num;
#dollar sign                    $     24   &#036; --> $   &dollar;   --> &dollar;
#percent sign                   %     25   &#037; --> %   &percnt;   --> &percnt;

	$param =~ s/%2F/\//g;
	$param =~ s/%26/&/g;

	return $param;
}

1;

__END__


=head1 NAME

OBO::Parser::OWLParser  - An OWL parser (oboInOwl mapping).
    
=head1 SYNOPSIS

use OBO::Parser::OWLParser;

use strict;

my $my_parser = OBO::Parser::OWLParser->new;

my $ontology = $my_parser->work("apo.owl");

=head1 DESCRIPTION

An OWLParser object works on parsing an OWL file which is compliant with
the OBO to OWL  mapping described here: 

http://www.bioontology.org/wiki/index.php/OboInOwl:Main_Page

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut