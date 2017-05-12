# $Id: Term.pm 2013-06-06 erick.antezana $
#
# Module  : Term.pm
# Purpose : Term of an Ontology.
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#
package OBO::Core::Term;

use OBO::Util::InstanceSet;
use OBO::Core::Synonym;
use OBO::Util::SynonymSet;

use Carp;
use strict;
use warnings;

sub new {
	my $class                   = shift;
	my $self                    = {};

	$self->{ID}                 = undef;                        # required, scalar (1)
	$self->{IS_ANONYMOUS}       = undef;                        # [1|0], 0 by default
	$self->{NAME}               = undef;                        # not required since OBO spec 1.4, scalar (0..1)
	$self->{NAMESPACE_SET}      = OBO::Util::Set->new();        # set (0..N)
	$self->{ALT_ID}             = OBO::Util::Set->new();        # set (0..N)
	$self->{BUILTIN}            = undef;                        # [1|0], 0 by default
	$self->{DEF}                = OBO::Core::Def->new();        # (0..1)
	$self->{COMMENT}            = undef;                        # scalar (0..1)
	$self->{SUBSET_SET}         = OBO::Util::Set->new();        # set of scalars (0..N)
	$self->{SYNONYM_SET}        = OBO::Util::SynonymSet->new(); # set of synonyms (0..N)
	$self->{XREF_SET}           = OBO::Util::DbxrefSet->new();  # set of dbxref's (0..N)
	$self->{PROPERTY_VALUE}     = OBO::Util::ObjectSet->new();  # set of objects: rel's Term->Instance or Term->Datatype (0..N)
	$self->{CLASS_OF}           = OBO::Util::InstanceSet->new();# set of instances (0..N)
	$self->{INTERSECTION_OF}    = OBO::Util::Set->new();        # (0..N) with N=0, 2, 3, ...
	$self->{UNION_OF}           = OBO::Util::Set->new();        # (0..N) with N=0, 2, 3, ...
	$self->{DISJOINT_FROM}      = OBO::Util::Set->new();        # (0..N)
	$self->{CREATED_BY}         = undef;                        # scalar (0..1)
	$self->{CREATION_DATE}      = undef;                        # scalar (0..1)
	$self->{MODIFIED_BY}        = undef;                        # scalar (0..1)
	$self->{MODIFICATION_DATE}  = undef;                        # scalar (0..1)
	$self->{IS_OBSOLETE}        = undef;                        # [1|0], 0 by default
	$self->{REPLACED_BY}        = OBO::Util::Set->new();        # set of scalars (0..N)
	$self->{CONSIDER}           = OBO::Util::Set->new();        # set of scalars (0..N)

	bless ($self, $class);
	return $self;
}

=head2 id

  Usage    - print $term->id() or $term->id($id) 
  Returns  - the term ID (string)
  Args     - the term ID (string)
  Function - gets/sets the ID of this term
  
=cut

sub id {
	if ($_[1]) { $_[0]->{ID} = $_[1] }
	return $_[0]->{ID};
}

=head2 idspace

  Usage    - print $term->idspace() 
  Returns  - the idspace of this term; otherwise, 'NN'
  Args     - none
  Function - gets the idspace of this term # TODO Does this method still makes sense?
  
=cut

sub idspace {
	$_[0]->{ID} =~ /([A-Za-z_]+):/ if ($_[0]->{ID});
	return $1 || 'NN';
}

=head2 subnamespace

  Usage    - print $term->subnamespace() 
  Returns  - the subnamespace of this term (character); otherwise, 'X'
  Args     - none
  Function - gets the subnamespace of this term
  
=cut

sub subnamespace {
	$_[0]->{ID} =~ /:([A-Z][a-z]?)/ if ($_[0]->{ID});
	return $1 || 'X';
}

=head2 code

  Usage    - print $term->code() 
  Returns  - the code of this term (character); otherwise, '0000000'
  Args     - none
  Function - gets the code of this term
  
