package MyLibrary::Patron::Links;

use MyLibrary::DB;
use Carp qw(croak);
use strict;

=head1 NAME

MyLibrary::Patron::Links;

=head1 SYNOPSIS

	# require the necessary module
	use MyLibrary::Patron::Links;

	# create a new patron link
	my $patron_link = MyLibrary::Patron::Links->new();

	# get a link id
	my $link_id = $patron_link->link_id();

	# set the attributes of the link
	$patron_link->link_name('CNN');
	$patron_link->link_url('http://my.site.com');
	$patron_link->patron_id(23);

	# save link to database
	$patron_link->commit();

	# get all links for a patron
	my @patron_links = MyLibrary::Patron::Links->get_links(patron_id => $patron_id);

	# delete a link from the database
	$patron_link->delete();

=head1 DESCRIPTION

This is a sub module for creating and manipulating personal patron links. Every link has a name, which is the URL display text, and the URL href itself. Every link must be associated with a particular patron. The module also allows for the retrieval of the complete list of links associated with a patron. The list will be alphabetized according to link name.

=head1 METHODS

=head2 new()

This class method is the constructor for this package. The method is responsible for initializing all attributes associated with a
 given Patron::Link object. The method can also be used to create a Patron object using a patron link id.

=head2 link_id()

This method is used exclusively to retrieve an exising patron link database id, if the patron link has been committed to the database. This method may not be used to set the link id in the database.

	# get a link id
	my $link_id = $patron_link->link_id();

=head2 link_name()

This method may be used to either get or set a link name. This is a required attribute, meaning that the object cannot be commited to the database if this attribute is left null.

	# set the link name
	$patron_link->link_name('CNN');

	# get the link name
	my $link_name = $patron_link->link_name();

=head2 link_url()

This attribute method should be used to either set or get the url associated with this patron link.

	# set the link URL
	$patron_link->link_URL('http://my.favoriteplace.com');

	# get the link URL
	my $link_URL = $patron_link->link_URL();

=head2 patron_id();

This method is used to set or get the patron id associated with a patron link. The patron must exist in the database or this method will throw an exception. The required attribute is the patron id, if setting the id. Otherwise, this method will always return the numeric patron id associated with the link.

	# set the patron id
	$patron_link->patron_id(23);

	# get the patron id
	my $patron_id = $patron_link->patron_id();

=head2 commit()

This method commits the patron link to the database. This method requires no arguments.

	# commit the patron link
	$patron_link->commit();

=head2 delete()

Use this method to delete a particular patron link from the database.

	# delete the patron link
	$patron_link->delete();

=head2 get_links

This is a class method that will return a list of patron link ids in link name order. The only required argument is the patron id. This method will return undef if no links exist corresponding to the patron id submitted.

	# get a list of patron link ids in name order
	my @patron_links = MyLibrary::Patron::Links->get_links(patron_id => $patron_id);

=head1 AUTHORS

Robert Fox <rfox2@nd.edu>

=cut

sub new {

	# declare a few variables
	my ($class, %opts) = @_;
	my $self = {};

	# check for an id
	if ($opts{id}) {
		
		# find this record
		my $dbh = MyLibrary::DB->dbh();
		my $rv = $dbh->selectrow_hashref('SELECT * FROM personallinks where link_id = ?', undef, $opts{id});
		if (ref($rv) eq "HASH") { $self = $rv }
		else { return }
	}

	# return the object
	return bless $self, $class;

}

sub link_name {

	my ($self, $name) = @_;
	if ($name) {$self->{link_name} = $name }
	else { return $self->{link_name} }

}

sub link_url {

	my ($self, $url) = @_;
	if ($url) {
		unless ($url =~ /^http:.+/) {
			croak ( 'Patron link URL does not begin with http.' );
		}
		$self->{link_url} = $url;
		return $self->{link_url};
	} else {
		return $self->{link_url};
	}

}

sub patron_id {

	my ($self, $patron_id) = @_;
	my $dbh = MyLibrary::DB->dbh();
	if ($patron_id) {
		my @patron_array = $dbh->selectrow_array('SELECT * FROM patrons WHERE patron_id = ?', undef, $patron_id);
		unless (scalar(@patron_array)) {
			croak ("Submitted patron id in patron_id(), $patron_id, does not correspond to an exising patron." );
		}
		$self->{patron_id} = $patron_id;
		return $self->{patron_id};

	} else {

		return $self->{patron_id};

	}	

}

sub link_id {
	
	my $self = shift;
	return $self->{link_id};

}

sub commit {

	my $self = shift;
	my $dbh = MyLibrary::DB->dbh();

	if ($self->link_id()) {

		my $return = $dbh->do('UPDATE personallinks SET link_name = ?, link_url = ?, patron_id = ? WHERE link_id = ?', undef, $self->link_name(), $self->link_url(), $self->patron_id(), $self->link_id());

		if ($return > 1 || ! $return) { croak "Patron link update in commit() failed. $return records were updated."; }

	} else {

		my $id = MyLibrary::DB->nextID();
		my $return = $dbh->do('INSERT INTO personallinks (link_id, patron_id, link_name, link_url) VALUES (?, ?, ?, ?)', undef, $id, $self->patron_id(), $self->link_name(), $self->link_url());
		if ($return > 1 || ! $return) { croak 'Patron link commit() failed.'; }
		$self->{link_id} = $id;

	}

	return 1;

}

sub get_links {

	my $class = shift;
	my %opts = @_;
	unless ($opts{patron_id} =~ /^\d+$/) {

		croak "Patron id not submitted. A valid numeric patron id must be submitted to the get_links() method.";

	}

	my $dbh = MyLibrary::DB->dbh();
	my @patron_array = $dbh->selectrow_array('SELECT * FROM patrons WHERE patron_id = ?', undef, $opts{patron_id});
	unless (scalar(@patron_array)) {
		croak "Valid patron id not submitted. No patron record exists corresponding to id number $opts{patron_id}.";
	}

	my $link_ids = $dbh->selectcol_arrayref("SELECT link_id FROM personallinks WHERE patron_id = ? ORDER BY link_name", undef, $opts{patron_id});

	unless (scalar(@{$link_ids})) {
		return;
	}

	return @{$link_ids};

}

sub delete {

	my $self = shift;
	
	if ($self->link_id()) {

		my $dbh = MyLibrary::DB->dbh();
		my $rv = $dbh->do('DELETE FROM personallinks WHERE link_id = ?', undef, $self->{link_id});
		if ($rv != 1) {croak ("Deleted $rv records. Please check the personallinks table for errors.");}
		return 1;

	}

	return 0;

}

1;
