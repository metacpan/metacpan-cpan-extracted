package MyLibrary::Librarian;

use MyLibrary::DB;
use Carp;
use strict;

=head1 NAME

MyLibrary::Librarian


=head1 SYNOPSIS

	# use the module
	use MyLibrary::Librarian;
	
	# create a new librarian
	my $librarian = MyLibrary::Librarian->new();
	
	# give the librarian characteristics
	$librarian->name('Fred Kilgour');
	$librarian->email('kilgour@oclc.org');
	$librarian->telephone('1 (800) 555-1212');
	$librarian->url('http://oclc.org/~kilgour/');
	
	# associate (classify) the librarian with term ids
	$librarian->term_ids(new => [3, 614, 601]);

	# disassociate certain term ids from this librarian
	$librarian->term_ids(del => [@del_term_ids]);

	# retrieve list of term ids with sort parameter
	my @term_ids = $librarian->term_ids(sort => 'name');
	
	# save the librarian to the database; create a new record
	$librarian->commit();
	
	# get the id of the current librarian object
	$id = $librarian->id();
	
	# get a librarian based on an id
	my $librarian = MyLibrary::Librarian->new(id => $id);
	
	# display information about the librarian
	print '       ID: ', $librarian->id(), "\n";
	print '     Name: ', $librarian->name(), "\n";
	print '    Email: ', $librarian->email(), "\n";
	print 'Telephone: ', $librarian->telephone(), "\n";
	print '      URL: ', $librarian->url(), "\n";
	
	# retrieve complete, sorted list of librarian objects
	my @librarians = MyLibrary::Librarian->get_librarians();
	
	# process each librarian
	foreach my $l (@librarians) {
	
		# print each librarian's name and email address
		print $l->name(), ' <', $l->email(), "> \n";
	
	}


=head1 DESCRIPTION

Use this module to get and set the characteristics of librarians to a MyLibrary database. Characteristics currently include: ID (primary database key), name, email address, telephone number, home page URL, and a set of integers (primary database keys) denoting what terms the librarian has been classified under.


=head1 METHODS

This section describes the methods available in the package.


=head2 new()

Use this method to create a librarian object. Called with no options, this method creates an empty object. Called with an id option, this method uses the id as a database key and fills the librarian object with data from the underlying database.

	# create a new librarian object
	my $librarian = MyLibrary::Librarian->new();
  
	# create a librarian object based on a previously existing ID
	my $librarian = MyLibrary::Librarian->new(id => 3);


=head2 id()

This method returns an integer representing the database key of the currently created librarian object.

	# get id of current librarian object
	my $id = $librarian->id();

You cannot set the id attribute.


=head2 name()

This method gets and sets the name from the librarian from the current librarian object:

	# get the name of the current librarian object
	my $name = $librarian->name();
	
	# set the current librarian object's name
	$librarian->name('Melvile Dewey');
	

=head2 telephone()

Use this method to get and set the telephone number of the current librarian object:

	# get the telephone number
	my $phone = $librarian->telephone();
	
	# set the current librarian object's telephone number
	$librarian->telephone('1 (800) 555-1212');


=head2 email()

Like the telephone and name methods, use this method to get and set the librarian object's email attribute:

	# get the email address
	my $email_address = $librarian->email();
	
	# set the current librarian object's email address
	$librarian->email('info@library.org');


=head2 url()

Set or get the URL attribute of the librarian object using this method:

	# get the URL attribute
	my $home_page = $librarian->url();
	
	# set the URL
	$librarian->url('http://dewey.library.nd.edu/');
	

=head2 term_ids()

This method gets and sets the term ids with which this libraian object is associated. Given no input, it returns a list of integers or undef if no term associations exist. Any input given is expected to be a list of integers. Related terms can be added or deleted given the correct input parameter. The returned list of term ids can be sorted by name using the sort parameter.

	# set the term id's
	$librarian->term_ids(new => [33, 24, 83]);
	
	# get the term id's of the current librarian object
	my @ids = $librarian->term_ids();

	# get the term id's of the current librarian object sorted by name
	my @ids = $librarian->term_ids(sort => 'name');
	
	# require the Term package
	use MyLibrary::Term;
	
	# process each id
	foreach my $i (@ids) {
	
		# create a term object
		my $term->MyLibrary::Term->new(id => $i);
		
		# print the term associated with the librarian object
		print $librarian->name, ' has been classified with the term: ', $term->name, ".\n";
	
	}

	# remove term associations
	$librarian->term_ids(del => [@removed_term_ids]);
	
=head2 commit()

Use this method to save the librarian object's attributes to the underlying database. If the object's data has never been saved before, then this method will create a new record in the database. If you used the new and passed it an id option, then this method will update the underlying database.

This method will return true upon success.

	# save the current librarian object to the underlying database
	$librarian->commit();


=head2 delete()

This method simply deletes the current librarian object from the underlying database.

	# delete (drop) this librarian from the database
	$librarian->delete();
	
	
=head2 get_librarians()

Use this method to get all the librarians from the underlying database sorted by their name. This method returns an 
array of objects enabling you to loop through each object in the array and subsequent characteristics of each object;

	# get all librarians
	my @librarians = MyLibrary::Librarian->get_librarians();
	
	# process each librarian
	foreach my $l (@librarians) {
	
		# print the name
		print $l->name, "\n";
	
	}


=head1 ACKNOWLEDGEMENTS

I would like to thank the following people for providing input on how this package can be improved: Brian Cassidy and Ben Ostrowsky.


=head1 AUTHORS

Eric Lease Morgan <emorgan@nd.edu>
Robert Fox <rfox2@nd.edu>


=head1 HISTORY

September 29, 2003 - first public release.
April, 2004 - many modifications.

=cut


sub new {

	# declare local variables
	my ($class, %opts) = @_;
	my $self           = {};
	my @term_ids       = ();

	# check for an id
	if ($opts{id}) {
		
		# check for valid input, an integer
		if ($opts{id} =~ /\D/) {
		
			# output an error and return nothing
			croak "The id passed as input to the new method must be an integer: id = $opts{id} ";
			
		}
			
		# get a handle
		my $dbh = MyLibrary::DB->dbh();
		
		# find this record
		my $rv = $dbh->selectrow_hashref('SELECT * FROM librarians WHERE librarian_id = ?', undef, $opts{id});
		
		if (ref($rv) eq "HASH") {
			$self = $rv;
			$self->{term_ids} = $dbh->selectcol_arrayref("SELECT term_id FROM terms_librarians WHERE librarian_id = " . $opts{id});
		} else {
			return;
		}
	
	}
	
	# return the object
	return bless ($self, $class);
	
}


sub id {

	my $self = shift;
	return $self->{librarian_id};

}


sub telephone {

	# declare local variables
	my ($self, $telephone) = @_;
	
	# check for the existence of a telephone number 
	if ($telephone) { $self->{telephone} = $telephone }
	
	# return it
	return $self->{telephone};
	
}


sub name {

	# declare local variables
	my ($self, $name) = @_;
	
	# check for the existence of a name 
	if ($name) { $self->{name} = $name }
	
	# return it
	return $self->{name};
	
}


sub email {

	# declare local variables
	my ($self, $email) = @_;
	
	# check for the existence of an email address 
	if ($email) { $self->{email} = $email }
	
	# return it
	return $self->{email};
	
}


sub term_ids {

	# get myself and then the ids
	my $self = shift;
	my %opts = @_;
	my @new_related_terms;
	if ($opts{new}) {
		@new_related_terms = @{$opts{new}};
	}
	my @del_related_terms;
	if ($opts{del}) {
		@del_related_terms = @{$opts{del}};
	}
	my $sort_type;
	if ($opts{sort}) {
		if ($opts{sort} eq 'name') {
			$sort_type = 'name';
		}
	}
	my @related_terms;
	my $strict_relations;
	if ($opts{strict}) {
		if ($opts{strict} eq 'on') {
			$strict_relations = 'on';
		} elsif ($opts{strict} eq 'off') {
			$strict_relations = 'off';
		} elsif (($opts{strict} !~ /^\d$/ && ($opts{strict} == 1 || $opts{strict} == 0)) || $opts{strict} ne 'off' || $opts{strict} ne 'on') {
			$strict_relations = 'on';
		} else {
			$strict_relations = $opts{strict};
		}
	} else {
		$strict_relations = 'on';
	}

	if (@new_related_terms) {
		TERMS: foreach my $new_related_term (@new_related_terms) {
			if ($new_related_term !~ /^\d+$/) {
				croak "Only numeric digits may be submitted as term ids for librarian relations. $new_related_term submitted.";
			}
			if ($strict_relations eq 'on') {
				my $dbh = MyLibrary::DB->dbh();
				my $term_list = $dbh->selectcol_arrayref('SELECT term_id FROM terms');
				my $found_term;
				TERM_VAL: foreach my $term_list_val (@$term_list) {
					if ($term_list_val == $new_related_term) {
						$found_term = 1;
						last TERM_VAL;
					} else {
						$found_term = 0;
					}
				}
				if ($found_term == 0) {
					next TERMS;
				}
			}
			my $found;
			if ($self->{term_ids}) {
				TERMS_PRESENT: foreach my $related_term (@{$self->{term_ids}}) {
					if ($new_related_term == $related_term) {
						$found = 1;
						last TERMS_PRESENT;
					} else {
						$found = 0;
					}
				}
			} else {
				$found = 0;
			}
			if ($found) {
				next TERMS;
			} else {
				push(@{$self->{term_ids}}, $new_related_term);
			}
		}
	}
	if (@del_related_terms) {
		foreach my $del_related_term (@del_related_terms) {
			my @terms = @{$self->{term_ids}};
			my $j = scalar(@{$self->{term_ids}});
			for (my $i = 0; $i < scalar(@{$self->{term_ids}}); $i++) {
				if ($self->{term_ids}[$i] == $del_related_term) {
					splice(@{$self->{term_ids}}, $i, 1);
					$i = $j;
				}
			}
		}
	}
	
	# return a dereferenced array
	if (ref($self->{term_ids}) eq "ARRAY" && scalar(@{$self->{term_ids}}) >= 1) { 
		if ($sort_type) {
			if ($sort_type eq 'name') {
				my $dbh = MyLibrary::DB->dbh();
				my $term_id_string;
				foreach my $term_id (@{$self->{term_ids}}) {
					$term_id_string .= "$term_id, ";
				}
				chop($term_id_string);
				chop($term_id_string);
				$self->{term_ids} = $dbh->selectcol_arrayref("SELECT term_id from terms WHERE term_id IN ($term_id_string) ORDER BY term_name");	
			}
		}
		return @{$self->{term_ids}};
	} else {
		return;
	}
}


sub url {

	# declare local variables
	my ($self, $url) = @_;
	
	# check for the existence of librarian's url
	if ($url) { $self->{url} = $url }
	
	# return it
	return $self->{url};
	
}


sub commit {

	# get object
	my $self = shift;

	# get a database handle
	my $dbh = MyLibrary::DB->dbh();	
	
	# see if the object has an id
	if ($self->id()) {
	
		# update the librarians table with this id
		my $return = $dbh->do('UPDATE librarians SET name = ?, telephone = ?, email = ?, url = ? WHERE librarian_id = ?', undef, $self->name(), $self->telephone(), $self->email(), $self->url(), $self->id());
		if ($return > 1 || ! $return) { croak "Librarian update in commit() failed. $return records were updated." }

		# update librarian=>term relational integrity	
		my @term_ids = @{$self->{term_ids}};
		if (scalar(@term_ids) > 0 && @term_ids) {
			my $arr_ref = $dbh->selectall_arrayref('SELECT term_id FROM terms_librarians WHERE librarian_id =?', undef, $self->id());
			# determine which term ids stay put
			if (scalar(@{$arr_ref}) > 0) {
				foreach my $arr_val (@{$arr_ref}) {
					my $j = scalar(@term_ids);
					for (my $i = 0; $i < $j; $i++)  {
						if ($arr_val->[0] == $term_ids[$i]) {
							splice(@term_ids, $i, 1);
							$i = $j;
						}
					}
				}
			}
			# add the new associations
			foreach my $term_id (@term_ids) {
				my $return = $dbh->do('INSERT INTO terms_librarians (term_id, librarian_id) VALUES (?,?)', undef, $term_id, $self->id());
				if ($return > 1 || ! $return) { croak "Unable to update librarian=>term relational integrity. $return row
s were inserted." }
			}
			# determine which term associations to delete
			my @del_related_terms;
			my @term_ids = @{$self->{term_ids}};
			if (scalar(@{$arr_ref}) > 0) {
				foreach my $arr_val (@{$arr_ref}) {
					my $found;
					for (my $i = 0; $i < scalar(@term_ids); $i++)  {
						if ($arr_val->[0] == $term_ids[$i]) {
							$found = 1;
							last;
						} else {
							$found = 0;
						}
					}
					if (!$found) {
						push (@del_related_terms, $arr_val->[0]);
					}
				}
			}
			# delete removed associations
			foreach my $del_rel_term (@del_related_terms) {
				my $return = $dbh->do('DELETE FROM terms_librarians WHERE term_id = ? AND librarian_id = ?', undef, $del_rel_term, $self->id());
				if ($return > 1 || ! $return) { croak "Unable to delete librarian=>term association. $return rows were deleted." }
			}
		} elsif (scalar(@term_ids) <= 0 || !@term_ids) {
			my $return = $dbh->do('DELETE FROM terms_librarians WHERE librarian_id = ?',  undef, $self->id());
		}
	
	} else {
	
		# get a new sequence
		my $id = MyLibrary::DB->nextID();		
		
		# create a new record
		my $return = $dbh->do('INSERT INTO librarians (librarian_id, name, telephone, email, url) VALUES (?, ?, ?, ?, ?)', undef, $id, $self->name(), $self->telephone(), $self->email(), $self->url());
		if ($return > 1 || ! $return) { croak 'Librarian commit() failed.'; }
		$self->{librarian_id} = $id;
		
		# update librarian=>term relational integrity, if list of term ids was supplied via the constructor
		unless (!$self->{term_ids}) {
			my @term_ids = @{$self->{term_ids}};
			if (scalar(@term_ids) > 0 && @term_ids) {
				foreach my $term_id (@term_ids) {
					my $return = $dbh->do('INSERT INTO terms_librarians (term_id, librarian_id) VALUES (?,?)', undef, $term_id, $self->id());
					if ($return > 1 || ! $return) { croak "Unable to update librarian=>term relational integrity. $return rows were inserted." }
				}
			}
		}
		
	}
	
	# done
	return 1;
}


sub delete {

	# get myself
	my $self = shift;

	# check for id
	return 0 unless $self->{librarian_id};

	# delete this record
	my $dbh = MyLibrary::DB->dbh();
	my $rv = $dbh->do('DELETE FROM librarians WHERE librarian_id = ?', undef, $self->{librarian_id});
	if ($rv != 1) { croak ("Delete failed. Deleted $rv records.") } 

	# delete term associations
	$rv = $dbh->do('DELETE FROM terms_librarians WHERE librarian_id = ?', undef, $self->{librarian_id});

	# done
	return 1;

}


sub get_librarians {

	# scope varibles
	my $self     = shift;
	my @rv       = ();
	
	# create and execute a query
	my $dbh = MyLibrary::DB->dbh();
	my $rows = $dbh->prepare('SELECT librarian_id FROM librarians ORDER BY name');
	$rows->execute;
	
	# process each found row
	while (my $r = $rows->fetchrow_array) {
	
		# fill up the return value
		push(@rv, $self->new(id => $r));
				
	}
	
	# return the array	
	return @rv;
	
}


# return true, or else
1;