=cut

sub code {
	$_[0]->{ID} =~ /:[A-Z]?[a-z]?(.*)/ if ($_[0]->{ID});	
	return $1 || '0000000';
}

=head2 name

  Usage    - print $term->name() or $term->name($name)
  Returns  - the name (string) of this term
  Args     - the name (string) of this term
  Function - gets/sets the name of this term
  
=cut

sub name {
	if ($_[1]) { $_[0]->{NAME} = $_[1] }
	return $_[0]->{NAME};
}

=head2 is_anonymous

  Usage    - print $term->is_anonymous() or $term->is_anonymous("1")
  Returns  - either 1 (true) or 0 (false)
  Args     - either 1 (true) or 0 (false)
  Function - tells whether this term is anonymous or not.
  
=cut

sub is_anonymous {
    if (defined $_[1] && ($_[1] == 1 || $_[1] == 0)) { $_[0]->{IS_ANONYMOUS} = $_[1] }
    return ($_[0]->{IS_ANONYMOUS} && $_[0]->{IS_ANONYMOUS} == 1)?1:0;
}

=head2 alt_id

  Usage    - $term->alt_id() or $term->alt_id($id1, $id2, $id3, ...)
  Returns  - a set (OBO::Util::Set) with the alternate id(s) of this term
  Args     - the alternate id(s) (string) of this term
  Function - gets/sets the alternate id(s) of this term
  
=cut

sub alt_id {
	my $self = shift;
	if (scalar(@_) > 1) {
   		$self->{ALT_ID}->add_all(@_);
	} elsif (scalar(@_) == 1) {
		$self->{ALT_ID}->add(shift);
	}
	return $self->{ALT_ID};
}

=head2 def

  Usage    - $term->def() or $term->def($def)
  Returns  - the definition (OBO::Core::Def) of this term
  Args     - the definition (OBO::Core::Def) of this term
  Function - gets/sets the definition of the term
  
=cut

sub def {
	$_[0]->{DEF} = $_[1] if ($_[1]);
    return $_[0]->{DEF};
}

=head2 def_as_string

  Usage    - $term->def_as_string() or $term->def_as_string("During meiosis, the synthesis of DNA proceeding from the broken 3' single-strand DNA end that uses the homologous intact duplex as the template.", "[GOC:elh, PMID:9334324]")
  Returns  - the definition (string) of this term
  Args     - the definition (string) of this term plus the dbxref list (string) describing the source of this definition
  Function - gets/sets the definition of this term
  Remark   - make sure that colons (,) are scaped (\,) when necessary
  
=cut

sub def_as_string {
	my $dbxref_as_string = $_[2];
	if (defined $_[1] && defined $dbxref_as_string) {
		my $def = $_[0]->{DEF};
		$def->text($_[1]);
		my $dbxref_set = OBO::Util::DbxrefSet->new(); 
		
		my ($e, $entry) = __dbxref($dbxref_set, $dbxref_as_string);
		if ($e == -1) {
			croak "ERROR: Check the 'dbxref' field of '", $entry, "' (term ID = ", $_[0]->id(), ")." ;
		}
		
		$def->dbxref_set($dbxref_set);
	}
	
	my @sorted_dbxrefs = map { $_->[0] }             # restore original values
						sort { $a->[1] cmp $b->[1] } # sort
						map  { [$_, lc($_->id())] }  # transform: value, sortkey
						$_[0]->{DEF}->dbxref_set()->get_set();

	my @result = (); # a Set?
	foreach my $dbxref (@sorted_dbxrefs) {
		push @result, $dbxref->as_string();
	}
	my $d = $_[0]->{DEF}->text();
	if (defined $d) {
		return '"'.$_[0]->{DEF}->text().'"'.' ['.join(', ', @result).']';
	} else {
		return '"" ['.join(', ', @result).']';
	}
}

=head2 namespace

  Usage    - $term->namespace() or $term->namespace($ns1, $ns2, $ns3, ...)
  Returns  - an array with the namespace(s) to which this term belongs
  Args     - the namespace(s) to which this term belongs
  Function - gets/sets the namespace(s) to which this term belongs
  
=cut

sub namespace {
	my $self = shift;
	if (scalar(@_) > 1) {
		$self->{NAMESPACE_SET}->add_all(@_);
	} elsif (scalar(@_) == 1) {
		$self->{NAMESPACE_SET}->add(shift);
	}
	return $self->{NAMESPACE_SET}->get_set();
}

=head2 comment

  Usage    - print $term->comment() or $term->comment("This is a comment")
  Returns  - the comment (string) of this term
  Args     - the comment (string) of this term
  Function - gets/sets the comment of this term
  
=cut

sub comment {
	if (defined $_[1]) { $_[0]->{COMMENT} = $_[1] }
	return $_[0]->{COMMENT};
}

=head2 subset

  Usage    - $term->subset() or $term->subset($ss_name1, $ss_name2, $ss_name3, ...)
  Returns  - an array with the subset name(s) to which this term belongs
  Args     - the subset name(s) (string) to which this term belongs
  Function - gets/sets the subset name(s) to which this term belongs
  
=cut

sub subset {
	my $self = shift;
	if (scalar(@_) > 1) {
   		$self->{SUBSET_SET}->add_all(@_);
	} elsif (scalar(@_) == 1) {
		$self->{SUBSET_SET}->add(shift);
	}
	return $self->{SUBSET_SET}->get_set();
}

