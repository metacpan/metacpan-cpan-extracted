#!/usr/bin/perl

use Test::More tests => 20;
use strict;

# use the module
use_ok('MyLibrary::Review');

# create a review object
my $review = MyLibrary::Review->new();
isa_ok($review, "MyLibrary::Review");

# set the review's text
$review->review('This was a great book!');
is($review->review, 'This was a great book!', 'set review');

# set the reviewer's name
$review->reviewer_name('Dewey');
is($review->reviewer_name, 'Dewey', 'set reviewer_name');

# set the reviewer's email
$review->reviewer_email('emorgan@nd.edu');
is($review->reviewer_email, 'emorgan@nd.edu', 'set email');

# set the review's rating
$review->review_rating('5');
is($review->review_rating, '5', 'set review_rating');

# set the resource id being rated
$review->resource_id(601);
is($review->resource_id, 601, 'set resource_id');

# set the date of this review
$review->review_date('2003-10-31');
is($review->review_date, '2003-10-31', 'set review_date');

# save a new review record
is($review->commit, '1', 'commit() a new review record');

# get a review id
my $id = $review->review_id;
like ($id, qr/^\d+$/, 'get review_id()');

# get record based on an id
my $new_review = MyLibrary::Review->new(id => $id);
is ($new_review->review, 'This was a great book!', 'get review');
is ($new_review->review_rating, 5, 'get review_rating');
is ($new_review->resource_id, 601, 'get resource_id');
is ($new_review->reviewer_name, 'Dewey', 'get name');
is ($new_review->reviewer_email, 'emorgan@nd.edu', 'get review_email');
is ($new_review->review_date, '2003-10-31', 'get review_date');

# update a review
$new_review->reviewer_name('Alcuin');
$new_review->reviewer_email('eric_morgan@infomotions.com');
$new_review->commit;
my $even_newer_review = MyLibrary::Review->new(id => $id);
is ($even_newer_review->reviewer_name, 'Alcuin', 'commit an updated reviewer name');
is ($even_newer_review->reviewer_email, 'eric_morgan@infomotions.com', 'commit() an updated email address');

# get reviews
my @r = MyLibrary::Review->get_reviews;
my $flag = 0;
foreach $review (@r) { 

	if ($review->{reviewer_name} =~ /Alcuin/) { $flag = 1; }
	
}
is ($flag, 1, 'get_reviews worked and one of the reviewers was Alcuin');

# delete a message
is ($review->delete, '1', 'delete() a review');

