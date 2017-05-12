# $Id: OBOParser.pm 2015-02-14 erick.antezana $
#
# Module  : OBOParser.pm
# Purpose : Parse OBO-formatted files.
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#
package OBO::Parser::OBOParser;

use OBO::Core::Dbxref;
use OBO::Core::Instance;
use OBO::Core::Ontology;
use OBO::Core::Relationship;
use OBO::Core::RelationshipType;
use OBO::Core::SubsetDef;
use OBO::Core::SynonymTypeDef;
use OBO::Core::Term;
use OBO::Util::IDspaceSet;
use OBO::Util::Set;
use OBO::XO::OBO_ID;

use Carp;
use Date::Manip qw(ParseDate UnixDate);
use strict;
use warnings;

use open qw(:std :utf8); # Make All I/O Default to UTF-8

$Carp::Verbose = 1;

sub new {
	my $class         = shift;
	my $self          = {};
	
	$self->{OBO_FILE} = undef; # required, (1)
        
	bless ($self, $class);
	return $self;
}

=head2 work

  Usage    - $OBOParser->work($obo_file_path)
  Returns  - the parsed OBO ontology
  Args     - the OBO file to be parsed
  Function - parses an OBO file
  
=cut

sub work {
	my $self = shift;
	if (defined $_[0]) {
		$self->{OBO_FILE} = shift;
	} else {
		croak 'You have to provide an OBO file as input';
	}
	
	open (OBO_FILE, $self->{OBO_FILE}) || croak 'The OBO file (', $self->{OBO_FILE}, ') cannot be opened: ', $!;
	
	$/ = ""; # one paragraph at the time
	chomp(my @chunks = <OBO_FILE>);
	chomp(@chunks);
	close OBO_FILE;

	#
	# Treat OBO file header tags
	#
	my $file_line_number = 0;
	if (defined $chunks[0] && $chunks[0] =~ /^format-version:\s*(.*)/) {

		my @header        = split (/\n/, $chunks[0]);
		$file_line_number = $#header + 2; # amount of lines in the header
		$chunks[0]        = join("\n", @header);

		#
		# format-version
		#
		my $format_version;
		if ($chunks[0] =~ /(^format-version:\s*(.*)\n?)/m) { # required tag
			$format_version = $2;
			$chunks[0]      =~ s/$1//;
		}

		#
		# data_version
		#
		my $data_version;
		if ($chunks[0] =~ /(^data-version:\s*(.*)\n?)/m) {
			$data_version = $2;
			$chunks[0]    =~ s/$1//;
		}
		
		#
		# ontology
		#
		my $ontology_id_space;
		if ($chunks[0] =~ /(^ontology:\s*(.*)\n?)/m) { # as of OBO spec 1.4
			$ontology_id_space = $2;
			$chunks[0]         =~ s/$1//;
		}
		
		#
		# date
		#
		my $date;
		if ($chunks[0] =~ /(^date:\s*(.*)\n?)/m) {
			$date      = $2;
			$chunks[0] =~ s/$1//;
		}
		
		#
		# saved_by
		#
		my $saved_by;
		if ($chunks[0] =~ /(^saved-by:\s*(.*)\n?)/m) {
			$saved_by  = $2;
			$chunks[0] =~ s/$1//;
		}

		#
		# auto_generated_by
		#
		my $auto_generated_by;
		if ($chunks[0] =~ /(^auto-generated-by:\s*(.*)\n?)/m) {
			$auto_generated_by = $2;
			$chunks[0]         =~ s/$1//;
		}

		#
		# imports
		#
		my $imports = OBO::Util::Set->new();
		while ($chunks[0] =~ /(^import:\s*(.*)\n?)/m) {
			$imports->add($2);
			$chunks[0] =~ s/$1//;
		}

		#
		# subsetdef
		#
		my $subset_def_map = OBO::Util::SubsetDefMap->new();
		while ($chunks[0] =~ /(^subsetdef:\s*(\S+)\s+\"(.*)\"\n?)/m) {
			my $line = quotemeta($1);
			my $ssd  = OBO::Core::SubsetDef->new();
			$ssd->name($2);
			$ssd->description($3);
			$subset_def_map->put($2, $ssd);
			$chunks[0] =~ s/${line}//;
		}
		
		#
		# synonymtypedef
		#
		my $synonym_type_def_set = OBO::Util::SynonymTypeDefSet->new();
		while ($chunks[0] =~ /(^synonymtypedef:\s*(\S+)\s+\"(.*)\"(.*)?\n?)/m) {
			my $line = quotemeta($1);
			my $std  = OBO::Core::SynonymTypeDef->new();
			$std->name($2);
			$std->description($3);
			my $sc = $4;
			$std->scope($sc) if (defined $sc && $sc =~s/\s//);
			$synonym_type_def_set->add($std);
			$chunks[0] =~ s/${line}//;
		}
		
		#
		# idspace
		#
		my $idspaces = OBO::Util::IDspaceSet->new();
		while ($chunks[0] =~ /(^idspace:\s*(\S+)\s*(\S+)\s+(\"(.*)\")?\n?)/m) {
			my $line        = quotemeta($1);
			my $new_idspace = OBO::Core::IDspace->new();
			$new_idspace->local_idspace($2);
			$new_idspace->uri($3);
			my $dc = $5;
			$new_idspace->description($dc) if (defined $dc);
			$idspaces->add($new_idspace);
			$chunks[0] =~ s/${line}//;
		}
		
		#
		# default-relationship-id-prefix
		# e.g. default-relationship-id-prefix: OBO_REL
		#
		my $default_relationship_id_prefix;
		if ($chunks[0] =~ /(^default_relationship_id_prefix:\s*(.*)\n?)/m) {
			$default_relationship_id_prefix = $2;
			$chunks[0] =~ s/$1//;
		}
		
		#
		# default-namespace
		#
		my $default_namespace;
		if ($chunks[0] =~ /(^default-namespace:\s*(.*)\n?)/m) {
			$default_namespace = $2;
			$chunks[0] =~ s/$1//;
		}		
		
		#
		# remark
		#
		my $remarks = OBO::Util::Set->new();
		while ($chunks[0] =~ /(^remark:\s*(.*)\n?)/m) {
			my $line = quotemeta($1);
			$remarks->add($2);
			$chunks[0] =~ s/${line}//;
		}

		if (!defined $format_version) {
			croak "The OBO file '", $self->{OBO_FILE},"' does not have a correct header, please verify it.";
		}
		
		#
		# treat-xrefs-as-equivalent
		#
		my $treat_xrefs_as_equivalent = OBO::Util::Set->new();
		while ($chunks[0] =~ /(^treat-xrefs-as-equivalent:\s*(.*)\n?)/m) {
			$treat_xrefs_as_equivalent->add($2);
			$chunks[0] =~ s/$1//;
		}
		
		#
		# treat-xrefs-as-is_a
		#
		my $treat_xrefs_as_is_a = OBO::Util::Set->new();
		while ($chunks[0] =~ /(^treat-xrefs-as-is_a:\s*(.*)\n?)/m) {
			$treat_xrefs_as_is_a->add($2);
			$chunks[0] =~ s/$1//;
		}
		
		#
		# store the values in header tags
		#
		my $result = OBO::Core::Ontology->new();
		
		$result->data_version($data_version) if ($data_version);
		$result->id($ontology_id_space) if ($ontology_id_space);
		$result->date($date) if ($date);
		$result->saved_by($saved_by) if ($saved_by);
		#$result->auto_generated_by($auto_generated_by) if ($auto_generated_by);
		$result->subset_def_map($subset_def_map);
		$result->imports($imports->get_set());
		$result->synonym_type_def_set($synonym_type_def_set->get_set());
		$result->idspaces($idspaces->get_set());
		$result->default_relationship_id_prefix($default_relationship_id_prefix) if ($default_relationship_id_prefix);
		$result->default_namespace($default_namespace) if ($default_namespace);
		$result->remarks($remarks->get_set());
		$result->treat_xrefs_as_equivalent($treat_xrefs_as_equivalent->get_set());
		$result->treat_xrefs_as_is_a($treat_xrefs_as_is_a->get_set());

		if ($chunks[0]) {
			print STDERR "The following line(s) has been ignored from the header:\n", $chunks[0], "\n";
		}
		
		#
		# Keep log's
		#
		my %used_subset; # of the used subsets to pin point nonused subsets defined in the header (subsetdef's)
		
		my %used_synonym_type_def; # of the used synonymtypedef to pin point nonused synonymtypedef's defined in the header (synonymtypedef's)
		
		#
		# Regexps
		#
		#my $r_db_acc     = qr/([ \*\.\w-]*):([ '\#~\w:\\\+\?\{\}\$\/\(\)\[\]\.=&!%_,-]*)/o;
		my $r_db_acc     = qr/\s+(\w+:\w+)/o; # TODO check if qr/\s+(\w+:\S+)/o; is better...
		my $r_dbxref     = qr/\s+(\[.*\])/o;
		my $syn_scope    = qr/(\s+(EXACT|BROAD|NARROW|RELATED))?/o;
		my $r_true_false = qr/\s*(true|false)/o; 
		my $r_comments   = qr/\s*(\!\s*(.*))?/o;
		
		my $intersection_of_counter = 0;
		my $union_of_counter        = 0;
		
		my %allowed_data_types = (	'xsd:simpleType' => 1,			# Indicates any primitive type (abstract)
									'xsd:string' => 1,				# A string
									'xsd:integer' => 1,				# Any integer
									'xsd:decimal' => 1,				# Any real number
									'xsd:negativeInteger' => 1,		# Any negative integer
									'xsd:positiveInteger' => 1,		# Any integer > 0
									'xsd:nonNegativeInteger' => 1,	# Any integer >= 0
									'xsd:nonPositiveInteger' => 1,	# Any integer < 0
									'xsd:boolean' => 1,				# True or false
									'xsd:date' => 1					# An XML-Schema date
		);
		
		foreach my $chunk (@chunks) {
			my @entry  = split (/\n/, $chunk);
			my $stanza = shift @entry;
					
			if ($stanza && $stanza =~ /\[Term\]/) { # treat [Term]'s
				
				my $term;
				#
				# to check we have zero or at least two intersection_of's and zero or at least two union_of's
				#
				$intersection_of_counter = 0;
				$union_of_counter        = 0;
				
				$file_line_number++;
				
				my $only_one_id_tag_per_entry   = 0;
				my $only_one_name_tag_per_entry = 0;
				
				foreach my $line (@entry) {
					$file_line_number++;
					if ($line =~ /^id:\s*(\S+)/) { # get the term id
						if ($line =~ /^id:$r_db_acc/) { # Does it follow the "convention"?
							croak "The term with id '", $1, "' has a duplicated 'id' tag in the file '", $self->{OBO_FILE} if ($only_one_id_tag_per_entry);
							$term = $result->get_term_by_id($1); # does this term is already in the ontology?
							if (!defined $term){
								$term = OBO::Core::Term->new();  # if not, create a new term
								$term->id($1);
								$result->add_term($term);        # add it to the ontology
								$only_one_id_tag_per_entry = 1;
							} elsif (defined $term->def()->text() && $term->def()->text() ne '') {
								# The term is already in the ontology since it has a definition! (maybe empty?)
								croak "The term with id '", $1, "' is duplicated in the OBO file.";
							}
						} else {
							carp "The term with id '", $1, "' does NOT follow the ID convention: 'IDSPACE:UNIQUE_IDENTIFIER', e.g. GO:1234567";
						}						
					} elsif ($line =~ /^is_anonymous:$r_true_false/) {
						$term->is_anonymous(($1 eq 'true')?1:0);
					} elsif ($line =~ /^name:\s*(.*)/) {
						carp "The term with id '", $1, "' has a duplicated 'name' tag in the file '", $self->{OBO_FILE} if ($only_one_name_tag_per_entry);
						if (!defined $1) {
							warn "The term with id '", $term->id(), "' has no name in file '", $self->{OBO_FILE}, "'";
						} else {
							$term->name($1);
							$only_one_name_tag_per_entry = 1;
						}
					} elsif ($line =~ /^namespace:\s*(.*)/) {
						$term->namespace($1); # it is a Set
					} elsif ($line =~ /^alt_id:$r_db_acc/) {
						$term->alt_id($1);
					} elsif ($line =~ /^def:\s*\"(.*)\"$r_dbxref/) { # fill the definition
						my $def = OBO::Core::Def->new();
						$def->text($1);
						$def->dbxref_set_as_string($2);
						$term->def($def);
					} elsif ($line =~ /^comment:\s*(.*)/) {
						$term->comment($1);
					} elsif ($line =~ /^subset:\s*(\S+)/) {
						my $ss = $1;
						if ($result->subset_def_map()->contains_key($ss)) {
							$term->subset($ss); # it is a Set (i.e. added to a Set)
							
							$used_subset{$ss}++; # check subsets usage
						} else {
							croak "The subset '", $ss, "' is not defined in the header! Check your OBO file line '", $file_line_number, "'";
						}
					} elsif ($line =~ /^(exact|narrow|broad|related)_synonym:\s*\"(.*)\"$r_dbxref/) { # OBO spec 1.1
						$term->synonym_as_string($2, $3, uc($1));
					} elsif ($line =~ /^synonym:\s*\"(.*)\"$syn_scope(\s+([-\w]+))?$r_dbxref/) {
						my $scope = (defined $3)?$3:'RELATED';
						# As of OBO flat file spec v1.2, we use:
						# synonym: "endomitosis" EXACT []
						if (defined $5) { # if a 'synonym type name' is given
							my $found = 0; # check that the 'synonym type name' was defined in the header!
							foreach my $st ($result->synonym_type_def_set()->get_set()) {
								if ($st->name() eq $5) {
									if (!defined $3) { # if no scope is given, use the one defined in the header!
										my $default_scope = $st->scope();
										$scope = $default_scope if (defined $default_scope);
									}
									$found = 1;
									last;
								}
							}
							croak 'The synonym type name (', $5,') used in line ',  $file_line_number, " in the file '", $self->{OBO_FILE}, "' was not defined" if (!$found);
							$used_synonym_type_def{$5}++; # check synonymtypedef usage
						}
						$term->synonym_as_string($1, $6, $scope, $5);
						
					} elsif ($line =~ /^xref:\s*(.*)/ || $line =~ /^xref_analog:\s*(.*)/ || $line =~ /^xref_unknown:\s*(.*)/) {
						$term->xref_set_as_string($1);
					} elsif ($line =~ /^is_a:$r_db_acc$r_comments/) { # The comment is ignored here but generated later internally
						my $t_id = $term->id();
						if ($t_id eq $1) {
							warn "The term '", $t_id, "' has a reflexive is_a relationship, which was ignored!";
							next;
						}
						my $rel = OBO::Core::Relationship->new();
						$rel->id($t_id.'_is_a_'.$1);
						$rel->type('is_a');
						my $target = $result->get_term_by_id($1); # Is this term already in the ontology?
						if (!defined $target) {
							$target = OBO::Core::Term->new(); # if not, create a new term
							$target->id($1);
							$result->add_term($target);
						}
						$rel->link($term, $target);
						$result->add_relationship($rel);
					} elsif ($line =~ /^intersection_of:\s*([\w\/]+)?$r_db_acc$r_comments/) {
						# TODO Improve the 'intersection_of' treatment
						my $rel = OBO::Core::Relationship->new();
						my $r   = $1 || 'nil';
						my $id  = $term->id().'_'.$r.'_'.$2; 
						$id     =~ s/\s+/_/g;
						$rel->id($id);
						$rel->type($r);
						my $target = $result->get_term_by_id($2); # Is this term already in the ontology?
						if (!defined $target) {
							$target = OBO::Core::Term->new(); # if not, create a new term
							$target->id($2);
							$result->add_term($target);
						}
						$rel->head($target);
						$term->intersection_of($rel);
						$intersection_of_counter++;
					} elsif ($line =~ /^union_of:$r_db_acc$r_comments/) {
						# TODO wait until the OBO spec 1.4 be released
						my $target = $result->get_term_by_id($1); # Is this term already in the ontology?
						if (!defined $target) {
							$target = OBO::Core::Term->new(); # if not, create a new term
							$target->id($1);
							$result->add_term($target);
						}
						$term->union_of($1);
						$union_of_counter++;
					} elsif ($line =~ /^disjoint_from:$r_db_acc$r_comments/) {
						$term->disjoint_from($1); # We are assuming that the other term exists or will exist; otherwise , we have to create it like in the is_a section.
					} elsif ($line =~ /^relationship:\s*([\w\/]+)$r_db_acc$r_comments/ || $line =~ /^relationship:\s*$r_db_acc$r_db_acc$r_comments/) {
						my $rel = OBO::Core::Relationship->new();
						my $id  = $term->id().'_'.$1.'_'.$2; # TODO: I have to standarise the id's: term_id1_db:acc_term_id2
						$id     =~ s/\s+/_/g;
						$rel->id($id);
						$rel->type($1);
						#warn "TYPE : '", $id, "'";
						my $target = $result->get_term_by_id($2); # Is this term already in the ontology?
						if (!defined $target) {
							$target = OBO::Core::Term->new(); # if not, create a new term
							$target->id($2);
							$result->add_term($target);
						}
						$rel->link($term, $target);
						$result->add_relationship($rel);
					} elsif ($line =~ /^created_by:\s*(.*)/) {
						$term->created_by($1);
					} elsif ($line =~ /^creation_date:\s*(.*)/) {
						my $d = $1;
						my $pd = ParseDate($d); # Check that the date follows the ISO 8601 format
						if (!$pd) {
							warn "Bad date string: '", $d, "' in line ", $file_line_number, "\n";
#						} else {
#							my ($year, $month, $day) = UnixDate($pd, "%Y", "%m", "%d");
#							warn "Date was $month/$day/$year\n";
						}
						$term->creation_date($d);
					} elsif ($line =~ /^modified_by:\s*(.*)/) {
						$term->modified_by($1);
					} elsif ($line =~ /^modification_date:\s*(.*)/) {
						my $d = $1;
						my $pd = ParseDate($d); # Check that the date follows the ISO 8601 format
						if (!$pd) {
							warn "Bad date string: '", $d, "' in line ", $file_line_number, "\n";
						}
						$term->modification_date($d);
					} elsif ($line =~ /^is_obsolete:$r_true_false/) {
						$term->is_obsolete(($1 eq 'true')?1:0);
					} elsif ($line =~ /^replaced_by:\s*(.*)/) {
						$term->replaced_by($1);
					} elsif ($line =~ /^consider:\s*(.*)/) {
						$term->consider($1);
					} elsif ($line =~ /^builtin:$r_true_false/) {
						$term->builtin(($1 eq 'true')?1:0);
					} elsif ($line =~ /^property_value:\s*(\w+)$r_db_acc/ || $line =~ /^property_value:\s*(\w+)\s+"([ \°'\#~\w:\\\+\?\{\}\$\/\(\)\[\]\.=&!%_,-]+)"$r_db_acc/) { # TODO some parts in this block might change later on...

						my $relationship_type_id = $1;
						my $value_specifier      = $2;
						my $last_match           = $3;

						my $r2_type = $result->get_relationship_type_by_id($relationship_type_id); # Is this relationship type already in the ontology?
						if (!defined $r2_type){
							$r2_type = OBO::Core::RelationshipType->new();      # if not, create a new relationship type
							$r2_type->id($relationship_type_id);
							$result->add_relationship_type($r2_type);           # add it to the ontology
						}
						#
						# create the triplet
						#						
						my $rel = OBO::Core::Relationship->new();
						my $id  = $term->id().'_'.$relationship_type_id.'_'.$value_specifier;                    # term --> rel --> [term|instance|datatype]
						$id     =~ s/\s+/_/g;
						$rel->id($id);
						$rel->type($r2_type->id());

						if (!defined $last_match) {
							#
							# property_value: lastest_modification_by erick
							#
						    my $target = $result->get_term_by_id($value_specifier);           # suggest to OBOF to define TERMs before they are used so that parsers could know they are dealing with terms!
						    
						    if (defined $target) {                              # term --> rel --> term
						    	
						    } else {
								$target = $result->get_instance_by_id($value_specifier);
								
								if (!defined $target) {                         # term --> rel --> instance
									$target = OBO::Core::Instance->new();
									$target->id($value_specifier);
									$result->add_instance($target);
								}
						    }
						    
							$rel->link($term, $target);                         # triplet: term --> rel --> target
							$term->property_value($rel);
							
							#$result->add_relationship($rel);                   # TODO Do we need this? or better add $ontology->{PROPERTY_VALUES}?
						} elsif (defined $last_match) {                                  # term --> rel --> datatype
							#
							# property_value: lastest_modification_by "erick" xsd:string or e.g. shoe_size "12" xsd:positiveInteger
							#
							my $target = $result->get_instance_by_id($value_specifier);
							
							if (!defined $target) {                             # term --> rel --> datatype
								$target = OBO::Core::Instance->new();
								$target->id($value_specifier);
								
								# data type check
								warn "Unrecommended XML-schema pritive (data type) found: '", $last_match, "'" unless (exists $allowed_data_types{$last_match});
								
								my $data_type = OBO::Core::Term->new();
								$data_type->id($last_match);
								#$result->add_term($data_type);                 # TODO Think about it...
								$target->instance_of($data_type);
								#$result->add_instance($target);                # TODO Think about it...
							}

							$rel->link($term, $target);
							$term->property_value($rel);
							
							#$result->add_relationship($rel);                   # TODO Do we need this? or better add $ontology->{PROPERTY_VALUES}?
						}
					} elsif ($line =~ /^!/) {
						# skip line
					} else {					
						warn 'Unknown syntax found (and ignored) in line: ', $file_line_number, " (in file '", $self->{OBO_FILE}, "'):\n\t", $line, "\n";
					}
				}
				# Check for required fields: id
				if (defined $term && !defined $term->id()) {
					croak "No ID found in term:\n", $chunk;
				}
				if ($intersection_of_counter == 1) { # IDEM TEST: ($intersection_of_counter != 0 && $intersection_of_counter < 2) 
					carp "Missing 'intersection_of' tag in term:\n\n", $chunk, "\n";
				}
				if ($union_of_counter == 1) { # IDEM TEST: ($union_of_counter != 0 && $union_of_counter < 2) 
					carp "Missing 'union_of' tag in term:\n\n", $chunk, "\n";
				}
				$file_line_number++;
			} elsif ($stanza && $stanza =~ /\[Typedef\]/) { # treat [Typedef]
				my $type;
				my $only_one_name_tag_per_entry = 0;
				
				#
				# to check we have zero or at least two intersection_of's and zero or at least two union_of's
				#
				$intersection_of_counter = 0;
				$union_of_counter        = 0;
				
				$file_line_number++;
				foreach my $line (@entry) {
					$file_line_number++;
					if ($line =~ /^id:\s*(.*)/) { # get the type id
						$type = $result->get_relationship_type_by_id($1); # Is this relationship type already in the ontology?
						if (!defined $type){
							$type = OBO::Core::RelationshipType->new();  # if not, create a new type
							$type->id($1);
							$result->add_relationship_type($type);        # add it to the ontology
						} elsif (defined $type->def()->text() && $type->def()->text() ne '') {
							# the type is already in the ontology since it has a definition! (not empty)
							croak "The relationship type with id '", $1, "' is duplicated in the OBO file. Check line: '", $file_line_number, "'";
						} else {
							# the type already in the ontology but with an empty def, which most probably will
							# be defined later. This case is the result of adding a relationship while parsing
							# the Term stanzas.
							#warn "Line: '", $line, "', Def: '", $type->def_as_string(), "'\n";
						}
					} elsif ($line =~ /^is_anonymous:$r_true_false/) {
						$type->is_anonymous(($1 eq 'true')?1:0);
					} elsif ($line =~ /^name:\s*(.*)/) {
						croak "The typedef with id '", $1, "' has a duplicated 'name' tag in the file '", $self->{OBO_FILE}, "'. Check line: '", $file_line_number, "'" if ($only_one_name_tag_per_entry);
						$type->name($1);
						$only_one_name_tag_per_entry = 1;
					} elsif ($line =~ /^namespace:\s*(.*)/) {
						$type->namespace($1); # it is a Set
					} elsif ($line =~ /^alt_id:\s*([:\w]+)/) {
						$type->alt_id($1);
					} elsif ($line =~ /^def:\s*\"(.*)\"$r_dbxref/) { # fill in the definition
						my $def = OBO::Core::Def->new();
						$def->text($1);
						$def->dbxref_set_as_string($2);
						$type->def($def);
					} elsif ($line =~ /^comment:\s*(.*)/) {
						$type->comment($1);
					} elsif ($line =~ /^subset:\s*(\S+)/) {
						my $ss = $1;
						if ($result->subset_def_map()->contains_key($ss)) {
							$type->subset($ss); # it is a Set (i.e. added to a Set)
							
							$used_subset{$ss}++; # check subsets usage
						} else {
							croak "The subset '", $ss, "' is not defined in the header! Check your OBO file relationship type in line: '", $file_line_number, "'";
						}
					} elsif ($line =~ /^domain:\s*(.*)/) {
						$type->domain($1);
					} elsif ($line =~ /^range:\s*(.*)/) {
						$type->range($1);
					} elsif ($line =~ /^is_anti_symmetric:$r_true_false/) {
						$type->is_anti_symmetric(($1 eq 'true')?1:0);
					} elsif ($line =~ /^is_cyclic:$r_true_false/) {
						$type->is_cyclic(($1 eq 'true')?1:0);
					} elsif ($line =~ /^is_reflexive:$r_true_false/) {
						$type->is_reflexive(($1 eq 'true')?1:0);
					} elsif ($line =~ /^is_symmetric:$r_true_false/) {
						$type->is_symmetric(($1 eq 'true')?1:0);
					} elsif ($line =~ /^is_transitive:$r_true_false/) {
						$type->is_transitive(($1 eq 'true')?1:0);
					} elsif ($line =~ /^is_a:\s*([:\w]+)$r_comments/) { # intrinsic or not??? # The comment is ignored here but generated (and sometimes fixed) later internally
						my $r    = $1;
						my $r_id = $type->id();
						if ($r_id eq $r) {
							warn "The term '", $r_id, "' has a reflexive is_a relationship, which was ignored!";
							next;
						}
						my $rel = OBO::Core::Relationship->new();
						$rel->id($r_id.'_is_a_'.$r);
						$rel->type('is_a');
						my $target = $result->get_relationship_type_by_id($r); # Is this relationship type already in the ontology?
						if (!defined $target) {
							$target = OBO::Core::RelationshipType->new(); # if not, create a new relationship type
							$target->id($r);
							$result->add_relationship_type($target);
						}
						$rel->link($type, $target); # add a relationship between two relationship types
						$result->add_relationship($rel);
					} elsif ($line =~ /^is_metadata_tag:$r_true_false/) {
						$type->is_metadata_tag(($1 eq 'true')?1:0);
					} elsif ($line =~ /^is_class_level:$r_true_false/) {
						$type->is_class_level(($1 eq 'true')?1:0);
					} elsif ($line =~ /^(exact|narrow|broad|related)_synonym:\s*\"(.*)\"$r_dbxref/) {
						$type->synonym_as_string($2, $3, uc($1));
					} elsif ($line =~ /^synonym:\s*\"(.*)\"$syn_scope(\s+(\w+))?$r_dbxref/) {
						my $scope = (defined $3)?$3:'RELATED';
						# From OBO flat file spec v1.2, we use:
						# synonym: "endomitosis" EXACT []
						if (defined $5) {
							my $found = 0; # check that the 'synonym type name' was defined in the header!
							foreach my $st ($result->synonym_type_def_set()->get_set()) {
								# Adapt the scope if necessary to the one defined in the header!
								if ($st->name() eq $5) {
									$found = 1;
									my $default_scope = $st->scope();
									$scope = $default_scope if (defined $default_scope);
									last;
								}
							}
							croak 'The synonym type name (', $5,') used in line ',  $file_line_number, " in the file '", $self->{OBO_FILE}, "' was not defined" if (!$found);
							$used_synonym_type_def{$5}++; # check synonymtypedef usage
						}
						$type->synonym_as_string($1, $6, $scope, $5);
					} elsif ($line =~ /^xref:\s*(.*)/ || $line =~ /^xref_analog:\s*(.*)/ || $line =~ /^xref_unk:\s*(.*)/) {
						$type->xref_set_as_string($1);
					} elsif ($line =~ /^intersection_of:\s*([\w\/]+)?$r_db_acc$r_comments/) {
						# TODO Improve the 'intersection_of' treatment
						my $rel = OBO::Core::Relationship->new();
						my $r   = $1 || 'nil';
						my $id  = $type->id().'_'.$r.'_'.$2; 
						$id     =~ s/\s+/_/g;
						$rel->id($id);
						$rel->type($r);
						my $target = $result->get_term_by_id($2); # Is this term already in the ontology?
						if (!defined $target) {
							$target = OBO::Core::Term->new(); # if not, create a new term
							$target->id($2);
							$result->add_term($target);
						}
						$rel->head($target);
						$type->intersection_of($rel);
						$intersection_of_counter++;
					} elsif ($line =~ /^union_of:\s*(.*)/) {
						# TODO wait until the OBO spec 1.4 be released
						my $target = $result->get_relationship_type_by_id($1); # Is this relationship type already in the ontology?
						if (!defined $target) {
							$target = OBO::Core::RelationshipType->new(); # if not, create a new relationship type
							$target->id($1);
							$result->add_relationship_type($target);
						}
						$type->union_of($1);
						$union_of_counter++;
					} elsif ($line =~ /^disjoint_from:\s*([:\w]+)$r_comments/) {
						$type->disjoint_from($1); # We are assuming that the other relation type exists or will exist; otherwise , we have to create it like in the is_a section.
					} elsif ($line =~ /^inverse_of:\s*([:\w]+)$r_comments/) { # e.g. inverse_of: has_participant ! has participant
						my $inv_id   = $1;
						my $inv_type = $result->get_relationship_type_by_id($inv_id); # Is this INVERSE relationship type already in the ontology?
						if (!defined $inv_type){
							$inv_type = OBO::Core::RelationshipType->new();  # if not, create a new type
							$inv_type->id($inv_id);
							#$inv_type->name($3) if ($3); # not necessary, this name could be wrong...
							$result->add_relationship_type($inv_type);       # add it to the ontology
						}
						$type->inverse_of($inv_type);
					} elsif ($line =~ /^transitive_over:\s*(.*)/) {
						$type->transitive_over($1);
					} elsif ($line =~ /^holds_over_chain:\s*([:\w]+)\s*([:\w]+)$r_comments/) { # R <- R1.R2 
						my $r1_id   = $1;
						my $r2_id   = $2;
						my $r1_type = $result->get_relationship_type_by_id($r1_id); # Is this relationship type already in the ontology?
						if (!defined $r1_type){
							$r1_type = OBO::Core::RelationshipType->new();  # if not, create a new type
							$r1_type->id($r1_id);
							$result->add_relationship_type($r1_type);       # add it to the ontology
						}
						my $r2_type = $result->get_relationship_type_by_id($r2_id); # Is this relationship type already in the ontology?
						if (!defined $r2_type){
							$r2_type = OBO::Core::RelationshipType->new();  # if not, create a new type
							$r2_type->id($r2_id);
							$result->add_relationship_type($r2_type);       # add it to the ontology
						}
						$type->holds_over_chain($r1_type->id(), $r2_type->id());
					} elsif ($line =~ /^equivalent_to_chain:\s*(.*)/) {
						# TODO
					} elsif ($line =~ /^disjoint_over:\s*(.*)/) {
						# TODO
					} elsif ($line =~ /^is_functional:$r_true_false/) {
						$type->is_functional(($1 eq 'true')?1:0);
					} elsif ($line =~ /^is_inverse_functional:$r_true_false/) {
						$type->is_inverse_functional(($1 eq 'true')?1:0);
					} elsif ($line =~ /^created_by:\s*(.*)/) {
						$type->created_by($1);
					} elsif ($line =~ /^creation_date:\s*(.*)/) {
						my $d = $1;
						my $pd = ParseDate($d); # Check that the date follows the ISO 8601 format
						if (!$pd) {
							warn "Bad date string: '", $d, "' in line ", $file_line_number, "\n";
						}
						$type->creation_date($d);
					} elsif ($line =~ /^modified_by:\s*(.*)/) {
						$type->modified_by($1);
					} elsif ($line =~ /^modification_date:\s*(.*)/) {
						my $d = $1;
						my $pd = ParseDate($d); # Check that the date follows the ISO 8601 format
						if (!$pd) {
							warn "Bad date string: '", $d, "' in line ", $file_line_number, "\n";
						}
						$type->modification_date($d);
					} elsif ($line =~ /^is_obsolete:\s*(.*)/) {
						$type->is_obsolete(($1 eq 'true')?1:0);
					} elsif ($line =~ /^replaced_by:\s*(.*)/) {
						$type->replaced_by($1);
					} elsif ($line =~ /^consider:\s*(.*)/) {
						$type->consider($1);
					} elsif ($line =~ /^builtin:$r_true_false/) {
						$type->builtin(($1 eq 'true')?1:0);
					} elsif ($line =~ /^!/) {
						# skip line
					} else {
						warn 'Unknown syntax found (and ignored) in line: ', $file_line_number, " (in file '", $self->{OBO_FILE}, "'):\n\t", $line, "\n";
					}	
				}
				# Check for required fields: id
				if (!defined $type->id()) {
					croak "No ID found in type:\n\n", $chunk, "\n\nfrom file '", $self->{OBO_FILE}, "'";
				}
				if ($intersection_of_counter == 1) { # IDEM TEST: ($intersection_of_counter != 0 && $intersection_of_counter < 2) 
					carp "Missing 'intersection_of' tag in relationship type:\n\n", $chunk, "\n";
				}
				if ($union_of_counter == 1) { # IDEM TEST: ($union_of_counter != 0 && $union_of_counter < 2) 
					carp "Missing 'union_of' tag in relationship type:\n\n", $chunk, "\n";
				}
				$file_line_number++;
			} elsif ($stanza && $stanza =~ /\[Instance\]/) { # treat [Instance]
				my $instance;
				
				#
				# to check we have zero or at least two intersection_of's and zero or at least two union_of's
				#
				# TODO do INSTANCES have these tags?
				$intersection_of_counter = 0;
				$union_of_counter        = 0;
				
				$file_line_number++;
				
				my $only_one_id_tag_per_entry   = 0;
				my $only_one_name_tag_per_entry = 0;
				
				foreach my $line (@entry) {
					$file_line_number++;
					if ($line =~ /^id:\s*(\S+)/) { # get the instance id
						if ($line =~ /^id:$r_db_acc/) { # Does it follow the "convention"?
							croak "The instance with id '", $1, "' has a duplicated 'id' tag in the file '", $self->{OBO_FILE} if ($only_one_id_tag_per_entry);
							$instance = $result->get_instance_by_id($1); # does this instance is already in the ontology?
							if (!defined $instance){
								$instance = OBO::Core::Instance->new();  # if not, create a new instance
								$instance->id($1);
								$result->add_instance($instance);        # add it to the ontology
								$only_one_id_tag_per_entry = 1;
							#} elsif (defined $instance->def()->text() && $instance->def()->text() ne '') {
								# TODO Do instances have a definition?
							#	# The instance is already in the ontology since it has a definition! (maybe empty?)
							#	croak "The instance with id '", $1, "' is duplicated in the OBO file.";
							}
						} else {
							croak "The instance with id '", $1, "' does NOT follow the ID convention: 'IDSPACE:UNIQUE_IDENTIFIER', e.g. GO:1234567";
						}						
					} elsif ($line =~ /^is_anonymous:$r_true_false/) {
						$instance->is_anonymous(($1 eq 'true')?1:0);
					} elsif ($line =~ /^name:\s*(.*)/) {
						croak "The instance with id '", $1, "' has a duplicated 'name' tag in the file '", $self->{OBO_FILE} if ($only_one_name_tag_per_entry);
						if (!defined $1) {
							warn "The instance with id '", $instance->id(), "' has no name in file '", $self->{OBO_FILE}, "'";
						} else {
							$instance->name($1);
							$only_one_name_tag_per_entry = 1;
						}
					} elsif ($line =~ /^namespace:\s*(.*)/) {
						$instance->namespace($1); # it is a Set
					} elsif ($line =~ /^alt_id:$r_db_acc/) {
						# TODO do INSTANCES have this tag?
						$instance->alt_id($1);
					} elsif ($line =~ /^def:\s*\"(.*)\"$r_dbxref/) { # fill in the definition
						my $def = OBO::Core::Def->new();
						$def->text($1);
						$def->dbxref_set_as_string($2);
						$instance->def($def);
					} elsif ($line =~ /^comment:\s*(.*)/) {
						$instance->comment($1);
					} elsif ($line =~ /^subset:\s*(\S+)/) {
						my $ss = $1;
						if ($result->subset_def_map()->contains_key($ss)) {
							$instance->subset($ss); # it is a Set (i.e. added to a Set)
							
							$used_subset{$ss}++; # check subsets usage
						} else {
							croak "The subset '", $ss, "' is not defined in the header! Check your OBO file line '", $file_line_number, "'";
						}
					} elsif ($line =~ /^(exact|narrow|broad|related)_synonym:\s*\"(.*)\"$r_dbxref/) { # OBO spec 1.1
						$instance->synonym_as_string($2, $3, uc($1));
					} elsif ($line =~ /^synonym:\s*\"(.*)\"$syn_scope(\s+([-\w]+))?$r_dbxref/) {
						my $scope = (defined $3)?$3:'RELATED';
						# As of OBO flat file spec v1.2, we use:
						# synonym: "endomitosis" EXACT []
						if (defined $5) {
							my $found = 0; # check that the 'synonym type name' was defined in the header!
							foreach my $st ($result->synonym_type_def_set()->get_set()) {
								# Adapt the scope if necessary to the one defined in the header!
								if ($st->name() eq $5) {
									$found = 1;
									my $default_scope = $st->scope();
									$scope = $default_scope if (defined $default_scope);
									last;
								}
							}
							croak 'The synonym type name (', $5,') used in line ',  $file_line_number, " in the file '", $self->{OBO_FILE}, "' was not defined" if (!$found);
							$used_synonym_type_def{$5}++; # check synonymtypedef usage
						}
						$instance->synonym_as_string($1, $6, $scope, $5);
					} elsif ($line =~ /^xref:\s*(.*)/ || $line =~ /^xref_analog:\s*(.*)/ || $line =~ /^xref_unknown:\s*(.*)/) {
						$instance->xref_set_as_string($1);
					} elsif ($line =~ /^instance_of:$r_db_acc$r_comments/) { # The comment is ignored here but retrieved later internally
						my $t = $result->get_term_by_id($1); # Is this instance already in the ontology?
						if (!defined $t) {
							$t = OBO::Core::Term->new(); # if not, create a new Term
							$t->id($1);
							$result->add_term($t);
						}
						$instance->instance_of($t);
					} elsif ($line =~ /^intersection_of:\s*([\w\/]+)?$r_db_acc$r_comments/) {
						# TODO Improve the 'intersection_of' treatment
						# TODO do INSTANCES have this tag?
						my $rel = OBO::Core::Relationship->new();
						my $r   = $1 || 'nil';
						my $id  = $instance->id().'_'.$r.'_'.$2; 
						$id     =~ s/\s+/_/g;
						$rel->id($id);
						$rel->type($r);
						my $target = $result->get_instance_by_id($2); # Is this instance already in the ontology?
						if (!defined $target) {
							$target = OBO::Core::Instance->new(); # if not, create a new instance
							$target->id($2);
							$result->add_instance($target);
						}
						$rel->head($target);
						$instance->intersection_of($rel);
						$intersection_of_counter++;
					} elsif ($line =~ /^union_of:\s*(.*)/) {
						# TODO wait until the OBO spec 1.4 be released
						# TODO do INSTANCES have this tag?
						my $target = $result->get_instance_by_id($1); # Is this instance already in the ontology?
						if (!defined $target) {
							$target = OBO::Core::Instance->new(); # if not, create a new instance
							$target->id($1);
							$result->add_instance($target);
						}
						$instance->union_of($1);
						$union_of_counter++;
					} elsif ($line =~ /^disjoint_from:$r_db_acc$r_comments/) {
						# TODO do INSTANCES have this tag?
						$instance->disjoint_from($1); # We are assuming that the other instance exists or will exist; otherwise , we have to create it like in the is_a section.
					} elsif ($line =~ /^relationship:\s*([\w\/]+)$r_db_acc$r_comments/ || $line =~ /^relationship:\s*$r_db_acc$r_db_acc$r_comments/) {
						# TODO do INSTANCES have this tag?
						my $rel = OBO::Core::Relationship->new();
						my $id  = $instance->id().'_'.$1.'_'.$2; # TODO see the line (TODO) of the 'term' section
						$id     =~ s/\s+/_/g;
						$rel->id($id);
						$rel->type($1);
						my $target = $result->get_instance_by_id($2); # Is this instance already in the ontology?
						if (!defined $target) {
							$target = OBO::Core::Instance->new(); # if not, create a new instance
							$target->id($2);
							$result->add_instance($target);
						}
						$rel->link($instance, $target);
						$result->add_relationship($rel);
					} elsif ($line =~ /^created_by:\s*(.*)/) {
						$instance->created_by($1);
					} elsif ($line =~ /^creation_date:\s*(.*)/) {
						my $d = $1;
						my $pd = ParseDate($d); # Check that the date follows the ISO 8601 format
						if (!$pd) {
							warn "Bad date string: '", $d, "' in line ", $file_line_number, "\n";
						}
						$instance->creation_date($d);
					} elsif ($line =~ /^modified_by:\s*(.*)/) {
						$instance->modified_by($1);
					} elsif ($line =~ /^modification_date:\s*(.*)/) {
						my $d = $1;
						my $pd = ParseDate($d); # Check that the date follows the ISO 8601 format
						if (!$pd) {
							warn "Bad date string: '", $d, "' in line ", $file_line_number, "\n";
						}
						$instance->modification_date($d);
					} elsif ($line =~ /^is_obsolete:$r_true_false/) {
						$instance->is_obsolete(($1 eq 'true')?1:0);
					} elsif ($line =~ /^replaced_by:\s*(.*)/) {
						$instance->replaced_by($1);
					} elsif ($line =~ /^consider:\s*(.*)/) {
						$instance->consider($1);
					} elsif ($line =~ /^builtin:$r_true_false/) {
						# TODO do INSTANCES have this tag?
						$instance->builtin(($1 eq 'true')?1:0);
					} elsif ($line =~ /^property_value:\s*(\w+)$r_db_acc/ || $line =~ /^property_value:\s*(\w+)\s+"([ \°'\#~\w:\\\+\?\{\}\$\/\(\)\[\]\.=&!%_,-]+)"$r_db_acc/) { # TODO some parts in this block might change later on...
					
						my $relationship_type_id = $1;
						my $value_specifier      = $2;
						my $last_match           = $3;
						
						my $r2_type = $result->get_relationship_type_by_id($relationship_type_id); # Is this relationship type already in the ontology?
						if (!defined $r2_type){
							$r2_type = OBO::Core::RelationshipType->new();      # if not, create a new relationship type
							$r2_type->id($relationship_type_id);
							$result->add_relationship_type($r2_type);           # add it to the ontology
						}

						#
						# create the triplet
						#						
						my $rel = OBO::Core::Relationship->new();
						my $id  = $instance->id().'_'.$relationship_type_id.'_'.$value_specifier;                # instance --> rel --> [term|instance|datatype]
						$id     =~ s/\s+/_/g;
						$rel->id($id);
						$rel->type($r2_type->id());
						
						if (!defined $last_match) {
							#
							# property_value: lastest_modification_by erick
							#
						    my $target = $result->get_term_by_id($value_specifier);           # suggest to OBOF to define TERMs before they are used so that parsers could know they are dealing with terms!
						    
						    if (defined $target) {                              # instance --> rel --> term
						    	
						    } else {
								$target = $result->get_instance_by_id($value_specifier);
								
								if (!defined $target) {                         # instance --> rel --> instance
									$target = OBO::Core::Instance->new();
									$target->id($value_specifier);
									$result->add_instance($target);
								}
						    }
						    
							$rel->link($instance, $target);                     # triplet: instance --> rel --> target
							$instance->property_value($rel);
							
							#$result->add_relationship($rel);                   # TODO Do we need this? or better add $ontology->{PROPERTY_VALUES}?
						} elsif (defined $last_match) {                                  # instance --> rel --> datatype
							#
							# property_value: lastest_modification_by "erick" xsd:string or e.g. shoe_size "12" xsd:positiveInteger
							#
							my $target = $result->get_instance_by_id($value_specifier);
							
							if (!defined $target) {                             # instance --> rel --> datatype
								$target = OBO::Core::Instance->new();
								$target->id($value_specifier);
								
								# data type check
								warn "Unrecommended XML-schema pritive (data type) found: '", $last_match, "'" unless (exists $allowed_data_types{$last_match});
								
								my $data_type = OBO::Core::Term->new();
								$data_type->id($last_match);
								#$result->add_term($data_type);                 # TODO Think about it...
								$target->instance_of($data_type);
								#$result->add_instance($target);                # TODO Think about it...
							}

							$rel->link($instance, $target);
							$instance->property_value($rel);
							
							#$result->add_relationship($rel);                   # TODO Do we need this? or better add $ontology->{PROPERTY_VALUES}?
						}						
					} elsif ($line =~ /^!/) {
						# skip line
					} else {					
						warn 'Unknown syntax found (and ignored) in line: ', $file_line_number, " (in file '", $self->{OBO_FILE}, "'):\n\t", $line, "\n";
					}
				}
				# Check for required fields: id
				if (defined $instance && !defined $instance->id()) {
					croak "No ID found in instance:\n", $chunk;
				}
				if ($intersection_of_counter == 1) { # IDEM TEST: ($intersection_of_counter != 0 && $intersection_of_counter < 2)
					 # TODO do INSTANCES have this tag?
					croak "Missing 'intersection_of' tag in instance:\n\n", $chunk, "\n";
				}
				if ($union_of_counter == 1) { # IDEM TEST: ($union_of_counter != 0 && $union_of_counter < 2) 
					carp "Missing 'union_of' tag in instance:\n\n", $chunk, "\n";
				}
				$file_line_number++;
			} elsif ($stanza && $stanza =~ /\[Annotation\]/) { # treat [Annotation]
				# TODO "Annotations are ignored by ONTO-PERL (they might be supported in the future).";
			}
		}
		
		#
		# Warn (and delete) on non used subsets which were defined in the header (subsetdef's)
		#
		my @set_of_all_ss = $result->subset_def_map()->key_set()->get_set();
		foreach my $pss (sort @set_of_all_ss) {
			if (!$used_subset{$pss}) {
				$result->subset_def_map()->remove($pss);
				warn "Unused subset found (and removed): '", $pss, "' (in file '", $self->{OBO_FILE}, "')";
			}
		}
		
		#
		# Warn (and delete) on non used synonym type def's which were defined in the header (synonymtypedef's)
		#
		my @set_of_all_synonymtypedef = $result->synonym_type_def_set()->get_set();
		foreach my $st (@set_of_all_synonymtypedef) {
			if (!$used_synonym_type_def{$st->name()}) {
				$result->synonym_type_def_set()->remove($st);
				warn "Unused synonym type def found (and removed): '", $st->name(), "' (in file '", $self->{OBO_FILE}, "')";
			}
		}
		
		#
		# Work-around for some ontologies like GO: Explicitly add the implicit 'is_a' if missing
		#
		if (!$result->has_relationship_type_id('is_a')){
			my $type = OBO::Core::RelationshipType->new();  # if not, create a new type
			$type->id('is_a');
			$type->name('is_a');
			$result->add_relationship_type($type);
		}
		
		$/ = "\n";

		return $result;
	} else { # if no header (chunk[0])
		carp "The OBO file '", $self->{OBO_FILE},"' does not have a correct header, please verify it.";
	}
}

1;

__END__


=head1 NAME

OBO::Parser::OBOParser  - An OBO (Open Biomedical Ontologies) file parser.
    
=head1 SYNOPSIS

use OBO::Parser::OBOParser;

use strict;

my $my_parser = OBO::Parser::OBOParser->new;

my $ontology = $my_parser->work("apo.obo");

$ontology->has_term($ontology->get_term_by_id("APO:B9999993"));

$ontology->has_term($ontology->get_term_by_name("small molecule"));

$ontology->get_relationship_by_id("APO:B9999998_is_a_APO:B0000000")->type() eq 'is_a';

$ontology->get_relationship_by_id("APO:B9999996_part_of_APO:B9999992")->type() eq 'part_of'; 


my $ontology2 = $my_parser->work("apo.obo");

$ontology2->has_term($ontology2->get_term_by_id("APO:B9999993"));

$ontology2->has_term($ontology2->get_term_by_name("cell cycle"));

$ontology2->get_relationship_by_id("APO:P0000274_is_a_APO:P0000262")->type() eq 'is_a';

$ontology2->get_relationship_by_id("APO:P0000274_part_of_APO:P0000271")->type() eq 'part_of'; 

=head1 DESCRIPTION

An OBOParser object parses an OBO-formatted file:

	http://www.geneontology.org/GO.format.obo-1_4.shtml
	
	http://berkeleybop.org/~cjm/obo2owl/obo-syntax.html

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut