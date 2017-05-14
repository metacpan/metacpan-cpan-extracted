package MyLibrary::Facet;

use MyLibrary::DB;
use Carp qw(croak);
use strict;

=head1 NAME

MyLibrary::Facet

=head1 SYNOPSIS

	# require the necessary module
	use MyLibrary::Facet;

	# create a new Facet object
	my $facet = MyLibrary::Facet->new();

	# set attributes of facet object
	$facet->facet_name('Facet Name');
	$facet->facet_note('This is a facet note');

	# delete a facet note
	$facet->delete_facet_note();

	# commit facet to database
	$facet->commit();

	# delete facet from database
	$facet->delete();

	# get all facets
	my @facets = MyLibrary::Facet->get_facets();
	my @facets = MyLibrary::Facet->get_facets(sort => 'name');

	# get specific facets based on criteria
	my @facets = MyLibrary::Facet->get_facets(value => 'Discipline', field => 'name');

	# return related terms
	my @related_terms = $facet->related_terms();

	# return a sorted list of related terms
	my @related_terms = $facet->related_terms(sort => 'name');


=head1 DESCRIPTION

The purpose of this module is to manipulate MyLibrary Facet objects and perform database I/O against the facets table of a MyLibrary database. You may also retrieve a list of facet objects by using a special class method. A list of term ids with which a particular facet is associated can be retrieved as well and manipulated independently. All changes to either the facet descriptive data can be commited to the database.

=head1 METHODS

=head2 new()

This method creates a new facet object. Called with no input, this constructor will return a new, empty facet object:

	# create empty facet
	$facet = MyLibrary::Facet->new();

The constructor can also be called using a known facet id or facet name:

	# create a facet object using a known facet id
	$facet = MyLibrary::Facet->new(id => $id);

	# create a facet object using a known facet name
	$facet = MyLibrary::Facet->new(name => 'Disciplines');

=head2 facet_id()

This object method is used to retrieve the facet id of the current facet object. This method cannot be used to set the facet id.

	# get facet id
	my $facet_id = $facet->facet_id();

=head2 facet_name()

This is an attribute method which allows you to either get or set the name attribute of a facet. The names for facets will be created by the institutional team tasked with the responsibility of designating the broad categories under which resources will be categorized. To retrieve the name attribute:

	# get the facet name
	$facet->facet_name();

	# set the facet name
	$facet->facet_name('Format');

=head2 facet_note()

This method allows one to either retrieve or set the facet descriptive note.

To retrieve the note attribute:

	# get the facet note
	$facet->facet_note();

	# set the facet note
	$facet->facet_note('The subject area under which a resource may be classified.');

=head2 delete_facet_note()

This object attribute method allows the removal of the facet note

	# delete the facet note
	$facet->delete_facet_note()

=head2 commit()

Use this method to commit the facet in memory to the database. Any updates made to facet attributes will be saved and new facets created will be saved. This method does not take any parameters.

	# commit the facet
	$facet->commit();

A numeric code will be returned upon successfull completion of the operation. A return code of 1 indicates a successful commit. Otherwise, the method will cease program execution and die with an appropriate error message.

=head2 delete()

Use this method to remove a facet record from the database. The record will be deleted permanently.

	# delete the facet
	$facet->delete();

=head2 get_facets()

This method can be used to retrieve a list of all of the facets currently in the database. Individual facet objects will be created and can be cycled through. This is a class method, not an object method. If the sort parameter is supplied, the list of facet ids will be sorted. Currently, the list can only be sorted by facet name. A specific list of facets can also be queried for by using the field and value parameters. Searchable fields are name and description. Examples are demonstrated below.

	# get all facets
	my @facets = MyLibrary::Facet->get_facets();

	# sort the returned list
	my @facets = MyLibrary::Facet->get_facets(sort => 'name');

	# find all facets based on criteria
	my @facets = MyLibrary::Facet->get_facets(value => 'Discpline', field => 'name');

=head2 related_terms()

This method should be used to return an array (a list) of term ids to which this facet is related. It requires no parameter input. If the facet is not related to any terms in the database, the method will return undef. The array of term ids can then be used to process the list of related terms. The returned list of term ids can also be sorted. This is an object method.

	# return related terms
	my @related_terms = $facet->related_terms();

	# return sorted list of related terms
	my @related_terms = $facet->related_terms(sort => 'name');

=head1 AUTHORS

Eric Lease Morgan <emorgan@nd.edu>
Robert Fox <rfox2@nd.edu>

=cut


sub new {

	# declare local variables
	my ($class, %opts) = @_;
	my $self = {};

	# check for an id
	if ($opts{id}) {
	
		my $dbh = MyLibrary::DB->dbh();
		my $rv = $dbh->selectrow_hashref('SELECT * FROM facets WHERE facet_id = ?', undef, $opts{id});
		if (ref($rv) eq "HASH") { 
			$self = $rv;
			$self->{related_terms} = $dbh->selectcol_arrayref('SELECT term_id FROM terms WHERE facet_id = ?', undef, $opts{id});
		} else { 
			return; 
		}
	} elsif ($opts{name}) {
		my $dbh = MyLibrary::DB->dbh();
		my $rv = $dbh->selectrow_hashref('SELECT * FROM facets WHERE facet_name = ?', undef, $opts{name});
		if (ref($rv) eq "HASH") { 
			$self = $rv;
			$self->{related_terms} = $dbh->selectcol_arrayref('SELECT term_id FROM terms WHERE facet_id = ?', undef, $self->{facet_id}); 
		} else { 
			return;
		} 
	}
	
	# return the object
	return bless $self, $class;
	
}


sub facet_id {

	my $self = shift;
	return $self->{facet_id};

}


sub facet_name {

	# declare local variables
	my ($self, $facet_name) = @_;
	
	# check for the existance of a note 
	if ($facet_name) { $self->{facet_name} = $facet_name }
	
	# return the name
	return $self->{facet_name};
	
}


sub facet_note {

	# declare local variables
	my ($self, $facet_note) = @_;
	
	# check for the existance of a note 
	if ($facet_note) { $self->{facet_note} = $facet_note }
	
	# return the note
	return $self->{facet_note};
	
}

sub delete_facet_note {

	my $self = shift;
	$self->{facet_note} = undef;
}


sub commit {

	# get myself, :-)
	my $self = shift;
	
	# get a database handle
	my $dbh = MyLibrary::DB->dbh();	
	
	# see if the object has an id
	if ($self->facet_id()) {
	
		# update the record with this id
		my $return = $dbh->do('UPDATE facets SET facet_name = ?, facet_note = ? WHERE facet_id = ?', undef, $self->facet_name(), $self->facet_note(), $self->facet_id());
		if ($return > 1 || ! $return) { croak "Facet update in commit() failed. $return records were updated." }
	
	} else {
	
		# get a new sequence
		my $id = MyLibrary::DB->nextID();		
		# create a new record
		my $return = $dbh->do('INSERT INTO facets (facet_id, facet_name, facet_note) VALUES (?, ?, ?)', undef, $id, $self->facet_name(), $self->facet_note());
		if ($return > 1 || ! $return) { croak 'Facet commit() failed.'; }
		$self->{facet_id} = $id;
		
	}
	
	# done
	return 1;
	
}


sub delete {

	my $self = shift;

	if ($self->{facet_id}) {

		my $dbh = MyLibrary::DB->dbh();

		# delete any related terms first
		my $term_ids = $dbh->selectcol_arrayref('SELECT term_id FROM terms WHERE facet_id = ?', undef, $self->{facet_id});	
		if (scalar(@{$term_ids}) >=1) {
			require MyLibrary::Term;
			foreach my $term_id (@{$term_ids}) {
				my $term = MyLibrary::Term->new(id => $term_id);
				$term->delete();
			}
		}

		# now, delete the primary facet record
		my $rv = $dbh->do('DELETE FROM facets WHERE facet_id = ?', undef, $self->{facet_id});
		if ($rv != 1) {croak ("Error deleting facet record. Deleted $rv records.");}
		 
		return 1;

	}

	return 0;

}


sub get_facets {

	my $self = shift;
	my %opts = @_;
	my @rv   = ();

	my ($sort, $field, $value, $sort_clause, $limit_clause, $query);
	if (defined($opts{sort})) {
		if ($opts{sort} eq 'name') {
			$sort_clause = 'ORDER BY facet_name';
		}
	}
	if (defined($opts{field}) && defined($opts{value})) {
		$field = $opts{'field'};
		$value = $opts{'value'};
		if ($field eq 'name') {
			$limit_clause = "WHERE facet_name LIKE \'%$value%\'";
		} elsif ($field eq 'description') {
			$limit_clause = "WHERE facet_note LIKE \'%$value%\'";
		}
	}
	$query = 'SELECT facet_id FROM facets';
	if ($limit_clause) {
		$query .= " $limit_clause";
	}
	if ($sort_clause) {
		$query .= " $sort_clause";
	}

	# create and execute a query
	my $dbh = MyLibrary::DB->dbh();

	my $facet_ids = $dbh->selectcol_arrayref("$query");
			
	foreach my $facet_id (@$facet_ids) {
		push (@rv, MyLibrary::Facet->new(id => $facet_id));
	}	
	
	return @rv;
}

sub related_terms {

	my $self = shift;
	my %opts = @_;
	my $sort;
	if (defined($opts{sort})) {
		$sort = $opts{sort};
	}
	my @related_terms = ();
	my $related_terms;
	my $related_term_list;

	foreach my $term_id (@{$self->{related_terms}}) {
		push (@related_terms, $term_id);
		$related_term_list .= "$term_id, ";
	}
	chop($related_term_list);
	chop($related_term_list);

	if ($sort && $sort eq 'name') {
		my $dbh = MyLibrary::DB->dbh();
		$related_terms = $dbh->selectcol_arrayref("SELECT term_id FROM terms WHERE term_id IN ($related_term_list) ORDER BY term_name");
		@related_terms = ();
		foreach my $related_term (@$related_terms) {
			push (@related_terms, $related_term);
		}
	}

	return @related_terms;
}
	
# return true, or else
1;
