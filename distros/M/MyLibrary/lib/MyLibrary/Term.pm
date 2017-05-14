package MyLibrary::Term;

use MyLibrary::DB;
use Carp qw(croak);
use strict;

=head1 NAME

MyLibrary::Term

=head1 SYNOPSIS
	
	# require the necessary module
	use MyLibrary::Term;

	# create a new Term object
	my $term = MyLibrary::Term->new();

	# set the attributes of a Term object
	$term->term_name('Term One');
	$term->term_note('Sample note for a term');
	$term->facet_id(9999);

	# delete the term note
	$term->delete_term_note();

	# commit Term data to database
	$term->commit();

	# get a list of all term objects
	my @terms = MyLibrary::Term->get_terms();

	# get list of term objects based on criteria
	my @terms = MyLibrary::Term->get_terms(field => 'name', value => 'Chemistry');

	# get a list of all related resource ids
	my @related_resources = $term->related_resources();

	# delete relations between terms and resources
	my @related_resources = $term->related_resources(del => [@resource_ids]);

	# set new relations between a term and resources
	my @related_resources = $term->related_resources(new => [@resource_ids]);	

	# sort a list of returned resource ids according to name
	my @related_resources = $term->related_resources(sort => 'name');

	# get a list of all related suggested resource ids
	my @suggested_resources = $term->suggested_resources();

	# retrieve a sorted list of related suggested resource ids
	my @suggested_resources = $term->suggested_resources(sort => 'name');

	# return a list of related librarian objects
	my @librarians = $term->librarians();

	# return a list of related librarian ids
	my @librarians = $term->librarians(output => 'id');

	# add a list of librarians to this term, dismissing database relational integrity
	$term->librarians(new => [@librarian_ids], strict => 'off');

	# sort a list of supplied term ids according to specific criteria
	my @sorted_terms = MyLibrary::Term->sort(term_ids => [@term_ids], type => 'name');

	# return overlapping resources with this term (~30 term ids max)
	my @overlap_resources = $term->overlap(term_ids => [@term_ids]);

	# return a distinct set of related terms within a resource group
	my @distinct_terms = MyLibrary::Term->distinct_terms(resource_ids => [@resource_ids]);

	# delete a list of librarians from this term
	$term->librarians(del => [@librarians_ids]);

	# delete a Term object from the database
	$term->delete();

=head1 DESCRIPTION

Use this module to get and set the terms used to classify things in a MyLibrary database. You can also retrieve a list of all term objects in the database, as well as get, set or delete relations between term objects and resource objects.

=head1 METHODS

=head2 new()

This method creates a new term object. Called with no input, this constructor will return a new, empty term object:

	# create empty term object
	my $term = MyLibrary::Term->new();

The constructor can also be called using a known term id or term name:

	# create a term object using a known term id
	my $term = MyLibrary::Term->new(id => $id);

	# create a term object using a known term name
	my $term = MyLibrary::Term->new(name => $name);

=head2 term_id()

This method can be used to retrieve the term id for the current term object. It cannot be used to set the id
for the term.

	# get term id
	my $term_id = $term->term_id();

=head2 term_name()

This is an attribute method which allows you to either get or set the name attribute of a term. The names for terms
will be created by the institutional team tasked with the responsibility of designating the more specific categories under
which resources will be categorized. A term is related to one and only one parent facet. To retrieve the name attribute:

	# get the term name
	my $term_name = $term->term_name();

=head2 term_note()

This method allows one to either retrieve or set the term descriptive note.

	# get the term note
	my $term_note = $term->term_note();

	# set the term note
	$term->term_note('This is a term note.');

=head2 delete_term_note()

Use this method to delete the term note

	# delete term note
	$term->delete_term_note();

=head2 facet_id()

This method may be used to either set or retrieve the value of the related facet id for this term. When the term
is commited to the database, if the facet id is changed, the relation between this term and the facets will also
be changed.

	# get the related facet id
	my $related_facet_id = $term->facet_id();

	# set the related facet id
	$term->facet_id(25);

=head2 commit()

This object method is used to commit the current term object in memory to the database. If the term already exists in the database,
it will be updated. New terms will be inserted into the database.

	# commit the term
	$term->commit();

=head2 delete()

This object method should be used with caution as it will delete an existing term from the database. Any associations
with the Resources will also be deleted with this method in order to maintain referential integrity. If an attempt is made to 
delete a term which does not yet exist in the database, a return value of '0' will result. A successful deletion will result
in a return value of '1'.

	# delete the term
	$term->delete();

=head2 get_terms()

This class method can be used to retrieve an array of all term objects. The array can then be used to sequentially process through all of the existing terms. This method can also be used to retrieve a list of objects based on object attributes such as name or description. This can be accomplished by supplying the field and value parameters to the method. Examples are demonstrated below.

	# get all the terms
	my @terms = MyLibrary::Term->get_terms();

	# get all terms based on criteria
	my @terms = MyLibrary::Term->get_terms(field => 'name', value => 'Biology and Life Sciences');

=head2 related_resources()

This object method can be used to retrieve an array (a list) of resource ids to which this term is related. This list can then be used to sequentially process through all related resources (for example in creating a list of related resources). No parameters are necessary for this method to retrieve related resources, however, new relatetions can be created by supplying a list of resource ids using the 'new' parameter. If the term is already related to a supplied resource id, that resource id will simply be discarded. Upon a term commit (e.g. $term->commit()), the new relations with resources will be created. Also, the input must be in the form of numeric digits. Care must be taken because false relationships could be created. A list of the currently related resources will always be returned (if such relations exist).

	# get all related resources
	my @related_resources = $term->related_resources();

	# supply new related resources
	$term->related_resources(new => [10, 12, 14]);
	or
	my @new_related_resource_list = $term->related_resources(new => [@new_resources]);

The method will by default check to make sure that the new resources to which this term should be related exist in the database. This feature may be switched off by supplying the strict => 'off' parameter. Changing this parameter to 'off' will switch off the default behavior and allow bogus resource relations to be created.

	# supply new related resources with relational integrity switched off
	$term->related_resources(new => [10, 12, 14], strict => 'off');

Resources which do not exist in the database will simply be rejected if strict relational integrity is turned on.

The method can also be used to delete a relationship between a term and a resource. This can be accomplished by supplying a list of resources via the 'del' parameter. The methodology is the same as the 'new' parameter with the primary difference being that referential integrity will be assumed (for example, that the resource being severed already exists in the database). This will not delete the resource itself, it will simply delete the relationship between the current term object and the list of resources supplied with the 'del' parameter.

	# sever the relationship between this term and a list of resource ids
	$term->related_resources(del => [10, 11, 12]);

	or

	$term->related_resources(del => [@list_to_be_severed]);

If the list includes resources to which the current term is not related, those resource ids will simply be ignored. Priority will be given to resource associations added to the object; deletions will occur during the commit() after new associations have been created.

Finally, a returned list of related resources can be sorted.

	# sort a returned list of resource ids according to resource name
	my @related_resources = $term->related_resources(sort => 'name');

=head2 suggested_resources()

This is an object method which can be used to retrieve, set or delete suggested resource relationships between terms and resources. The return set will always be an array of resource ids which can then be used to process through the resources to which the ids correspond. This method functions similarly to the related_resource() method and uses similar parameters to change method functionality. If no parameters are submitted, the method simply returns a list of resource_ids or undef if there are no suggested resources for this term. As with the related_resources() method, passing a sort parameter will sort the returned list according to the parameter value. Currently, only 'name' is acceptable as a parameter value.

	# get all suggested resources
	my @suggested_resources = $term->suggested_resources();

	# get a sorted list of suggested resources
	my @suggested_resources = $term->suggested_resources(sort => 'name');

	# supply new suggested resources
	my @new_suggested_resource_list = $term->suggested_resources(new => [@new_suggested_resource_list]);

As with related_resources(), this method will by default check to make sure that the new resources to which this term should be related exist in the database. The strict => 'off' parameter may also be supplied to the method to turn off relational integrity checks.

	# turn off relational integrity checks
	$term->suggested_resources(new => [@new_suggested_resources], strict => 'off');

Turning off this feature will allow for bogus relations to be created.

The parameter to delete suggested resource relationships is del => [@set_to_delete]. The list supplied will be automatically deleted when the term is commited with commit(). This parameter does not delete the resources themselves, only their relationship as a 'suggested resource'. If the list includes resource ids to which the term is not related, they will simply be discarded and ignored.

	# remove suggested resource relationships
	$term->suggested_resources(del => [@list_to_be_deleted]);

Priority for processing the list will be given to resources associations added to the term, but the overall effect on the data should be transparent.

=head2 librarians()

This object method will return a list of related librarian objects/ids or undef if no librarians are associated with this term. The type of data returned is controlled by the 'output' parameter. If 'id' is chosen as the preferred output, a simple list of related librarian ids will be returned. If the output type of 'object' is preferred, the returned librarian object can be manipulated using the librarian object methods. This method can also be used to add or delete librarian associations with this term. The 'new' and 'del' parameters exist for this purpose (see examples below). A list of librarian ids should be provied for these parameters. Relational integrity can be abandoned by using the 'strict' parameter and giving it a value of off.

	# return a list of librarian objects
	my @librarians = $term->librarians();

	# return a list of librarian ids
	my @librarians = $term->librarians(output => 'id');

	# add a list of librarian associations to this term
	$term->librarians(new => [@librarian_ids]);
	$term->librarians(new => [@librarian_ids], strict => 'off');

	# remove a list of librarian associations from this term
	$term->librarians(del => [@librarian_ids]);

=head2 sort()

This class method performs a simple sort on a supplied list of term ids according to specific criteria, which is indicated as a parameter value for the method.

	# sort term ids by term name
	my @sorted_terms = MyLibrary::Term->sort(term_ids => [@term_ids], type => 'name');

=head2 overlap()

This object method returns a list of overlapping resources with a provided list of term ids. If there are no overlapping resources, the method returns null. If submitted term ids do not exist in the database, the method will ignore that input. Since some databases are limited by how many table joins they can perform in one query, limit the number of term ids to approximately 25-30 at a time. Otherwise, the method will likely fail.

	# return overlapping resources with this term
	my @overlap_resources = $term->overlap(term_ids => [@term_ids]);

=head2 distinct_terms()

This class method returns a unique list of term ids (which can be sorted using the sort() method) that correspond to a specific group of resource ids.

	# return a distinct set of related terms within a resource group
	my @distinct_terms = MyLibrary::Term->distinct_terms(resource_ids => [@resource_ids]);

=head1 AUTHORS

Eric Lease Morgan <emorgan@nd.edu>
Robert Fox <rfox2@nd.edu>

=cut


sub new {

	# declare local variables
	my ($class, %opts) = @_;
	my $self           = {};

	# check for an id
	if ($opts{id}) {
	
		# get a handle
		my $dbh = MyLibrary::DB->dbh();
		
		# find this record
		my $rv = $dbh->selectrow_hashref('SELECT * FROM terms WHERE term_id = ?', undef, $opts{id});
		
		# check for success
		if (ref($rv) eq "HASH") {
			$self = $rv; 
			$self->{related_resources}= $dbh->selectall_arrayref('SELECT resource_id FROM terms_resources WHERE term_id =?', undef, $opts{id});
			$self->{suggested_resources} = $dbh->selectall_arrayref('SELECT resource_id FROM suggestedResources WHERE term_id = ?', undef, $opts{id});
		} else { 
			return; 
		}
	
	} elsif ($opts{name}) {

		# get a handle
		my $dbh = MyLibrary::DB->dbh();

		# find this record
		my $rv = $dbh->selectrow_hashref('SELECT * FROM terms WHERE term_name = ?', undef, $opts{name});

		# check for success
		if (ref($rv) eq "HASH") { 
			$self = $rv; 
			$self->{related_resources}= $dbh->selectall_arrayref('SELECT resource_id FROM terms_resources WHERE term_id =?', undef, $self->{term_id});
			$self->{suggested_resources} = $dbh->selectall_arrayref('SELECT resource_id FROM suggestedResources WHERE term_id = ?', undef, $self->{term_id});
		} else { 
			return;
		}
	}
	
	# return the object
	return bless $self, $class;
	
}


sub term_id {

	my $self = shift;
	return $self->{term_id};

}


sub term_name {

	# declare local variables
	my ($self, $term_name) = @_;
	
	# check for the existance of a term name
	if ($term_name) { $self->{term_name} = $term_name }
	
	# return it
	return $self->{term_name};
	
}


sub term_note {

	# declare local variables
	my ($self, $term_note) = @_;
	
	# check for the existance of a term note
	if ($term_note) { $self->{term_note} = $term_note }
	
	# return it
	return $self->{term_note};
	
}

sub delete_term_note {
	
	my $self = shift;
	$self->{term_note} = undef;

}


sub facet_id {

	# declare local variables
	my ($self, $facet_id) = @_;
	
	# check for the existance of facet id
	if ($facet_id) { $self->{facet_id} = $facet_id }
	
	# return it
	return $self->{facet_id};
	
}


sub commit {

	# get myself, :-)
	my $self = shift;
	
	# get a database handle
	my $dbh = MyLibrary::DB->dbh();	
	
	# see if the object has an id
	if ($self->term_id()) {
	
		# update the record with this id
		my $return = $dbh->do('UPDATE terms SET term_name = ?, term_note = ?, facet_id = ? WHERE term_id = ?', undef, $self->term_name(), $self->term_note(), $self->facet_id(), $self->term_id());
		if ($return > 1 || ! $return) { 
			croak "Terms update in commit() failed. $return records were updated.";
		}
		# update term=>resource relational integrity
		my @related_resources = $self->related_resources();
		if (scalar(@related_resources) > 0 && @related_resources) {
			my $arr_ref = $dbh->selectall_arrayref('SELECT resource_id FROM terms_resources WHERE term_id =?', undef, $self->term_id());
			# determine which resources stay put
			if (scalar(@{$arr_ref}) > 0) {
				foreach my $arr_val (@{$arr_ref}) {
					my $j = scalar(@related_resources);
					for (my $i = 0; $i < scalar(@related_resources); $i++)  {
						if ($arr_val->[0] == $related_resources[$i]) {
							splice(@related_resources, $i, 1);
							$i = $j;
						}
					}
				}
			}
			# add the new associations
			foreach my $related_resource (@related_resources) {
				my $return = $dbh->do('INSERT INTO terms_resources (resource_id, term_id) VALUES (?,?)', undef, $related_resource, $self->term_id());
				if ($return > 1 || ! $return) { croak "Unable to update term=>resource relational integrity. $return rows were inserted." }
			}
			# determine which resource associations to delete
			my @del_related_resources;
			my @related_resources = $self->related_resources();
			if (scalar(@{$arr_ref}) > 0) {
				foreach my $arr_val (@{$arr_ref}) {
					my $found;
					for (my $i = 0; $i < scalar(@related_resources); $i++)  {
						if ($arr_val->[0] == $related_resources[$i]) {
							$found = 1;
							last;
						} else {
							$found = 0;
						}
					}
					if (!$found) {
						push (@del_related_resources, $arr_val->[0]);
					}
				}
			}
			# delete removed associations
			foreach my $del_rel_resource (@del_related_resources) {
				my $return = $dbh->do('DELETE FROM terms_resources WHERE resource_id = ? AND term_id = ?', undef, $del_rel_resource, $self->term_id());
				if ($return > 1 || ! $return) { croak "Unable to delete term=>resource association. $return rows were deleted." }
			}
		} elsif (scalar(@related_resources) <= 0 || !@related_resources) {
			# remove any remaining resource associations
			my $return = $dbh->do('DELETE FROM terms_resources WHERE term_id = ?', undef, $self->term_id());
		}
		# update suggested resource relational integrity
		my @suggested_resources = $self->suggested_resources();
		if (scalar(@suggested_resources) > 0 && @suggested_resources) {
			my $arr_ref = $dbh->selectall_arrayref('SELECT resource_id FROM suggestedResources WHERE term_id =?', undef, $self->term_id());
			# determine which suggested stay put
			if (scalar(@{$arr_ref}) > 0) {
				foreach my $arr_val (@{$arr_ref}) {
					my $j = scalar(@suggested_resources);
					for (my $i = 0; $i < scalar(@suggested_resources); $i++)  {
						if ($arr_val->[0] == $suggested_resources[$i]) {
							splice(@suggested_resources, $i, 1);
							$i = $j;
						}
					}
				}
			}
			# add the new associations
			foreach my $suggested_resource (@suggested_resources) {
				my $return = $dbh->do('INSERT INTO suggestedResources (term_id, resource_id) VALUES (?,?)', undef, $self->term_id(), $suggested_resource);
				if ($return > 1 || ! $return) { croak "Unable to update term=>suggested_resource relational integrity. $return rows were inserted." }
			}
			# determine which resource associations to delete
			my @del_suggested_resources;
			my @suggested_resources = $self->suggested_resources();
			if (scalar(@{$arr_ref}) > 0) {
				foreach my $arr_val (@{$arr_ref}) {
					my $found;
					for (my $i = 0; $i < scalar(@suggested_resources); $i++)  {
						if ($arr_val->[0] == $suggested_resources[$i]) {
							$found = 1;
							last;
						} else {
							$found = 0;
						}
					}
					if (!$found) {
						push (@del_suggested_resources, $arr_val->[0]);
					}
				}
			}
			# delete removed associations
			foreach my $del_sug_resource (@del_suggested_resources) {
				my $return = $dbh->do('DELETE FROM suggestedResources WHERE resource_id = ? AND term_id = ?', undef, $del_sug_resource, $self->term_id());
				if ($return > 1 || ! $return) { croak "Unable to delete term=>suggested_resource association. $return rows were deleted." }
			}
		} elsif (scalar(@suggested_resources) == 0) {
			my $arr_ref = $dbh->selectall_arrayref('SELECT resource_id FROM suggestedResources WHERE term_id =?', undef, $self->term_id());
			# delete remainder of suggested resources for this term
			if (scalar(@{$arr_ref}) > 0) {
				my $return = $dbh->do('DELETE FROM suggestedResources WHERE term_id = ?', undef, $self->term_id());
				if ($return eq undef) { croak "Unable to delete remainder of term suggested resource associations. $return rows were deleted." }
			}	

		}  
	
	} else {
	
		# get a new sequence
		my $id = MyLibrary::DB->nextID();		
		
		# create a new record
		my $return = $dbh->do('INSERT INTO terms (term_id, term_name, term_note, facet_id) VALUES (?, ?, ?, ?)', undef, $id, $self->term_name(), $self->term_note(), $self->facet_id());
		if ($return > 1 || ! $return) { 
			croak 'Terms commit() failed.'; 
		}
		$self->{term_id} = $id;
		# update term=>resource relational integrity
		my @related_resources = $self->related_resources();
		if (scalar(@related_resources) > 0 && @related_resources) {
			foreach my $related_resource (@related_resources) {
				my $return = $dbh->do('INSERT INTO terms_resources (resource_id, term_id) VALUES (?,?)', undef, $related_resource, $self->term_id());
				if ($return > 1 || ! $return) { croak "Unable to update term=>resource relational integrity. $return rows were inserted." }
			}
		}
		# update term=>suggested_resource relational integrity	
		my @suggested_resources = $self->suggested_resources();
		if (scalar(@suggested_resources) > 0 && @suggested_resources) {
			foreach my $suggested_resource (@suggested_resources) {
				my $return = $dbh->do('INSERT INTO suggestedResources (term_id, resource_id) VALUES (?,?)', undef, $self->term_id(), $suggested_resource);
				if ($return > 1 || ! $return) { croak "Unable to update term=>suggested_resource relational integrity. $return rows were inserted." }
			}
		}
	}
	
	# done
	return 1;
}


sub delete {

	my $self = shift;

	if ($self->{term_id}) {

		my $dbh = MyLibrary::DB->dbh();
		my $rv = $dbh->do('DELETE FROM terms WHERE term_id = ?', undef, $self->{term_id});
		if ($rv != 1) {croak ("Deleted $rv records. I'll bet this isn't what you wanted.");}
		# delete resource associations
		$rv = $dbh->do('SELECT * FROM terms_resources WHERE term_id = ?', undef, $self->{term_id});
		if ($rv > 0) { 
			$rv = $dbh->do('DELETE FROM terms_resources WHERE term_id = ?', undef, $self->{term_id});
			if ($rv < 1 || ! $rv) {croak ("Term => Resource associations could not be deleted. Referential integrity may be compromised.");}
		}
		# delete suggested resource associations
		$rv = $dbh->do('SELECT * FROM suggestedResources WHERE term_id = ?', undef, $self->{term_id});
		if ($rv > 0) {
			$rv = $dbh->do('DELETE FROM suggestedResources WHERE term_id = ?', undef, $self->{term_id});
			if ($rv < 1 || ! $rv) {croak ("Term => Suggested resource associations could not be deleted. Referential integrity may be compromised.");}
		}
		# delete the librarian associations
		$rv = $dbh->do('SELECT * FROM terms_librarians WHERE term_id = ?', undef, $self->{term_id});
		if ($rv > 0) {
			$rv = $dbh->do('DELETE FROM terms_librarians WHERE term_id = ?', undef, $self->{term_id});
			if ($rv < 1 || ! $rv) {croak ("Term => Librarian associations could not be deleted. Referential integrity may be compromised.");}
		}

		# delete patron associations
		$dbh->do('DELETE FROM patron_term WHERE term_id = ?', undef, $self->term_id());

		return 1;

	}

	return 0;

}


sub get_terms {

	my $self = shift;
	my %opts = @_;
	my @rv   = ();

	my ($field, $value, $sort, $limit_clause, $sort_clause, $query);

	if ($opts{sort}) {
		if ($opts{sort} eq 'name') {
			$sort_clause = 'ORDER BY term_name';
		}
	}

	if ($opts{field} && $opts{value}) {
		$field = $opts{'field'};
		$value = $opts{'value'};
		if ($field eq 'name') {
			$limit_clause = "WHERE term_name LIKE \'%$value%\'";
		} elsif ($field eq 'description') {
			$limit_clause = "WHERE term_note LIKE \'%$value%\'";
		}
	}

	$query = 'SELECT term_id FROM terms';

	# the order is important here
	if ($limit_clause) {
		$query .= " $limit_clause";
	}
	if ($sort_clause) {
		$query .= " $sort_clause";
	}
	
	# create and execute a query
	my $dbh = MyLibrary::DB->dbh();
	my $term_ids = $dbh->selectcol_arrayref("$query");

	foreach my $term_id (@$term_ids) {
		push (@rv, MyLibrary::Term->new(id => $term_id));
	}
	
	return @rv;
	
}

sub related_resources {

	my $self = shift;
	my %opts = @_;
	my @new_related_resources;
	if ($opts{new}) { 
		@new_related_resources = @{$opts{new}};
	}
	my @del_related_resources;
	if ($opts{del}) {
		@del_related_resources = @{$opts{del}};
	}
	my $sort;
	if ($opts{sort}) {
		$sort = $opts{sort};
	}	
	my @related_resources;
	my $strict_relations;
	if ($opts{strict}) {
		if ($opts{strict} == 1) {
			$strict_relations = 'on';
		} elsif ($opts{strict} == 0) {
			$strict_relations = 'off';
		} elsif (($opts{strict} !~ /^\d$/ && ($opts{strict} == 1 || $opts{strict} == 0)) || $opts{strict} ne 'off' || $opts{strict} ne 'on') {
			$strict_relations = 'on';
		} else {
			$strict_relations = $opts{strict};
		}
	} else {
		$strict_relations = 'on';
	}
	if (@new_related_resources) {
		RESOURCES: foreach my $new_related_resource (@new_related_resources) { 
			if ($new_related_resource !~ /^\d+$/) {
				croak "Only numeric digits may be submitted as resource ids for term relations. $new_related_resource submitted.";
			}
			if ($strict_relations eq 'on') {
				my $dbh = MyLibrary::DB->dbh();
				my $resource_list = $dbh->selectcol_arrayref('SELECT resource_id FROM resources');
				my $found_resource;
				RESOURCE_VAL: foreach my $resource_list_val (@$resource_list) {
					if ($resource_list_val == $new_related_resource) {
						$found_resource = 1;
						last RESOURCE_VAL;
					} else {
						$found_resource = 0;
					}
				}
				if ($found_resource == 0) {
					next RESOURCES;
				}
			}
			my $found;
			if ($self->{related_resources}) {
				RESOURCES_PRESENT: foreach my $related_resource (@{$self->{related_resources}}) {
					if ($new_related_resource == @$related_resource[0]) {
						$found = 1;
						last RESOURCES_PRESENT;
					} else {
						$found = 0;
					}
				}
			} else {
				$found = 0;
			}
			if ($found) {
				next RESOURCES;
			} else {
				my @related_resource_num = ();
				my $related_resource_num = \@related_resource_num;
				$related_resource_num->[0] = $new_related_resource;
				push(@{$self->{related_resources}}, $related_resource_num);
			}
		}
	}
	if (@del_related_resources) {
		foreach my $del_related_resource (@del_related_resources) {
			my $j = scalar(@{$self->{related_resources}});
			for (my $i = 0; $i < scalar(@{$self->{related_resources}}); $i++) {
				if ($self->{related_resources}->[$i]->[0] == $del_related_resource) {
					splice(@{$self->{related_resources}}, $i, 1);
					$i = $j;
				}
			}
		}
	}
						
			
	foreach my $related_resource (@{$self->{related_resources}}) {
		push(@related_resources, $related_resource->[0]);
	}

	if ($sort) {
		if ($sort eq 'name') {
			my $dbh = MyLibrary::DB->dbh();
			my $resource_id_string;
			foreach my $resource_id (@related_resources) {
				$resource_id_string .= "$resource_id, ";
			}
			chop($resource_id_string);
			chop($resource_id_string);
			my $resource_ids = $dbh->selectcol_arrayref("SELECT resource_id FROM resources WHERE resource_id IN ($resource_id_string) ORDER BY resource_name");
			@related_resources = ();
			foreach my $resource_id (@$resource_ids) {
				push (@related_resources, $resource_id);
			}
		}
	}

	return @related_resources;
}

sub suggested_resources {

	my $self = shift;
	my %opts = @_;
	my @new_suggested_resources;
	if ($opts{new}) {
		@new_suggested_resources = @{$opts{new}};
	}
	my @del_suggested_resources;
	if ($opts{del}) {
		@del_suggested_resources = @{$opts{del}};
	}
	my $sort;
	if ($opts{sort}) {
		$sort = $opts{sort};
	}
	my @suggested_resources;
	my $strict_relations;
	if ($opts{strict}) {
		if ($opts{strict} == 1) {
			$strict_relations = 'on';
		} elsif ($opts{strict} == 0) {
			$strict_relations = 'off';
		} elsif (($opts{strict} =~ /^\d$/ && ($opts{strict} != 1 || $opts{strict} != 0)) || $opts{strict} ne 'off' || $opts{strict} ne 'on') {
			$strict_relations = 'on';
		} else {
			$strict_relations = $opts{strict};
		}
	} else {
		$strict_relations = 'on';
	}
	# debug
	if (@new_suggested_resources) {
		SUGGESTED: foreach my $new_suggested_resource (@new_suggested_resources) {
			if ($new_suggested_resource !~ /^\d+$/) {
				croak "Only numeric digits may be submitted as resource ids for term relations. $new_suggested_resource submitted.";
			}
			if ($strict_relations eq 'on') {
				my $dbh = MyLibrary::DB->dbh();
				my $resource_list = $dbh->selectcol_arrayref('SELECT resource_id FROM resources');
				my $found_resource;
				RESOURCE_VAL: foreach my $resource_list_val (@$resource_list) {
					if ($resource_list_val == $new_suggested_resource) {
						$found_resource = 1;
						last RESOURCE_VAL;
					} else {
						$found_resource = 0;
					}
				}
				if ($found_resource == 0) {
					next SUGGESTED;
				}
			}
			my $found;
			if ($self->{suggested_resources}) {
				SUGGESTED_PRESENT: foreach my $suggested_resource (@{$self->{suggested_resources}}) {
					if ($new_suggested_resource == @$suggested_resource[0]) {
						$found = 1;
						last SUGGESTED_PRESENT;
					} else {
						$found = 0;
					}
				}
			} else {
				$found = 0;
			}
			if ($found) {
				next SUGGESTED;
			} else {
				my @suggested_resource_num = ();
				my $suggested_resource_num = \@suggested_resource_num;
				$suggested_resource_num->[0] = $new_suggested_resource;
				push(@{$self->{suggested_resources}}, $suggested_resource_num);
			}
		}
	}
	if (@del_suggested_resources) {
		foreach my $del_suggested_resource (@del_suggested_resources) {
			my $j = scalar(@{$self->{suggested_resources}});
			for (my $i = 0; $i < scalar(@{$self->{suggested_resources}}); $i++) {
				if ($self->{suggested_resources}->[$i]->[0] == $del_suggested_resource) {
					splice(@{$self->{suggested_resources}}, $i, 1);
					$i = $j;
				}
			}
		}
	}
	
	foreach my $suggested_resource (@{$self->{suggested_resources}}) {
		 push(@suggested_resources, $suggested_resource->[0]);
	}

	if ($sort) {
		if ($sort eq 'name') {
			my $dbh = MyLibrary::DB->dbh();
			my $resource_id_string;
			foreach my $resource_id (@suggested_resources) {
				$resource_id_string .= "$resource_id, ";
			}
			chop($resource_id_string);
			chop($resource_id_string);
			my $resource_ids = $dbh->selectcol_arrayref("SELECT resource_id FROM resources WHERE resource_id IN ($resource_id_string) ORDER BY resource_name");
			@suggested_resources = ();
			foreach my $resource_id (@$resource_ids) {
				push (@suggested_resources, $resource_id);
			}
		}
	}

	return @suggested_resources;
}

sub librarians {

	my $self = shift;
	my %opts = @_;
	my @new_librarians = ();

	my $output;
	if ($opts{'output'}) {
		$output = $opts{'output'};
	} else {
		$output = 'object';
	}

	if ($opts{'new'}) {
		@new_librarians = @{$opts{new}};
	}
	my @del_librarians = ();
	if ($opts{'del'}) {
		@del_librarians = @{$opts{del}};
	}

	my $strict_relations;	
	if ($opts{'strict'}) {
		if ($opts{strict} == 1) {
			$strict_relations = 'on';
		} elsif ($opts{strict} == 0) {
			$strict_relations = 'off';
		} elsif (($opts{strict} =~ /^\d$/ && ($opts{strict} != 1 || $opts{strict} != 0)) || $opts{strict} ne 'off' || $opts{strict} ne 'on') {
			$strict_relations = 'on';
		} else {
			$strict_relations = $opts{strict};
		}
	} else {
		$strict_relations = 'on';
	}
	
	my $dbh = MyLibrary::DB->dbh();

	my $librarians = $dbh->selectcol_arrayref('SELECT librarian_id FROM terms_librarians WHERE term_id = ?', undef, $self->term_id());
	if (@new_librarians) {
		NEW_LIBRARIAN: foreach my $new_librarian (@new_librarians) { 
			if ($new_librarian !~ /^\d+$/) {
				croak "Only numeric digits may be submitted as librarian ids for term relations. $new_librarian submitted.";
			}
			if ($strict_relations eq 'on') {
				my $librarian_list = $dbh->selectcol_arrayref('SELECT librarian_id FROM librarians');
				my $found_librarian;
				LIBRARIAN: foreach my $librarian_list_val (@$librarian_list) {
					if ($librarian_list_val == $new_librarian) {
						$found_librarian = 1;
						last LIBRARIAN;
					} else {
						$found_librarian = 0;
					}
				}
				if ($found_librarian == 0) {
					next NEW_LIBRARIAN;
				}
			}
			my $found;
			if ($librarians) {
				LIBRARIAN_PRESENT: foreach my $librarian_present (@{$librarians}) {
					if ($new_librarian == $librarian_present) {
						$found = 1;
						last LIBRARIAN_PRESENT;
					} else {
						$found = 0;
					}
				}
			} else {
				$found = 0;
			}
			if ($found) {
				# librarian association already exists
				next NEW_LIBRARIAN;
			} else {
				# add new librarian association to database		 
				my $rv = $dbh->do('INSERT INTO terms_librarians (term_id, librarian_id) VALUES (?,?)', undef, $self->term_id(), $new_librarian);
				if ($rv > 1 || ! $rv) {
					croak("Librarian could not be added to term. $rv values inserted");
				}
			}
		}
	}
	if (@del_librarians) {
		foreach my $del_librarian_id (@del_librarians) {
			my $j = scalar(@{$librarians});
			for (my $i = 0; $i < scalar(@{$librarians}); $i++) {
				if ($librarians->[$i] == $del_librarian_id) {
					# librarian found, delete association
					my $rv = $dbh->do('DELETE FROM terms_librarians WHERE term_id = ? AND librarian_id = ?', undef, $self->term_id(), $del_librarian_id);
					if ($rv > 1 || ! $rv) {
						croak("Could not delete librarian association from term. $rv database rows deleted.");
					}
					$i = $j;
				}
			}
		}
	}
	
	# get final list of librarians after additions and deletions
	my @librarian_objects = ();
	$librarians = $dbh->selectcol_arrayref('SELECT librarian_id FROM terms_librarians WHERE term_id = ?', undef, $self->term_id());
	if ($output eq 'object') {	
		require MyLibrary::Librarian;
	}

	foreach my $librarian_id (@{$librarians}) {
		if ($output eq 'object') {
			my $librarian = MyLibrary::Librarian->new(id => $librarian_id);
			push(@librarian_objects, $librarian);
		} elsif ($output eq 'id') {
			push(@librarian_objects, $librarian_id);
		}
	}

	if (scalar(@librarian_objects) >= 1) {
		return @librarian_objects;
	} else {
		return;
	}	

}

sub sort {

	my $class = shift;
	my $dbh = MyLibrary::DB->dbh();
	my %opts = @_;
	my $sort_option = $opts{'type'};
	unless ($sort_option) {
		croak ("Missing parameter: type");
	}
	my @term_ids = @{$opts{'term_ids'}};
	my $return_term_ids;

	my $term_id_string;
	foreach my $term_id (@term_ids) {
		$term_id_string .= "$term_id, ";
	}
	chop($term_id_string);
	chop($term_id_string);

	if ($sort_option eq 'name') {	
		$return_term_ids = $dbh->selectcol_arrayref("SELECT term_id FROM terms WHERE term_id IN ($term_id_string) ORDER BY term_name");
	}

	return @{$return_term_ids};

}

sub overlap {

	# THIS QUERY IS LIMITED BY HOW MANY TERMS ARE JOINED; FOR EXAMPLE, MYSQL CAN ONLY HANDLE 31 TABLE JOINS MAX
	
	my $term = shift;
	my %opts = @_;
	my @overlap_ids = @{$opts{'term_ids'}};

	unless (scalar(@overlap_ids) >= 1) {
		return;
	}

	my $current_term_id = $term->term_id();

	my $statement_prefix = 'SELECT r.resource_id FROM resources r';
	my $where_statement = 'WHERE';
	my $n = 1;

	my $sql_statement;
	foreach my $overlap_id (@overlap_ids) {

		my $current_number = $n + 1;
		my $last_number = $n - 1;

		unless (MyLibrary::Term->new(id => $overlap_id)) {

			next;

		}

		if ($n == 1) {

			$statement_prefix .= ", terms_resources tr1, terms_resources tr${current_number}";

		} else {

			$statement_prefix .= ", terms_resources tr${current_number}";

		}

		if ($n == 1) {

			$where_statement .=  " tr1.resource_id = tr${current_number}.resource_id";
			$where_statement .=  " AND tr1.term_id = $current_term_id";
			$where_statement .=  " AND tr${current_number}.term_id = $overlap_id";

		} else {

			$where_statement .=  " AND tr${last_number}.resource_id = tr${current_number}.resource_id";
			$where_statement .=  " AND tr${current_number}.term_id = $overlap_id";	

		}

		$where_statement .= ' AND r.resource_id = tr1.resource_id';
		$sql_statement = $statement_prefix . ' ' . $where_statement;
		
		$n++;
	}

	# execute query
	my $dbh = MyLibrary::DB->dbh();
    my $resource_ids = $dbh->selectcol_arrayref("$sql_statement");

	return @{$resource_ids};

}

sub distinct_terms {

	my $class = shift;
	my %opts = @_;

	unless ($opts{'resource_ids'}) {
		return;
	}

	my @resource_ids = @{$opts{'resource_ids'}};

	unless (scalar(@resource_ids) >= 1) {
		return;
	}

	my $in_list;

	foreach my $resource_id (@resource_ids) {
		$in_list .= "$resource_id, ";
	}
	chop($in_list);
	chop($in_list);

	my $sql = "SELECT DISTINCT term_id FROM terms_resources WHERE resource_id IN ($in_list)";

	# execute query	
	my $dbh = MyLibrary::DB->dbh();
	my $term_ids = $dbh->selectcol_arrayref("$sql");

	return @{$term_ids};

}

# return true
1;
