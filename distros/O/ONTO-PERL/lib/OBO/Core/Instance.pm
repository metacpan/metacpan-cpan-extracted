# $Id: Instance.pm 2011-06-06 erick.antezana $
#
# Module  : Instance.pm
# Purpose : Capture instances in an Ontology.
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#
package OBO::Core::Instance;

use OBO::Core::Relationship;
use OBO::Core::Synonym;
use OBO::Util::SynonymSet;

use Carp;
use strict;

sub new {
	my $class                   = shift;
	my $self                    = {};

	$self->{ID}                 = undef;                        # required, scalar (1)
	$self->{IS_ANONYMOUS}       = undef;                        # [1|0], 0 by default
	$self->{NAME}               = undef;                        # not required since OBO spec 1.4, scalar (0..1)
	$self->{NAMESPACE_SET}      = OBO::Util::Set->new();        # set (0..N)
	$self->{ALT_ID}             = OBO::Util::Set->new();        # set (0..N)
	$self->{BUILTIN}            = undef;                        # [1|0], 0 by default
	$self->{COMMENT}            = undef;                        # scalar (0..1)
	$self->{SUBSET_SET}         = OBO::Util::Set->new();        # set of scalars (0..N)
	$self->{SYNONYM_SET}        = OBO::Util::SynonymSet->new(); # set of synonyms (0..N)
	$self->{XREF_SET}           = OBO::Util::DbxrefSet->new();  # set of dbxref's (0..N)
	$self->{PROPERTY_VALUE}     = OBO::Util::ObjectSet->new();  # set of objects: rel's Instance->Instance or Instance->Datatype (0..N)
	$self->{INSTANCE_OF}        = undef;                        # OBO::Core::Term (0..1)
	$self->{INTERSECTION_OF}    = OBO::Util::Set->new();        # (0..N)
	$self->{UNION_OF}           = OBO::Util::Set->new();        # (0..N)
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

  Usage    - print $instance->id() or $instance->id($id) 
  Returns  - the instance ID (string)
  Args     - the instance ID (string)
  Function - gets/sets the ID of this instance
  
=cut

sub id {
	if (defined $_[1]) { $_[0]->{ID} = $_[1] }
	return $_[0]->{ID};
}

=head2 idspace

  Usage    - print $instance->idspace() 
  Returns  - the idspace of this instance; otherwise, 'NN'
  Args     - none
  Function - gets the idspace of this instance # TODO Does this method still makes sense?
  
=cut

sub idspace {
	$_[0]->{ID} =~ /([A-Za-z_]+):/ if ($_[0]->{ID});
	return $1 || 'NN';
}

=head2 subnamespace

  Usage    - print $instance->subnamespace() 
  Returns  - the subnamespace of this instance (character); otherwise, 'X'
  Args     - none
  Function - gets the subnamespace of this instance
  
=cut

sub subnamespace {
	$_[0]->{ID} =~ /:([A-Z][a-z]?)/ if ($_[0]->{ID});
	return $1 || 'X';
}

=head2 code

  Usage    - print $instance->code() 
  Returns  - the code of this instance (character); otherwise, '0000000'
  Args     - none
  Function - gets the code of this instance
  
=cut

sub code {
	$_[0]->{ID} =~ /:[A-Z]?[a-z]?(.*)/ if ($_[0]->{ID});	
	return $1 || '0000000';
}

=head2 name

  Usage    - print $instance->name() or $instance->name($name)
  Returns  - the name (string) of this instance
  Args     - the name (string) of this instance
  Function - gets/sets the name of this instance
  
=cut

sub name {
	if ($_[1]) { $_[0]->{NAME} = $_[1] }
	return $_[0]->{NAME};
}

=head2 is_anonymous

  Usage    - print $instance->is_anonymous() or $instance->is_anonymous("1")
  Returns  - either 1 (true) or 0 (false)
  Args     - either 1 (true) or 0 (false)
  Function - tells whether this instance is anonymous or not.
  
=cut

sub is_anonymous {
	if (defined $_[1] && ($_[1] == 1 || $_[1] == 0)) { $_[0]->{IS_ANONYMOUS} = $_[1] }
    return ($_[0]->{IS_ANONYMOUS} && $_[0]->{IS_ANONYMOUS} == 1)?1:0;
}

=head2 alt_id

  Usage    - $instance->alt_id() or $instance->alt_id($id1, $id2, $id3, ...)
  Returns  - a set (OBO::Util::Set) with the alternate id(s) of this instance
  Args     - the alternate id(s) (string) of this instance
  Function - gets/sets the alternate id(s) of this instance
  
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

=head2 namespace

  Usage    - $instance->namespace() or $instance->namespace($ns1, $ns2, $ns3, ...)
  Returns  - an array with the namespace(s) to which this instance belongs
  Args     - the namespace(s) to which this instance belongs
  Function - gets/sets the namespace(s) to which this instance belongs
  
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

  Usage    - print $instance->comment() or $instance->comment("This is a comment")
  Returns  - the comment (string) of this instance
  Args     - the comment (string) of this instance
  Function - gets/sets the comment of this instance
  
=cut

sub comment {
	if (defined $_[1]) { $_[0]->{COMMENT} = $_[1] }
	return $_[0]->{COMMENT};
}

=head2 subset

  Usage    - $instance->subset() or $instance->subset($ss_name1, $ss_name2, $ss_name3, ...)
  Returns  - an array with the subset name(s) to which this instance belongs
  Args     - the subset name(s) (string) to which this instance belongs
  Function - gets/sets the subset name(s) to which this instance belongs
  
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

  Usage    - $instance->synonym_set() or $instance->synonym_set($synonym1, $synonym2, $synonym3, ...)
  Returns  - an array with the synonym(s) of this instance
  Args     - the synonym(s) (OBO::Core::Synonym) of this instance
  Function - gets/sets the synonym(s) of this instance
  
=cut

sub synonym_set {
	my $self = shift;
	foreach my $synonym (@_) {
		my $s_name = $self->name();
		if (!defined($s_name)) {
			croak 'The name of this instance (', $self->id(), ') is undefined. Add it before adding its synonyms.';
		}
		
		my $syn_found = 0;
		# update the scope of a synonym
		foreach my $s_text ($self->{SYNONYM_SET}->get_set()) {
			if ($s_text->def()->text() eq $synonym->def()->text()) {     # if that SYNONYM is already in the set
				$s_text->def()->dbxref_set($synonym->def()->dbxref_set); # then update its DBXREFs!
				$s_text->scope($synonym->scope);                         # then update its SCOPE!
				$s_text->synonym_type_name($synonym->synonym_type_name); # and update its SYNONYM_TYPE_NAME!
				$syn_found = 1;
				last;
			}
		}
		
		# do not add 'EXACT' synonyms with the same 'name':
		if (!$syn_found && !($synonym->scope() eq 'EXACT' && $synonym->def()->text() eq $s_name)) {
			$self->{SYNONYM_SET}->add($synonym) 
		}
   	}
	return $self->{SYNONYM_SET}->get_set();
}

=head2 synonym_as_string

  Usage    - print $instance->synonym_as_string() or $instance->synonym_as_string('this is a synonym text', '[APO:ea]', 'EXACT', 'UK_SPELLING')
  Returns  - an array with the synonym(s) of this instance
  Args     - the synonym text (string), the dbxrefs (string), synonym scope (string) of this instance, and optionally the synonym type name (string)
  Function - gets/sets the synonym(s) of this instance
  
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

  Usage    - $instance->xref_set() or $instance->xref_set($dbxref_set)
  Returns  - a Dbxref set (OBO::Util::DbxrefSet) with the analogous xref(s) of this instance in another vocabulary
  Args     - a set of analogous xref(s) (OBO::Util::DbxrefSet) of this instance in another vocabulary
  Function - gets/sets the analogous xref(s) set of this instance in another vocabulary
  
=cut

sub xref_set {
	$_[0]->{XREF_SET} = $_[1] if ($_[1]);
	return $_[0]->{XREF_SET};
}

=head2 xref_set_as_string

  Usage    - $instance->xref_set_as_string() or $instance->xref_set_as_string("[Reactome:20610, EC:2.3.2.12]")
  Returns  - the dbxref set with the analogous xref(s) of this instance; [] if the set is empty
  Args     - the dbxref set with the analogous xref(s) of this instance
  Function - gets/sets the dbxref set with the analogous xref(s) of this instance
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

  Usage    - $instance->property_value() or $instance->property_value($p_value1, $p_value2, $p_value3, ...)
  Returns  - an array with the property value(s) of this instance
  Args     - the relationship(s) (OBO::Core::Relationship) of this instance with its property value(s)
  Function - gets/sets the property_value(s) of this instance
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

=head2 instance_of

  Usage    - $instance->instance_of() or $instance->instance_of($term)
  Returns  - a term (OBO::Core::Term) of which this object is instance of
  Args     - a term (OBO::Core::Term) of which this object is instance of
  Function - gets/sets the term (class) of this instance
  
=cut

sub instance_of {
	if ($_[1]) {
		my $r   = OBO::Core::Relationship->new();
		my $tid = $_[1]->id();
		my $rt  = 'instance_of';
		my $iid = $_[0]->id();
		my $id  = $iid.'_'.$rt.'_'.$tid;

		$r->id($id);
		$r->type($rt);
		$r->link($_[0], $_[1]); # $_[0] --> $r --> $_[1]  == Instance --> rel --> Term
		$_[0]->{INSTANCE_OF} = $r; # only one term (class) per instance 
		
		# make the term aware of its instance
		$_[1]->class_of()->add($_[0]);
	}
	return ($_[0]->{INSTANCE_OF})?$_[0]->{INSTANCE_OF}->head():undef;
}

=head2 is_instance_of

  Usage    - $instance->is_instance_of($term)
  Returns  - either 1 (true) or 0 (false)
  Args     - a term (OBO::Core::Term) of which this object might be instance of
  Function - tells whether this object is instance of $term
  
=cut

sub is_instance_of {
	return ($_[1] && $_[0]->{INSTANCE_OF} && $_[1]->id() eq $_[0]->{INSTANCE_OF}->head()->id());
}

=head2 intersection_of
        
  Usage    - $instance->intersection_of() or $instance->intersection_of($t1, $t2, $r1, ...)
  Returns  - an array with the instances/relations which define this instance
  Args     - a set (strings) of instances/relations which define this instance
  Function - gets/sets the set of instances/relatonships defining this instance
        
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
        
  Usage    - $instance->union_of() or $instance->union_of($t1, $t2, $r1, ...)
  Returns  - an array with the instances/relations which define this instance
  Args     - a set (strings) of instances/relations which define this instance
  Function - gets/sets the set of instances/relatonships defining this instance
        
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

  Usage    - $instance->disjoint_from() or $instance->disjoint_from($disjoint_instance_id1, $disjoint_instance_id2, $disjoint_instance_id3, ...)
  Returns  - the disjoint instance id(s) (string(s)) from this one
  Args     - the instance id(s) (string) that is (are) disjoint from this one
  Function - gets/sets the disjoint instance(s) from this one
  
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

  Usage    - print $instance->created_by() or $instance->created_by("erick_antezana")
  Returns  - name (string) of the creator of the instance, may be a short username, initials or ID
  Args     - name (string) of the creator of the instance, may be a short username, initials or ID
  Function - gets/sets the name of the creator of the instance
  
=cut

sub created_by {
	$_[0]->{CREATED_BY} = $_[1] if ($_[1]);
	return $_[0]->{CREATED_BY};
}

=head2 creation_date

  Usage    - print $instance->creation_date() or $instance->creation_date("2010-04-13T01:32:36Z")
  Returns  - date (string) of creation of the instance specified in ISO 8601 format
  Args     - date (string) of creation of the instance specified in ISO 8601 format
  Function - gets/sets the date of creation of the instance
  
=cut

sub creation_date {
	$_[0]->{CREATION_DATE} = $_[1] if ($_[1]);
	return $_[0]->{CREATION_DATE};
}

=head2 modified_by

  Usage    - print $instance->modified_by() or $instance->modified_by("erick_antezana")
  Returns  - name (string) of the modificator of the instance, may be a short username, initials or ID
  Args     - name (string) of the modificator of the instance, may be a short username, initials or ID
  Function - gets/sets the name of the modificator of the instance
  
=cut

sub modified_by {
	$_[0]->{MODIFIED_BY} = $_[1] if ($_[1]);
	return $_[0]->{MODIFIED_BY};
}

=head2 modification_date

  Usage    - print $instance->modification_date() or $instance->modification_date("2010-04-13T01:32:36Z")
  Returns  - date (string) of modification of the instance specified in ISO 8601 format
  Args     - date (string) of modification of the instance specified in ISO 8601 format
  Function - gets/sets the date of modification of the instance
  
=cut

sub modification_date {
	$_[0]->{MODIFICATION_DATE} = $_[1] if ($_[1]);
	return $_[0]->{MODIFICATION_DATE};
}

=head2 is_obsolete

  Usage    - print $instance->is_obsolete()
  Returns  - either 1 (true) or 0 (false)
  Args     - either 1 (true) or 0 (false)
  Function - tells whether the instance is obsolete or not. 'false' by default.
  
=cut

sub is_obsolete {
	if (defined $_[1] && ($_[1] == 1 || $_[1] == 0)) { $_[0]->{IS_OBSOLETE} = $_[1] }
    return ($_[0]->{IS_OBSOLETE} && $_[0]->{IS_OBSOLETE} == 1)?1:0;
}

=head2 replaced_by

  Usage    - $instance->replaced_by() or $instance->replaced_by($id1, $id2, $id3, ...)
  Returns  - a set (OBO::Util::Set) with the id(s) of the replacing instance(s)
  Args     - the the id(s) of the replacing instance(s) (string)
  Function - gets/sets the the id(s) of the replacing instance(s)
  
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

  Usage    - $instance->consider() or $instance->consider($id1, $id2, $id3, ...)
  Returns  - a set (OBO::Util::Set) with the appropiate substitute(s) for an obsolete instance
  Args     - the appropiate substitute(s) for an obsolete instance (string)
  Function - gets/sets the appropiate substitute(s) for this obsolete instance
  
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

  Usage    - $instance->builtin() or $instance->builtin(1) or $instance->builtin(0)
  Returns  - tells if this instance is builtin to the OBO format; false by default
  Args     - 1 (true) or 0 (false)
  Function - gets/sets the value indicating whether this instance is builtin to the OBO format
  
=cut

sub builtin {
	if (defined $_[1] && ($_[1] == 1 || $_[1] == 0)) { $_[0]->{BUILTIN} = $_[1] }
    return ($_[0]->{BUILTIN} && $_[0]->{BUILTIN} == 1)?1:0;
}

=head2 equals

  Usage    - print $instance->equals($another_instance)
  Returns  - either 1 (true) or 0 (false)
  Args     - the instance (OBO::Core::Instance) to compare with
  Function - tells whether this instance is equal to the parameter
  
=cut

sub equals {
	my ($self, $target) = @_;
	if ($_[1] && eval { $_[1]->isa('OBO::Core::Instance') }) {
		return (defined $_[1] && $_[0]->{'ID'} eq $_[1]->{'ID'})?1:0;
	} else {
		croak "An unrecognized object type (not a OBO::Core::Instance) was found: '", $_[1], "'";
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
	
	my @dbxrefs = split (',', $dbxref_as_string);
	
	my $r_db_acc      = qr/([ \*\.\w-]*):([ '\#~\w:\\\+\?\{\}\$\/\(\)\[\]\.=&!%_-]*)/o;
	my $r_desc        = qr/\s+\"([^\"]*)\"/o;
	my $r_mod         = qr/\s+(\{[\w ]+=[\w ]+\})/o;
	
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
	$match =~ s/;;;;;/\\"/g;
	$match =~ s/;;;;/\\,/g;
	return $match;
}

1;

__END__


=head1 NAME

OBO::Core::Instance  - An instance in an ontology.
    
=head1 SYNOPSIS

use OBO::Core::Instance;

use OBO::Core::Def;

use OBO::Util::DbxrefSet;

use OBO::Core::Dbxref;

use OBO::Core::Synonym;

use strict;


# three new instances

my $n1 = OBO::Core::Instance->new();

my $n2 = OBO::Core::Instance->new();

my $n3 = OBO::Core::Instance->new();


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


=head1 DESCRIPTION

A Instance in the ontology. c.f. OBO flat file specification.

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut