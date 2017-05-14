package MyLibrary::Review;

use MyLibrary::DB;
use Carp;
use strict;

=head1 NAME

MyLibrary::Review


=head1 SYNOPSIS

	# use the module
	use MyLibrary::Review;
	
	# create a new review
	my $review = MyLibrary::Review->new;
	
	# give the review characteristics
	$review->review('This resource worked just fine more me.');
	$review->reviewer_name('Fred Kilgour');
	$review->reviewer_email('kilgour@oclc.org');
	$review->review_date('2002-10-31');
	$review->review_rating('3');
	
	# associate the review with a resource
	$review->resource_id(601);
	
	# save the review; create a new record or update it
	$review->commit;
	
	# get the id of the current review object
	$id = $review->review_id;
	
	# create a new review object based on an id
	my $review = MyLibrary::Review->new(id => $id);
	
	# display a review
	print '  Resource ID: ', $review->resource_id, "\n";
	print '       Review: ', $review->review, "\n";
	print '     Reviewer: ', $review->reviewer_name, "\n";
	print '        Email: ', $review->reviewer_email, "\n";
	print '       Rating: ', $review->review_rating, "\n";
	print '         Date: ', $review->review_date, "\n";
	

=head1 DESCRIPTION

The module provides a means of saving reviews of information resources to the underlying MyLibrary database.


=head1 METHODS

This section describes the methods available in the package.


=head2 new

Use this method to create a new review object. Called with no arguments, this method creates an empty object. Given an id, this method gets the review from the database associated accordingly.

	# create a new review object
	my $review = MyLibrary::Review->new;
  
	# create a review object based on a previously existing ID
	my $review = MyLibrary::Review->new(id => 3);


=head2 review_id

This method returns an integer representing the database key of the currently created review object.

	# get id of current review object
	my $id = $review->review_id;

You cannot set the review_id attribute.


=head2 review

This method gets and sets the text of the review for the current review object:

	# get the text of the current review object
	my $text = $review->review;
	
	# set the current review object's text
	$review->review('I would recommend this resoruce to anyone.');
	

=head2 reviewer_name

Use this method to get and set the name of a review's reviewer:

	# get the reviewer's name
	my $reviewer = $review->reviewer_name;
	
	# set the reviwer's name
	$librarian->reviewer_name('Paul Evan Peters');


=head2 reviewer_email

Usse this method to get and set the reviewer's email address of the review object:

	# get the email address
	my $email_address = $review->reviewer_email;
	
	# set the email address
	$review->reviewer_email('pep@greatbeyond.org');


=head2 date

Set or get the date attribute of the review object with this method:

	# get the date attribute
	my $review_date = $review->review_date;
	
	# set the date
	$review->review_date('2003-10-31');

The date is expected to be in the format of YYYY-MM-DD.


=head2 review_rating

Use this method to set a rating in the review. 

	# set the rating
	$review->review_rating('3');
	
	# get rating
	my $review_rating = $review->review_rating;
	
Ratings can be strings up to 255 characters in length, but this attribute is intended to be an integer value for calculating purposes. The programer can use the attribute in another manner if they so choose.	

=head2 resource_id

Use this method to get and set what resource is being reviewed:

	# set the resource
	$review->resource_id('601');
	
	# get resource id
	my $resource_id = $review->resource_id;
	

=head2 commit

Use this method to save the review object's attributes to the underlying database. If the object's data has never been saved before, then this method will create a new record in the database. If you used the new and passed it an id option, then this method will update the underlying database.

This method will return true upon success.

	# save the current review object to the underlying database
	$review->commit;


=head2 delete

This method simply deletes the current review object from the underlying database.

	# delete (drop) this review from the database
	$review->delete();
	
	
=head2 get_reviews

Use this method to get all the reviews from the underlying database. It method returns an array of objects enabling you to loop through each object in the array and subsequent characteristics of each object;

	# get all reviews
	my @reviews = MyLibrary::Review->get_reviews;
	
	# initialize counters
	my $total_rating  = 0;
	my $total_reviews = 0;
	
	# process each review
	foreach my $r (@reviews) {
	
		# look for a particular resource
		if ($r->resource_id == 601) {
		
			# update counters
			$total_rating = $total_rating + $r->review_rating;
			$total_reviews = $total_reviews + 1;
			
		}
	
	}

	# check for reviews
	if ($total_reviews) {
	
		# print the average rating
		print "The average rating for resource 601 is: " . ($total_rating / $total_reviews)
	
	}


=head1 AUTHOR

Eric Lease Morgan <emorgan@nd.edu>


=head1 HISTORY

October 31, 2003 - first public release; Halloween


=cut


sub new {

	# declare local variables
	my ($class, %opts) = @_;
	my $self           = {};

	# check for an id
	if ($opts{id}) {
		
		# check for valid input, an integer
		if ($opts{id} =~ /\D/) {
		
			# output an error and return nothing
			croak "The id passed as input to the new method must be an integer: id = $opts{id} ";
			return;
			
		}
			
		# get a handle
		my $dbh = MyLibrary::DB->dbh();
		
		# find this record
		my $rv = $dbh->selectrow_hashref('SELECT * FROM reviews WHERE review_id = ?', undef, $opts{id});
		
		# check for a hash
		return unless ref($rv) eq 'HASH';

		# fill myself up with the fetched data
		$self = bless ($rv, $class);
			
	}
	
	# return the object
	return bless ($self, $class);
	
}


sub review_id {

	my $self = shift;
	return $self->{review_id};

}


sub review {

	# declare local variables
	my ($self, $review) = @_;
	
	# check for the existence of a telephone number 
	if ($review) { $self->{review} = $review }
	
	# return it
	return $self->{review};
	
}


sub reviewer_name {

	# declare local variables
	my ($self, $reviewer_name) = @_;
	
	# check for the existence of a name 
	if ($reviewer_name) { $self->{reviewer_name} = $reviewer_name }
	
	# return it
	return $self->{reviewer_name};
	
}


sub reviewer_email {

	# declare local variables
	my ($self, $reviewer_email) = @_;
	
	# check for the existence of an email address 
	if ($reviewer_email) { $self->{reviewer_email} = $reviewer_email }
	
	# return it
	return $self->{reviewer_email};
	
}



sub review_date {

	# declare local variables
	my ($self, $date) = @_;
	
	# check for the existence of date
	if ($date) { $self->{review_date} = $date }
	
	# return it
	return $self->{review_date};
	
}


sub review_rating {

	# declare local variables
	my ($self, $review_rating) = @_;
	
	# check for the existence of rating
	if ($review_rating) { $self->{review_rating} = $review_rating }
	
	# return it
	return $self->{review_rating};
	
}


sub resource_id {

	# declare local variables
	my ($self, $resource_id) = @_;
	
	# check for the existence of resource id
	if ($resource_id) { $self->{resource_id} = $resource_id }
	
	# return it
	return $self->{resource_id};
	
}


sub commit {

	# get myself, :-)
	my $self = shift;
	
	# get a database handle
	my $dbh = MyLibrary::DB->dbh();	
	
	# see if the object has an id
	if ($self->review_id) {
	
		# update the review table with this id
		my $return = $dbh->do('UPDATE reviews SET review = ?, reviewer_name = ?, reviewer_email = ?, review_date = ?, review_rating = ?, resource_id = ? WHERE review_id = ?', undef, $self->review, $self->reviewer_name, $self->reviewer_email, $self->review_date, $self->review_rating, $self->resource_id, $self->review_id);
		if ($return > 1 || ! $return) { croak "Review update in commit() failed. $return records were updated." }
		
	}
	
	else {
	
		# get a new sequence
		my $id = MyLibrary::DB->nextID();		
		
		# create a new record
		my $return = $dbh->do('INSERT INTO reviews (review_id, review, reviewer_name, reviewer_email, review_date, review_rating, resource_id) VALUES (?, ?, ?, ?, ?, ?, ?)', undef, $id, $self->review, $self->reviewer_name, $self->reviewer_email, $self->review_date, $self->review_rating, $self->resource_id);
		if ($return > 1 || ! $return) { croak 'Review commit() failed.'; }
		$self->{review_id} = $id;
			
	}
	
	# done
	return 1;
	
}


sub delete {

	# get myself
	my $self = shift;

	# check for id
	return 0 unless $self->{review_id};

	# delete this record
	my $dbh = MyLibrary::DB->dbh();
	my $rv = $dbh->do('DELETE FROM reviews WHERE review_id = ?', undef, $self->{review_id});
	if ($rv != 1) { croak ("Deleted $rv records. I'll bet this isn't what you wanted.") } 
	
	# done
	return 1;

}


sub get_reviews {

	# scope varibles
	my $self     = shift;
	my @rv       = ();
	
	# create and execute a query
	my $dbh = MyLibrary::DB->dbh();
	my $rows = $dbh->prepare('SELECT review_id FROM reviews');
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