=head2 synonym_set

  Usage    - $term->synonym_set() or $term->synonym_set($synonym1, $synonym2, $synonym3, ...)
  Returns  - an array with the synonym(s) of this term
  Args     - the synonym(s) (OBO::Core::Synonym) of this term
  Function - gets/sets the synonym(s) of this term
  Remark1  - if the synonym (text) is already in the set of synonyms of this term, its scope (and their dbxref's) will be updated (provided they have the same synonym type name)
  Remark2  - a synonym text identical to the term name is not added to the set of synonyms of this term
  
=cut

sub synonym_set {
	my $self = shift;
	foreach my $synonym (@_) {
		my $term_name = $self->name();
		if (!defined($term_name)) {
			croak 'The name of this term (', $self->id(), ') is undefined. Add it before adding its synonyms.';
		}
		
		#
		# update the scope (and dbxref's) of a synonym -- if the text and synonym type name are identical in both synonyms
		#
		my $syn_found = 0;
		foreach my $s ($self->{SYNONYM_SET}->get_set()) {
			
			if ($s->def()->text() eq $synonym->def()->text()) {   # if that SYNONYM is already in the set
			
				my $synonym_type_name = $synonym->synonym_type_name();
				my $s_type_name       = $s->synonym_type_name();
				if ($synonym_type_name || $s_type_name) {       # if any of their STN's is defined
					if ($s_type_name && $synonym_type_name && ($s_type_name eq $synonym_type_name)) {   # they should be identical
					
						$s->def()->dbxref_set($synonym->def()->dbxref_set);  # then update its DBXREFs!
						$s->scope($synonym->scope);                          # then update its SCOPE!
					
						$syn_found = 1;
						last;
					}
				} else {
					$s->def()->dbxref_set($synonym->def()->dbxref_set);      # then update its DBXREFs!
					$s->scope($synonym->scope);                              # then update its SCOPE!
				
					$syn_found = 1;
					last;
				}
			}
		}
		
		# do not add 'EXACT' synonyms with the same 'name':
		if (!$syn_found && !($synonym->scope() eq 'EXACT' && $synonym->def()->text() eq $term_name)) {
			$self->{SYNONYM_SET}->add($synonym) || warn "ERROR: the synonym (", $synonym->def()->text(), ") was not added!!"; 
		}
   	}
	return $self->{SYNONYM_SET}->get_set();
}

=head2 synonym_as_string

  Usage    - print $term->synonym_as_string() or $term->synonym_as_string('this is a synonym text', '[APO:ea]', 'EXACT', 'UK_SPELLING')
  Returns  - an array with the synonym(s) of this term
  Args     - the synonym text (string), the dbxrefs (string), synonym scope (string) of this term, and optionally the synonym type name (string)
  Function - gets/sets the synonym(s) of this term
  Remark1  - if the synonym (text) is already in the set of synonyms of this term, its scope (and their dbxref's) will be updated (provided they have the same synonym type name)
  Remark2  - a synonym text identical to the term name is not added to the set of synonyms of this term
  
=cut

sub synonym_as_string {
	if ($_[1] && $_[2] && $_[3]) {
		my $synonym = OBO::Core::Synonym->new();
		$synonym->def_as_string($_[1], $_[2]);
		$synonym->scope($_[3]);
		$synonym->synonym_type_name($_[4]); # optional argument
		$_[0]->synonym_set($synonym);
	}
	
	my @sorted_syns = map { $_->[0] }                       # restore original values
					sort { $a->[1] cmp $b->[1] }            # sort
					map  { [$_, lc($_->def_as_string())] }  # transform: value, sortkey
					$_[0]->{SYNONYM_SET}->get_set();

	my @result;
	my $s_as_string;
	foreach my $synonym (@sorted_syns) {
		my $syn_scope = $synonym->scope();
		if ($syn_scope) {
			my $syn_type_name = $synonym->synonym_type_name();
			if ($syn_type_name) {
				$s_as_string = ' '.$syn_scope.' '.$syn_type_name;
			} else {
				$s_as_string = ' '.$syn_scope;
			}
		} else {
			# This case should never happen since the SCOPE is mandatory!
			warn "The scope of this synonym is not defined: ", $synonym->def()->text();
		}
		
		push @result, $synonym->def_as_string().$s_as_string;
   	}
	return @result;
}

=head2 xref_set

  Usage    - $term->xref_set() or $term->xref_set($dbxref_set)
  Returns  - a Dbxref set (OBO::Util::DbxrefSet) with the analogous xref(s) of this term in another vocabulary
  Args     - a set of analogous xref(s) (OBO::Util::DbxrefSet) of this term in another vocabulary
  Function - gets/sets the analogous xref(s) set of this term in another vocabulary
  
=cut

sub xref_set {
	$_[0]->{XREF_SET} = $_[1] if ($_[1]);
	return $_[0]->{XREF_SET};
}

=head2 xref_set_as_string

  Usage    - $term->xref_set_as_string() or $term->xref_set_as_string("[Reactome:20610, EC:2.3.2.12]")
  Returns  - the dbxref set with the analogous xref(s) of this term; [] if the set is empty
  Args     - the dbxref set with the analogous xref(s) of this term
  Function - gets/sets the dbxref set with the analogous xref(s) of this term
  Remark   - make sure that colons (,) are scaped (\,) when necessary
  
=cut

sub xref_set_as_string {
	my $xref_as_string = $_[1];
	if ($xref_as_string) {
		my $xref_set = $_[0]->{XREF_SET};
		
		my ($e, $entry) = __dbxref($xref_set, $xref_as_string);
		if ($e == -1) {
			croak "ERROR: Check the 'dbxref' field of '", $entry, "' (term ID = ", $_[0]->id(), ")." ;
		}

		$_[0]->{XREF_SET} = $xref_set; # We are overwriting the existing set; otherwise, add the new elements to the existing set!
	}
	my @result = $_[0]->xref_set()->get_set();
}

=head2 property_value

  Usage    - $term->property_value() or $term->property_value($p_value1, $p_value2, $p_value3, ...)
  Returns  - an array with the property value(s) of this term
  Args     - the relationship(s) (OBO::Core::Relationship) of this term with its property value(s)
  Function - gets/sets the property_value(s) of this term
  Remark   - WARNING: this code might change!
  
=cut

sub property_value {
	# TODO WARNING: this code might change!
	my ($self, @co) = @_;
	
	foreach my $i (@co) {
		$self->{PROPERTY_VALUE}->add($i);
	}
	return $self->{PROPERTY_VALUE};
}

=head2 class_of

  Usage    - $term->class_of() or $term->class_of($instance1, $instance2, $instance3, ...)
  Returns  - an array with the instance(s) of this term
  Args     - the instance(s) (OBO::Core::Instance) of this term
  Function - gets/sets the instance(s) of this term
  
=cut

sub class_of {
	my ($self, @co) = @_;
	
	foreach my $i (@co) {
		$self->{CLASS_OF}->add($i);
		$i->instance_of($self); # make the instance aware of its class (term)
	}
	return $self->{CLASS_OF};
}

=head2 is_class_of

  Usage    - $term->is_class_of($instance)
  Returns  - either 1 (true) or 0 (false)
  Args     - an instance (OBO::Core::Instance) of which this object might be class of
  Function - tells whether this object is a class of $instance
  
=cut

sub is_class_of {
	return (defined $_[1] && $_[0]->{CLASS_OF}->contains($_[1]));
}

=head2 intersection_of

  Usage    - $term->intersection_of() or $term->intersection_of($t1, $t2, $r1, ...)
  Returns  - an array with the terms/relations which define this term
  Args     - a set (strings) of terms/relations which define this term
  Function - gets/sets the set of terms/relationships defining this term

=cut

sub intersection_of {
	my $self = shift;
	if (scalar(@_) > 1) {
		$self->{INTERSECTION_OF}->add_all(@_);
	} elsif (scalar(@_) == 1) {
		$self->{INTERSECTION_OF}->add(shift);
	}
	return $self->{INTERSECTION_OF}->get_set();
}

=head2 union_of
        
  Usage    - $term->union_of() or $term->union_of($t1, $t2, $r1, ...)
  Returns  - an array with the terms/relations which define this term
  Args     - a set (strings) of terms/relations which define this term
  Function - gets/sets the set of terms/relationships defining this term

=cut   
 
sub union_of {
	my $self = shift;
	if (scalar(@_) > 1) {
		$self->{UNION_OF}->add_all(@_);
	} elsif (scalar(@_) == 1) { 
		$self->{UNION_OF}->add(shift);
	}
	return $self->{UNION_OF}->get_set();
} 

=head2 disjoint_from

  Usage    - $term->disjoint_from() or $term->disjoint_from($disjoint_term_id1, $disjoint_term_id2, $disjoint_term_id3, ...)
  Returns  - the disjoint term id(s) (string(s)) from this one
  Args     - the term id(s) (string) that is (are) disjoint from this one
  Function - gets/sets the disjoint term(s) from this one

=cut

sub disjoint_from {
	my $self = shift;
	if (scalar(@_) > 1) {
   		$self->{DISJOINT_FROM}->add_all(@_);
	} elsif (scalar(@_) == 1) {
		$self->{DISJOINT_FROM}->add(shift);
	}
	return $self->{DISJOINT_FROM}->get_set();
}

=head2 created_by

  Usage    - print $term->created_by() or $term->created_by("erick_antezana")
  Returns  - name (string) of the creator of the term, may be a short username, initials or ID
  Args     - name (string) of the creator of the term, may be a short username, initials or ID
  Function - gets/sets the name of the creator of the term
  
=cut

sub created_by {
	$_[0]->{CREATED_BY} = $_[1] if ($_[1]);
	return $_[0]->{CREATED_BY};
}

=head2 creation_date

  Usage    - print $term->creation_date() or $term->creation_date("2010-04-13T01:32:36Z")
  Returns  - date (string) of creation of the term specified in ISO 8601 format
  Args     - date (string) of creation of the term specified in ISO 8601 format
  Function - gets/sets the date of creation of the term
  Remark   - You can get an ISO 8601 date as follows:
  				use POSIX qw(strftime);
				my $datetime = strftime("%Y-%m-%dT%H:%M:%S", localtime());

=cut

sub creation_date {
	$_[0]->{CREATION_DATE} = $_[1] if ($_[1]);
	return $_[0]->{CREATION_DATE};
}

=head2 modified_by

  Usage    - print $term->modified_by() or $term->modified_by("erick_antezana")
  Returns  - name (string) of the modificator of the term, may be a short username, initials or ID
  Args     - name (string) of the modificator of the term, may be a short username, initials or ID
  Function - gets/sets the name of the modificator of the term
  
=cut

sub modified_by {
	# TODO WARNING: This is not going to be in the OBO spec. Use property_values instead...
	$_[0]->{MODIFIED_BY} = $_[1] if ($_[1]);
	return $_[0]->{MODIFIED_BY};
}

=head2 modification_date

  Usage    - print $term->modification_date() or $term->modification_date("2010-04-13T01:32:36Z")
  Returns  - date (string) of modification of the term specified in ISO 8601 format
  Args     - date (string) of modification of the term specified in ISO 8601 format
  Function - gets/sets the date of modification of the term
  Remark   - You can get an ISO 8601 date as follows:
  				use POSIX qw(strftime);
				my $datetime = strftime("%Y-%m-%dT%H:%M:%S", localtime());
  
=cut

sub modification_date {
	# TODO WARNING: This is not going to be in the OBO spec. Use property_values instead...
	$_[0]->{MODIFICATION_DATE} = $_[1] if ($_[1]);
	return $_[0]->{MODIFICATION_DATE};
}

=head2 is_obsolete

  Usage    - $term->is_obsolete(1) or print $term->is_obsolete()
  Returns  - either 1 (true) or 0 (false)
  Args     - either 1 (true) or 0 (false)
  Function - tells whether the term is obsolete or not. 'false' by default.
  
=cut

sub is_obsolete {
	if (defined $_[1] && ($_[1] == 1 || $_[1] == 0)) { $_[0]->{IS_OBSOLETE} = $_[1] }
    return ($_[0]->{IS_OBSOLETE} && $_[0]->{IS_OBSOLETE} == 1)?1:0;
}

=head2 replaced_by

  Usage    - $term->replaced_by() or $term->replaced_by($id1, $id2, $id3, ...)
  Returns  - a set (OBO::Util::Set) with the id(s) of the replacing term(s)
  Args     - the the id(s) of the replacing term(s) (string)
  Function - gets/sets the the id(s) of the replacing term(s)
  
=cut

sub replaced_by {
	my $self = shift;
	if (scalar(@_) > 1) {
   		$self->{REPLACED_BY}->add_all(@_);
	} elsif (scalar(@_) == 1) {
		$self->{REPLACED_BY}->add(shift);
	}
	return $self->{REPLACED_BY};
}

=head2 consider

  Usage    - $term->consider() or $term->consider($id1, $id2, $id3, ...)
  Returns  - a set (OBO::Util::Set) with the appropiate substitute(s) for an obsolete term
  Args     - the appropiate substitute(s) for an obsolete term (string)
  Function - gets/sets the appropiate substitute(s) for this obsolete term
  
=cut

sub consider {
	my $self = shift;
	if (scalar(@_) > 1) {
   		$self->{CONSIDER}->add_all(@_);
	} elsif (scalar(@_) == 1) {
		$self->{CONSIDER}->add(shift);
	}
	return $self->{CONSIDER};
}

=head2 builtin

  Usage    - $term->builtin() or $term->builtin(1) or $term->builtin(0)
  Returns  - tells if this term is builtin to the OBO format; false by default
  Args     - 1 (true) or 0 (false)
  Function - gets/sets the value indicating whether this term is builtin to the OBO format
  
=cut

sub builtin {
	if (defined $_[1] && ($_[1] == 1 || $_[1] == 0)) { $_[0]->{BUILTIN} = $_[1] }
    return ($_[0]->{BUILTIN} && $_[0]->{BUILTIN} == 1)?1:0;
}

=head2 equals

  Usage    - print $term->equals($another_term)
  Returns  - either 1 (true) or 0 (false)
  Args     - the term (OBO::Core::Term) to compare with
  Function - tells whether this term is equal to the parameter
  
=cut

sub equals {
	if ($_[1] && eval { $_[1]->isa('OBO::Core::Term') }) {
		return (defined $_[1] && $_[0]->{'ID'} eq $_[1]->{'ID'})?1:0;
	} else {
		croak "An unrecognized object type (not a OBO::Core::Term) was found: '", $_[1], "'";
	}
}

sub __dbxref () {
	caller eq __PACKAGE__ or croak "You cannot call this (__dbxref) prived method!";
	#
	# $_[0] ==> set
	# $_[1] ==> dbxref string
	#
	my $dbxref_set       = $_[0];
	my $dbxref_as_string = $_[1];
	
	$dbxref_as_string =~ s/^\[//;
	$dbxref_as_string =~ s/\]$//;
	$dbxref_as_string =~ s/\\,/;;;;/g;  # trick to keep the comma's
	$dbxref_as_string =~ s/\\"/;;;;;/g; # trick to keep the double quote's
	
	my @lineas = $dbxref_as_string =~ /\"([^\"]*)\"/g; # get the double-quoted pieces
	foreach my $l (@lineas) {
		my $cp = $l;
		$l =~ s/,/;;;;/g; # trick to keep the comma's
		$dbxref_as_string =~ s/\Q$cp\E/$l/;
	}

	my $r_db_acc      = qr/([ \*\.\w-]*):([ ;'\#~\w:\\\+\?\{\}\$\/\(\)\[\]\.=&!%_-]*)/o;
	my $r_desc        = qr/\s+\"([^\"]*)\"/o;
	my $r_mod         = qr/\s+(\{[\w ]+=[\w ]+\})/o;
	
	my @dbxrefs = split (',', $dbxref_as_string);

	foreach my $entry (@dbxrefs) {
		my ($match, $db, $acc, $desc, $mod) = undef;
		my $dbxref = OBO::Core::Dbxref->new();
		if ($entry =~ m/$r_db_acc$r_desc$r_mod?/) {
			$db    = __unescape($1);
			$acc   = __unescape($2);
			$desc  = __unescape($3);
			$mod   = __unescape($4) if ($4);
		} elsif ($entry =~ m/$r_db_acc$r_desc?$r_mod?/) {
			$db    = __unescape($1);
			$acc   = __unescape($2);
			$desc  = __unescape($3) if ($3);
			$mod   = __unescape($4) if ($4);
		} else {
			return (-1, $entry);
		}
		
		# set the dbxref:
		$dbxref->name($db.':'.$acc);
		$dbxref->description($desc) if (defined $desc);
		$dbxref->modifier($mod) if (defined $mod);
		$dbxref_set->add($dbxref);
	}
	return 1;
}

sub __unescape {
	caller eq __PACKAGE__ or die;
	my $match = $_[0];
	$match    =~ s/;;;;;/\\"/g;
	$match    =~ s/;;;;/\\,/g;
	return $match;
}

1;

__END__


=head1 NAME

OBO::Core::Term  - A universal/term/class/concept in an ontology.
    
=head1 SYNOPSIS

use OBO::Core::Term;

use OBO::Core::Def;

use OBO::Util::DbxrefSet;

use OBO::Core::Dbxref;

use OBO::Core::Synonym;

use strict;


# three new terms

my $n1 = OBO::Core::Term->new();

my $n2 = OBO::Core::Term->new();

my $n3 = OBO::Core::Term->new();


# id's

$n1->id("APO:P0000001");

$n2->id("APO:P0000002");

$n3->id("APO:P0000003");


# alt_id

$n1->alt_id("APO:P0000001_alt_id");

$n2->alt_id("APO:P0000002_alt_id1", "APO:P0000002_alt_id2", "APO:P0000002_alt_id3", "APO:P0000002_alt_id4");


# name

$n1->name("One");

$n2->name("Two");

$n3->name("Three");


$n1->is_obsolete(1);

$n1->is_obsolete(0);

$n1->is_anonymous(1);

$n1->is_anonymous(0);


# synonyms

my $syn1 = OBO::Core::Synonym->new();

$syn1->scope('EXACT');

my $def1 = OBO::Core::Def->new();

$def1->text("Hola mundo1");

my $sref1 = OBO::Core::Dbxref->new();

$sref1->name("APO:vm");

my $srefs_set1 = OBO::Util::DbxrefSet->new();

$srefs_set1->add($sref1);

$def1->dbxref_set($srefs_set1);

$syn1->def($def1);

$n1->synonym($syn1);


my $syn2 = OBO::Core::Synonym->new();

$syn2->scope('BROAD');

my $def2 = OBO::Core::Def->new();

$def2->text("Hola mundo2");

my $sref2 = OBO::Core::Dbxref->new();

$sref2->name("APO:ls");

$srefs_set1->add_all($sref1);

my $srefs_set2 = OBO::Util::DbxrefSet->new();

$srefs_set2->add_all($sref1, $sref2);

$def2->dbxref_set($srefs_set2);

$syn2->def($def2);

$n2->synonym($syn2);


my $syn3 = OBO::Core::Synonym->new();

$syn3->scope('BROAD');

my $def3 = OBO::Core::Def->new();

$def3->text("Hola mundo2");

my $sref3 = OBO::Core::Dbxref->new();

$sref3->name("APO:ls");

my $srefs_set3 = OBO::Util::DbxrefSet->new();

$srefs_set3->add_all($sref1, $sref2);

$def3->dbxref_set($srefs_set3);

$syn3->def($def3);

$n3->synonym($syn3);


# synonym as string

$n2->synonym_as_string("Hello world2", "[APO:vm2, APO:ls2]", "EXACT");


# creator + date

$n1->created_by("erick_antezana");

$n1->creation_date("2009-04-13T01:32:36Z ");


# xref

$n1->xref("Uno");

$n1->xref("Eins");

$n1->xref("Een");

$n1->xref("Un");

$n1->xref("Uj");

my $xref_length = $n1->xref()->size();


my $def = OBO::Core::Def->new();

$def->text("Hola mundo");

my $ref1 = OBO::Core::Dbxref->new();

my $ref2 = OBO::Core::Dbxref->new();

my $ref3 = OBO::Core::Dbxref->new();


$ref1->name("APO:vm");

$ref2->name("APO:ls");

$ref3->name("APO:ea");


my $refs_set = OBO::Util::DbxrefSet->new();

$refs_set->add_all($ref1,$ref2,$ref3);

$def->dbxref_set($refs_set);

$n1->def($def);

$n2->def($def);


# def as string

$n2->def_as_string("This is a dummy definition", '[APO:vm, APO:ls, APO:ea "Erick Antezana"] {opt=first}');

my @refs_n2 = $n2->def()->dbxref_set()->get_set();

my %r_n2;

foreach my $ref_n2 (@refs_n2) {
	
	$r_n2{$ref_n2->name()} = $ref_n2->name();
	
}


=head1 DESCRIPTION

A Term in the ontology. c.f. OBO flat file specification.

Recommended: http://ontology.buffalo.edu/bfo/Terminology_for_Ontologies.pdf

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut