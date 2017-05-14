package MyLibrary::Patron;

use MyLibrary::DB;
use MyLibrary::Patron::Links;
use Carp qw(croak);
use strict;


=head1 NAME

MyLibrary::Patron

=head1 SYNOPSIS

	# require the necessary module
	use MyLibrary::Patron;

	# create an undefined Patron object
	my $patron = MyLibrary::Patron->new();

	# get patron id
	my $patron_id = $patron->patron_id();

	# set the various attributes of a Patron object
	$patron->patron_firstname('Robert');
	$patron->patron_surname('Fox');
	$patron->patron_image('/path/to/image.jpg');
	$patron->patron_url('http://homesite/for/patron');
	$patron->patron_username('username');
	$patron->patron_organization('University of Notre Dame');
	$patron->patron_address_1('address info');
	$patron->patron_can_contact(1);
	$patron->patron_password('#$@$^&*');
	$patron->patron_total_visits(23);
	$patron->patron_last_visit('2005-15-08');
	$patron->patron_remember_me(1);
	$patron->patron_email('yourname@nd.edu');
	$patron->patron_stylesheet_id(25);

	# commit a Patron to the database
	$patron->commit();

	# manipulate patron to resource relations
	my @patron_resources = $patron->patron_resources(new => [@resource_ids]);
	$patron->patron_resources(del => [@resource_ids]);
	my @patron_resources = $patron->patron_resources(sort => 'name');

	# create, delete and retrieve associated personal links
	$patron->add_link(link_name => 'CNN', link_url => 'http://mysite.com');
	my $num_deleted = $patron->delete_link(link_id => $link_id);
	my @patron_links = $patron->get_links();

	# get or set personal link attributes
	my $link_id = $patron_links[0]->link_id();
	$patron_links[0]->link_name('CNN2');
	my $link_name = $patron_links[0]->link_name();
	my $link_url = $patron_links[0]->link_url();

	# resource usage counts
	MyLibrary::Patron->resource_usage(action => 'increment', patron => $patron_id, resource => $resource_id);
	my $usage_count = MyLibrary::Patron->resource_usage(action => 'resource_usage_count', patron => $patron_id, resource => $resource_id);
	my $resource_usage_count = MyLibrary::Patron->resource_usage(action => 'absolute_usage_count', resource => $resource_id);
	my $patron_usage_count = MyLibrary::Patron->resource_usage(action => 'patron_usage_count', resource => $resource_id);
	my $patron_resource_count = MyLibrary::Patron->resource_usage(action => 'patron_resource_count', patron => $patron_id);

	# manipulate patron -> term relations
	my @patron_terms = $patron->patron_terms();
	$patron->patron_terms(new => [@term_ids]);
	$patron->patron_terms(del => [@term_ids]);
	my @patron_terms = $patron->patron_terms(sort => 'name');

	# get a list of Patron objects
	my @patrons = MyLibrary::Patron->get_patrons();

	# delete a Patron object from the database
	$patron->delete();

=head1 DESCRIPTION

Use this module to get and set patron information to a MyLibrary database as well as retrieve a list of all Patron objects in a MyLibrary instance. This package also contains several methods which can be used to retrieve related information about a given patron such as which resources they have selected as well as their customized interface.

=head1 METHODS

=head2 new()

This class method is the constructor for this package. The method is responsible for initializing all attributes associated with a given Patron object. The method can also be used to create a Patron object using a patron id or name. The patron would thus already need to exist in the database in order for these parameters to have any effect.

=head2 patron_id()

This method is used exclusively to retrieve an exising patron's database id, if the patron has been commited to the database. This method may not be used to set a patron's database id.

	# get patron id
	my $patron_id = $patron->patron_id();

This is a required Patron object attribute.

=head2 patron_firstname()

This method may be used to either get or set a patron's first name. This is a required attribute, meaning that the object cannot be commited to the database if this attribute is left null.

	# set patron_firstname()
	$patron->patron_firstname('Robert');

	# get patron_firstname()
	my $patron_first_name = $patron->patron_firstname();

=head2 patron_surname()

This method may be used to either get or set a patorn's last name. This is a required attribute, meaning that the object cannot be commited to the database if this attribute is left null.

	# set patron_surname()
	$patron->patron_surname('Miller');

	# get patron_surname()
	my $patron_last_name = $patron->patron_surname();

=head2 patron_image()

This method was added in response to certain metadata standards (namely FOAF), and allows the programmer to add a path within a patron record to an image associated with the patron. For example, the image could be chosen by the patron or a picture of the patron. This is not a required attribute.

	# set the patron_image()
	$patron->patron_image('/usr/local/bin/me.jpg');

	# get the patron_image()
	my $patron_image = $patron->patron_image();

=head2 patron_email()

This method gets or sets a patron's email address. This is not a required attribute.

	# set patron's email address
	$patron->patron_email('eric');

	# get patron's email address
	my $email = $patron->patron_email();

=head2 patron_address_1(), patron_address_2(), patron_address_3(), patron_address_4(), patron_address_5()

These methods should be used to set or get the patron's address information. Typically, this is a street address or building location. This is not a required attribute. The five address fields can contain any information which is appropriate for indicating the patron's full address. These fields are intentionally open ended so that address formats from various nationalities can be stored in these fields. Each field can correspond to a particular line in an address.

	# set a patron's address part one
	$patron->patron_address_1('2634 Willow Street');

	# get a patron's address part one
	my $patron_address_one = $patron->patron_address_1();

=head2 patron_can_contact()

This method should be used to set the can_contact flag. This is a binary attribute, and is not required. However, a devault value of '0' ('Do not contact') will be set if no value is indicated. The input to this method will be sanitized from non-binary content.

	# set a patron's can_contact flag
	$patron->patron_can_contact(1);

	# get a patron's can_contact flag
	my $patron_contact_flag = $patron->patron_can_contact();

=head2 patron_password()

This method can be used to either retrieve or set a patron's password. This attribute will only be used when the system relies upon the 'default' method of authentication (which is to store patron passwords locally as opposed to relying upon an insitutional authentication system). The non-encrypted password chosen and entered by the patron will be encrypted. When the password is retrieved, it will also be in an encrypted form for security purposes. Authentication methods can then be used to perform password verification against this patron attribute. Alpha or numeric digits may be used in a patron's password in any order, however, authentication module methods may place certain requirements on password length and complexity. This method simply encrypts, stores and retrieves patron passwords.

	# set the patron's password
	my $entered_password = $input->{'password'};
	$patron->patron_password($entered_password);

	# retrieve the encrypted form of a patron's password
	my $patron_password = $patron->patron_password();

=head2 patron_remember_me()

This method should be used to set the wants_cookie flag, which indicates whether the patron desires to have a "permanent" cookie placed on the current computer they are working on. This will allow the patron to automatically log into their MyLibrary account the next time they use this particular machine. This is a binary attribute, and is not required. However, a devault value of '0' ('Does not want permanent cookie') will be set if no value is indicated. The input to this method will be sanitized from non-binary content.

	# set a patron's wants_cookie flag
	$patron->patron_remember_me(1);

	# get a patron's wants_cookie flag
	my $patron_wants_cookie_flag = $patron->patron_remember_me();

=head2 patron_username()

This method should be used to either set or get a patron's system username. The ultimate source of the username content will either come from the patron themselves or from an external authority (such as an LDAP database). This is the attribute the patron uses to identify themselves to the MyLibrary system. This is a required attribute.

	# set the patron's username
	$patron->patron_username('johnsmith');

	# get a patron's username
	my $patron_username = $patron->patron_username();

=head2 patron_organization()

Use this method as an accessor to the parent organization for the patron. This method will perform the standard set and get operations on this attribute. The organization should correspond to the parent institution within which the patron resides, or could also correspond to sub organizations within the parent institution.

	# set the patron's organization
	$patron->patron_organization('University of Notre Dame');

	# get a patron's organization name
	my $patron_organization = $patron->patron_organization();

=head2 patron_last_visit()

This method can be used to get or set the date of the last time the patron visited the MyLibrary system. The input to this method will be sanitized and if an inappropriate date is input, the method will simply not execute. This is not a required attribute.

	# set the date of the last visit
	$patron->patron_last_visit('2003-10-05');

	# get the date of the last visit
	my $patron_last_visit = $patron->patron_last_visit();

=head2 patron_total_visits()

This method can be used to either retrieve the total number of visits or increment the total visit count by the amount indicated. The amount indicated must be a positive integer. However, this is not a required attribute. Any other parameter input for this method will simply be ignored.

	# increment the number of total visits by a certain number
	$patron->patron_total_visits(increment => 6);

	# retrieve the number of total visits
	my $patron_total_visits = $patron->patron_total_visits(); 

=head2 patron_stylesheet_id()

Patrons may indicate a preference for a certain style of their interface. This will organize certain interface attributes such as coordinating colors, graphical options and positioning of interface elements. The stylesheets supplied by MyLibrary administrators will provide the patron with a choice of style for their page. This method must be used to either retrieve or set the stylesheet id with which the patron will be associated. The input to this method must be an integer. This is a required attribute. If no stylesheet id is provided, a default stylesheet will be assigned when the patron initially creates their page. However, the patron can choose another stylesheet at any time.

	# associate a stylesheet with a patron
	$patron->patron_stylesheet_id(16);

	# retrieve the stylesheet associated with this patron
	my $patron_stylesheet_id = $patron->patron_stylesheet_id();

=head2 commit()

This method will simply commit the current Patron object to the database and update any attribute information that has changed for an existing patron. Database integrity checks will be performed upon commit.

	# commit the Patron object to the database
	$patron->commit();

=head2 patron_resources()

This object method can be used to create or delete relations between patron objects and resources objects in the underlying database. It can also be used to obtain a list of resource ids associated with a particular patron. The method always returns the current list of resource ids associated with a patron object regardless of the parameters passed to it. If the sort parameter is passed, the list of resource ids returned will be sorted. Currently, sorting is only available by resource name ('name').

Null will be returned if no resources are associated with the patron object. The method will also check to make sure that resources exist that are to be added or deleted. If resource ids are passed to this method which do not correspond to an existing resource object, they will be ignored.

The resources associated with the patron object are, in effect, "owned" by the patron. In other words, these resources have been hand picked for the patron or by the patron in order to form a specialized list somehow associated with the patron. For example, resources may be in the subject area in which the patron is interested, or a list of a certain type of resource that the patron regularly uses. Also, a default list of resources may be created for the patron and this method can be used to make that association.

	# simply return a list of associated resource ids
	my @patron_resources = $patron->patron_resources();

	# retrieve a sorted list
	my @sorted_resource_list = $patron->patron_resources(sort => 'name');

	# add a list of resources to a patron
	$patron->patron_resources(new => [@resource_ids]);

	# delete a list of resources from a patron
	$patron->patron_resources(del => [@resource_ids]);

=head2 resource_usage()

This is a class method that can be used to retrieve usage counts based on a number of criteria or increment usage counts for a particular patron and resource. Regarding statistical usage retrieval, counts can be generated according to number of uses by a single patron for a single resource, a group of resources, or statistical tidbits like how many patrons have used a particular resource. The output is entirely dependent upon the type and combination of parameters passed to the method.

Examples for each combination of parameters and output follow.

	# simply increment the usage value for a patron and particular resource
	MyLibrary::Patron->resource_usage(action => 'increment', patron => $patron_id, resource => $resource_id);

	# retrieve the resource usage count for a patron
	my $usage_count = MyLibrary::Patron->resource_usage(action => 'resource_usage_count', patron => $patron_id, resource => $resource_id);

	# determine an absolute usage count for a patricular resource
	my $resource_usage_count = MyLibrary::Patron->resource_usage(action => 'absolute_usage_count', resource => $resource_id);

	# determine how many patrons have used a particular resource at least once
	my $patron_usage_count = MyLibrary::Patron->resource_usage(action => 'patron_usage_count', resource => $resource_id);

	# retrieve a count of resources a particular patron has used
	my $patron_resource_count = MyLibrary::Patron->resource_usage(action => 'patron_resource_count', patron => $patron_id);

=head2 patron_terms()

This object method should be used to manipulate relations between patron and term objects. The output is always the current list of term ids associated with the patron or null. The output list can be sorted by term name. Term object relations can be created or deleted using this method.

	# get an unordered list of term ids
	my @patron_terms = $patron->patron_terms();

	# get a name sorted list of term ids
	my @patron_terms = $patron->patron_terms(sort => 'name');

	# add term assciations
	$patron->patron_terms(new => [@term_ids]);

	# delete term associations
	$patron->patron_terms(del => [@term_ids]);

=head2 delete()

This method is used to delete a Patron object from the database. This is an irreversible process.

	# delete patron from database
	$patron->delete();

=head2 get_patrons()

This is a class method that will allow the programmer to retrieve all of the patron objects which currently exist in a MyLibrary instance. These are full class objects and any object methods can be used on the objects retrieved using this method. The method will return an array of Patron objects.

	# get all patron objects
	my @patrons = MyLibrary::Patron->get_patrons();

=head1 AUTHORS

Robert Fox <rfox2@nd.edu>
Eric Lease Morgan <emorgan@nd.edu>

=cut

sub new {
	
	# declare a few variables
	my ($class, %opts) = @_;
	my $self = {};
	
	# check for an id
	if ($opts{id}) {
	
		# find this record
		my $dbh = MyLibrary::DB->dbh();
		my $rv = $dbh->selectrow_hashref('SELECT * FROM patrons WHERE patron_id = ?', undef, $opts{id});
		if (ref($rv) eq "HASH") { $self = $rv }
		else { return }
	
	# check for username		
	} elsif ($opts{username}) {
	
		# get a record based on this username
		my $dbh = MyLibrary::DB->dbh();
		my $rv = $dbh->selectrow_hashref('SELECT * FROM patrons WHERE patron_username = ?', undef, $opts{username});
		if (ref($rv) eq "HASH") { $self = $rv }
		else { return }
		
	}

	# return the object
	return bless $self, $class;
	
}


sub patron_email {
	my ($self, $email) = @_;
	if ($email) { $self->{patron_email} = $email }
	else { return $self->{patron_email} }
}


sub patron_firstname {
	my ($self, $name_first) = @_;
	if ($name_first) { $self->{patron_firstname} = $name_first }
	else { return $self->{patron_firstname} }
} 


sub patron_surname {
	my ($self, $name_last) = @_;
	if ($name_last) { $self->{patron_surname} = $name_last }
	else { return $self->{patron_surname} }
}

sub patron_image {
	my ($self, $image) = @_;
	if ($image) { $self->{patron_image} = $image }
	else { return $self->{patron_image} }
}

sub patron_url {
	my ($self, $url) = @_;
	if ($url) { $self->{patron_url} = $url }
	else { return $self->{patron_url} }
}

sub patron_password {
	my ($self, $password) = @_;
	if ($password) { 
		my $encrypted_password = $self->_encrypt_password($password);
		$self->{patron_password} = $encrypted_password; 
	} else { 
		return $self->{patron_password}; 
	}
}


sub patron_address_1 {
	my ($self, $address_1) = @_;
	if ($address_1) { $self->{patron_address_1} = $address_1 }
	else { return $self->{patron_address_1} }
}


sub patron_address_2 {
	my ($self, $address_2) = @_;
	if ($address_2) { $self->{patron_address_2} = $address_2 }
	else { return $self->{patron_address_2} }
}

sub patron_address_3 {
	my ($self, $address_3) = @_;
	if ($address_3) { $self->{patron_address_3} = $address_3 }
	else { return $self->{patron_address_3} }
}

sub patron_address_4 {
	my ($self, $address_4) = @_;
	if ($address_4) { $self->{patron_address_4} = $address_4 }
	else { return $self->{patron_address_4} }
}


sub patron_address_5 {
	my ($self, $address_5) = @_;
	if ($address_5) { $self->{patron_address_5} = $address_5 }
	else { return $self->{patron_address_5} }
}

sub patron_can_contact {
	my ($self, $patron_can_contact) = @_;
	if ($patron_can_contact) { $self->{patron_can_contact} = $patron_can_contact }
	else { return $self->{patron_can_contact} }
}

sub patron_remember_me {
	my ($self, $wants_cookie) = @_;
	if ($wants_cookie) { $self->{patron_remember_me} = $wants_cookie }
	else { return $self->{patron_remember_me} }
}


sub patron_username {
	my ($self, $username) = @_;
	if ($username) { $self->{patron_username} = $username }
	else { return $self->{patron_username} }
}

sub patron_organization {
	my ($self, $organization) = @_;
	if ($organization) { $self->{patron_organization} = $organization }
	else { return $self->{patron_organization} }
}

sub patron_last_visit {
	my ($self, $last_visit) = @_;
	if ($last_visit) { $self->{patron_last_visit} = $last_visit }
	else { return $self->{patron_last_visit} }
}


sub patron_total_visits {
	my ($self, $total_visits) = @_;
	if ($total_visits) { $self->{patron_total_visits} = $total_visits }
	else { return $self->{patron_total_visits} }
}


sub patron_stylesheet_id {
	my ($self, $stylesheet_id) = @_;
	if ($stylesheet_id) { $self->{patron_stylesheet_id} = $stylesheet_id }
	else { return $self->{patron_stylesheet_id} }
}


sub patron_id {
	my $self = shift;
	return $self->{patron_id};
}


sub commit {

	my $self = shift;
	my $dbh = MyLibrary::DB->dbh();	

	if ($self->patron_id()) {

		my $return = $dbh->do('UPDATE patrons SET patron_firstname = ?, patron_surname = ?, patron_email = ?, patron_image =  ?, patron_url = ?, patron_username = ?, patron_organization = ?, patron_address_1 = ?, patron_address_2 = ?, patron_address_3 = ?, patron_address_4 = ?, patron_address_5 = ?, patron_can_contact = ?, patron_password = ?, patron_total_visits = ?, patron_last_visit = ?, patron_remember_me = ?, patron_stylesheet_id = ? WHERE patron_id = ?', undef, $self->patron_firstname(), $self->patron_surname(), $self->patron_email(), $self->patron_image(), $self->patron_url(), $self->patron_username(), $self->patron_organization(), $self->patron_address_1(), $self->patron_address_2(), $self->patron_address_3(), $self->patron_address_4(), $self->patron_address_5(), $self->patron_can_contact(), $self->patron_password(), $self->patron_total_visits(), $self->patron_last_visit(), $self->patron_remember_me(), $self->patron_stylesheet_id(), $self->patron_id());

		if ($return > 1 || ! $return) { croak "Patron update in commit() failed. $return records were updated."; }

	} else {

		my $id = MyLibrary::DB->nextID();		
		my $return = $dbh->do('INSERT INTO patrons (patron_id, patron_firstname, patron_surname, patron_email, patron_image, patron_url, patron_username, patron_organization, patron_address_1, patron_address_2, patron_address_3, patron_address_4, patron_address_5, patron_can_contact, patron_password, patron_total_visits, patron_last_visit, patron_remember_me, patron_stylesheet_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', undef, $id, $self->patron_firstname(), $self->patron_surname(), $self->patron_email(), $self->patron_image(), $self->patron_url(), $self->patron_username(), $self->patron_organization(), $self->patron_address_1(), $self->patron_address_2(), $self->patron_address_3(), $self->patron_address_4(), $self->patron_address_5(), $self->patron_can_contact(), $self->patron_password(), $self->patron_total_visits(), $self->patron_last_visit(), $self->patron_remember_me(), $self->patron_stylesheet_id(), $self->patron_id());
		if ($return > 1 || ! $return) { croak 'Patron commit() failed.'; }
		$self->{patron_id} = $id;

	}

	return 1;

}

sub patron_resources {

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
	if ($opts{'sort'}) {
		if ($opts{'sort'} eq 'name') {
			$sort = 'resource_name';
		}
	}

	unless ($self->patron_id() =~ /^\d+$/) {
		croak "Patron id not found. Resource associations cannot be made with a patron object which is not initialized. Please run commit() against this patron object first.";
	}

	my $dbh = MyLibrary::DB->dbh();

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
				croak "Only numeric digits may be submitted as resource ids for resource relations. $new_related_resource submitted.";
			}

			# check to make sure this resource exists
			if ($strict_relations eq 'on') {
				my @resource_array = $dbh->selectrow_array('SELECT * FROM resources WHERE resource_id = ?', undef, $new_related_resource);
				unless (scalar(@resource_array)) {
					next RESOURCES;
				}
			}

			# check to see if this resource already exists for the patron
			my 	@resource_association = $dbh->selectrow_array('SELECT * FROM patron_resource WHERE patron_id = ? AND resource_id = ? AND patron_owned = 1', undef, $self->patron_id(), $new_related_resource);
			if (scalar(@resource_association)) {
				next RESOURCES;
			} else {
				my $return = $dbh->do('INSERT INTO patron_resource (patron_id, resource_id, patron_owned) VALUES (?,?,?)', undef, $self->patron_id(), $new_related_resource, 1);
				if ($return > 1 || ! $return) {croak "Unable to create patron->resource association. $return rows were inserted.";}
			}
		}
	}

	if (@del_related_resources) {
		my $sth = $dbh->prepare('DELETE FROM patron_resource WHERE patron_id = ? and resource_id = ?');
		foreach my $related_resource (@del_related_resources) {
			$sth->execute($self->patron_id(), $related_resource);
		}
	}

	my $related_resource_ids;
	if ($opts{'sort'}) {
		$related_resource_ids = $dbh->selectcol_arrayref("SELECT pr.resource_id FROM patron_resource pr, resources r WHERE pr.patron_id = ? AND pr.patron_owned = 1 AND pr.resource_id = r.resource_id ORDER BY r.$sort", undef, $self->patron_id());
	} else {	
		$related_resource_ids = $dbh->selectcol_arrayref('SELECT resource_id FROM patron_resource WHERE patron_id = ? AND patron_owned = 1', undef, $self->patron_id());
	}

	return @{$related_resource_ids};

}

sub add_link {

	my $self = shift;
	my %opts = @_;
	unless ($opts{link_name} && $opts{link_url}) {
		croak ("Missing parameter for add_link(). Both a link name and link url must be submitted.");
	}
	
	my $new_link = MyLibrary::Patron::Links->new();
	$new_link->link_name($opts{link_name});
	$new_link->link_url($opts{link_url});
	$new_link->patron_id($self->patron_id());
	$new_link->commit();

}

sub delete_link {

	my $self = shift;
	my %opts = @_;
	unless ($opts{link_id}) {
		croak ("Missing parameter for delete_link(). A link id must be submitted.");
	}

	my $del_link = MyLibrary::Patron::Links->new(id => $opts{link_id});
	my $return = $del_link->delete();
	return $return;

}

sub get_links {

	my $self = shift;
	my @link_ids = MyLibrary::Patron::Links->get_links(patron_id => $self->patron_id());
	my @return_objects = ();
	foreach my $link_id (@link_ids) {
		my $link = MyLibrary::Patron::Links->new(id =>$link_id);
		push(@return_objects, $link);
	}

	if (scalar(@return_objects) >= 1) {
		return @return_objects;
	} else {
		return;
	}

}

sub patron_terms {

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
	
	my $sort;
	if ($opts{'sort'}) {
		if ($opts{'sort'} eq 'name') {
			$sort = 'term_name';
		}
	}

	unless ($self->patron_id() =~ /^\d+$/) {
		croak "Patron id not found. Resource associations cannot be made with a patron object which is not initialized. Please run commit() against this patron object first.";
	}

	my $dbh = MyLibrary::DB->dbh();

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

	if (@new_related_terms) {
		TERMS: foreach my $new_related_term (@new_related_terms) {
			
			if ($new_related_term !~ /^\d+$/) {
				croak "Only numeric digits may be submitted as term ids for term relations. $new_related_term submitted.";
			}

			# check to make sure this term exists
			if ($strict_relations eq 'on') {
				my @term_array = $dbh->selectrow_array('SELECT * FROM terms WHERE term_id = ?', undef, $new_related_term);
				unless (scalar(@term_array)) {
					next TERMS;
				}
			}

			# check to see if this term already exists for the patron
			my @term_association = $dbh->selectrow_array('SELECT * FROM patron_term WHERE patron_id = ? AND term_id = ?', undef, $self->patron_id(), $new_related_term);
			if (scalar(@term_association)) {
				next TERMS;
			} else {
				my $return = $dbh->do('INSERT INTO patron_term (patron_id, term_id) VALUES (?,?)', undef, $self->patron_id(), $new_related_term);
				if ($return > 1 || ! $return) {croak "Unable to create patron->term association. $return rows were inserted.";}
			}
		}
	}

	if (@del_related_terms) {
		my $sth = $dbh->prepare('DELETE FROM patron_term WHERE patron_id = ? and term_id = ?');
		foreach my $related_term (@del_related_terms) {
			$sth->execute($self->patron_id(), $related_term);
		}
	}

	my $related_term_ids;
	if ($opts{'sort'}) {
		$related_term_ids = $dbh->selectcol_arrayref("SELECT pt.term_id FROM patron_term pt, terms t WHERE pt.patron_id = ? AND pt.term_id = t.term_id ORDER BY t.$sort", undef, $self->patron_id());
	} else {
		$related_term_ids = $dbh->selectcol_arrayref('SELECT term_id FROM patron_term WHERE patron_id = ?', undef, $self->patron_id());
	}

	return @{$related_term_ids};

}


sub resource_usage {

	my $class = shift;
	my %opts = @_;

	my $dbh = MyLibrary::DB->dbh();

	unless ($opts{action}) {
		croak "An action parameter must be submitted to this method. Valid action parameter types are increment, resource_usage_count, absolute_usage_count, patron_usage_count and patron_resource_count. Other parameters are also required depending on the action.";
	} 

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

	if ($opts{action} eq 'increment') {

		unless ($opts{patron} && $opts{patron}) {
			croak "A valid patron and resource id must be submitted in the patron parameter in order to perform this action. One of these parameters was not passed.";
		}

		if ($opts{patron} !~ /^\d+$/) {
			croak "A valid patron id must be submitted in the patron parameter in order to perform this action.";
		}

		if ($opts{resource} !~ /^\d+$/) {
			croak "A valid resource id must be submitted in the patron parameter in order to perform this action.";
		}

		my @current_count_array = $dbh->selectrow_array('SELECT usage_count FROM patron_resource WHERE patron_id = ? AND resource_id = ?', undef, $opts{patron}, $opts{resource});
		my $current_count = $current_count_array[0];
		my $count_increment = ++$current_count;
		my $return = $dbh->do('UPDATE patron_resource SET usage_count = ? WHERE patron_id = ? AND resource_id = ?', undef, $count_increment, $opts{patron}, $opts{resource}); 
		if ($return > 1 || ! $return) { croak "Increment usage count failed for patron_id $opts{patron} and resource_id $opts{resource}." }

		# update patron 0 for absolute count
		my @zero_count_array = $dbh->selectrow_array('SELECT usage_count FROM patron_resource WHERE patron_id = ? AND resource_id = ?', undef, 0, $opts{resource});
		my $zero_count = $zero_count_array[0];
		if (! $zero_count) {
			$dbh->do('INSERT INTO patron_resource (patron_id, resource_id, usage_count) VALUES (?,?,1)', undef, 0, $opts{resource});
		} else {
			my $new_count = ++$zero_count;
			my $return = $dbh->do('UPDATE patron_resource SET usage_count = ? WHERE patron_id = ? AND resource_id = ?', undef, $new_count, 0, $opts{resource});
			if ($return > 1 || ! $return) { croak "Increment usage count failed for patron_id 0 and resource_id $opts{resource}."; }
		}

		
	} elsif ($opts{action} eq 'resource_usage_count') {

		unless ($opts{patron} && $opts{patron}) {
			croak "A valid patron and resource id must be submitted in the patron parameter in order to perform this action. One of these parameters was not passed.";
		}

		if ($opts{patron} !~ /^\d+$/) {
			croak "A valid patron id must be submitted in the patron parameter in order to perform this action.";
		}

		if ($opts{resource} !~ /^\d+$/) {
			croak "A valid resource id must be submitted in the patron parameter in order to perform this action.";
		}

		my @usage_count_array = $dbh->selectrow_array('SELECT usage_count FROM patron_resource WHERE patron_id = ? AND resource_id = ?', undef, $opts{patron}, $opts{resource});
		my $usage_count = $usage_count_array[0];

		return $usage_count;

	} elsif ($opts{action} eq 'absolute_usage_count') {

		if ($opts{resource} !~ /^\d+$/) {
			croak "A valid resource id must be submitted in the patron parameter in order to perform this action.";
		}

		my @absolute_count_array = $dbh->selectrow_array('SELECT usage_count FROM patron_resource WHERE patron_id = ? AND resource_id = ?', undef, 0, $opts{resource});
		my $absolute_count = $absolute_count_array[0];

		return $absolute_count;

	} elsif ($opts{action} eq 'patron_usage_count')  {

		if ($opts{resource} !~ /^\d+$/) {
			croak "A valid resource id must be submitted in the patron parameter in order to perform this action.";
		}

		my $patron_usage_array = $dbh->selectcol_arrayref('SELECT patron_id FROM patron_resource WHERE resource_id = ? AND patron_id >= 1', undef, $opts{resource});

		my $patron_usage_count = scalar(@{$patron_usage_array});

		return $patron_usage_count;

	} elsif ($opts{action} eq 'patron_resource_count') {

		if ($opts{patron} !~ /^\d+$/) {
			croak "A valid patron id must be submitted in the patron parameter in order to perform this action.";
		}

		my $patron_resource_array = $dbh->selectcol_arrayref('SELECT resource_id FROM patron_resource WHERE patron_id = ? AND usage_count > 0', undef, $opts{patron});

		my $patron_resource_count = scalar(@{$patron_resource_array});

		return $patron_resource_count;

	}

}


sub delete {

	my $self = shift;

	if ($self->patron_id()) {

		my $dbh = MyLibrary::DB->dbh();
		my $rv = $dbh->do('DELETE FROM patrons WHERE patron_id = ?', undef, $self->{patron_id});
		if ($rv != 1) {croak ("Deleted $rv records. Please check the patron_resource table for errors.");}
		# delete any resource associations
		$dbh->do('DELETE FROM patron_resource WHERE patron_id = ?', undef, $self->patron_id()); 
		# delete any term associations
		$dbh->do('DELETE FROM patron_term WHERE patron_id = ?', undef, $self->patron_id());
		return 1;

	}

	return 0;

}


sub get_patrons {

	my $class = shift;
	my @rv;

	my $dbh = MyLibrary::DB->dbh();
	my $patron_ids = $dbh->selectcol_arrayref('SELECT patron_id FROM patrons');
	
	foreach my $patron_id (@$patron_ids) {
	
		push (@rv, MyLibrary::Patron->new(id => $patron_id));
	
	}
	
	return @rv;
	
}

sub _encrypt_password {

	my $self = shift;
	my $password = shift;
	if (defined $password) {
		my $salt = substr($password, 0, 2);
		my $crypted_pw = crypt($password, $salt);
		return $crypted_pw;
	} else {
		croak "Password not indicated for encryption.\n";
	}

}


1;
