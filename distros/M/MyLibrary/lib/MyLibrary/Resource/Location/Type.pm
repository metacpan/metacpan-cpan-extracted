package MyLibrary::Resource::Location::Type;

use MyLibrary::DB;
use Carp qw(croak);
use strict;

=head1 NAME

MyLibrary::Resource::Location::Type

=head1 SYNOPSIS


	# require the necessary module
	use MyLibrary::Resource::Location::Type;

	# create a new Location Type object
	my $location_type = MyLibrary::Resource::Location::Type->new();

	# set the attributes of a Location Type object
	$location_type->name();
	$location_type->description();

	# commit Location Type
	$location_type->commit();

	# output the Location Type id
	my $location_type_id = $location_type->location_type_id();

	# delete a Location Type from the database
	$location_type->delete();

	# return a list of all type ids for processing
	my @location_type_ids = MyLibrary::Resource::Location::Type->all_types();

=head1 DESCRIPTION

This is a sub-class of the Location class which is used to represent individual resource location types and allow manipulation of resource location type data. Each location will be assigned one location type. Multiple location types can exist, each representing a method by which a resource can be accessed. Certain resources will be accessed only via physical methods, while others will be purely digital. Each type should have a description assigned which clearly states the mode of access for that type.

=head1 METHODS

=head2 new()

This constructor method is used to create a resource location type object. The object can then be manipulated using the various accessor methods supplied with this module.

	# create a new resource location type object
	my $resource_location_type = MyLibrary::Resource::Location::Type->new();

This method can also be called using an id parameter which will then return an object using the persistent data store. If the called location does not exist, this method will return 'undef'.

	# create an object from persistent data using the location type id
	my $resource_location_type = MyLibrary::Resource::Location::Type->new(id => $loc_id);

This method can also be called using the 'name' parameter, so that an object can be created based on the name of the location type. Each location type name must be unique, so only one type will be retrieved using the method in this fashion.

	# create an object from persistent data using the location type name
	my $resource_location_type = MyLibrary::Resource::Location::Type->new(name => $loc_name);

=cut

sub new {

	my ($class, %opts) = @_;
	my $self           = {};

	if ($opts{id}) {

		my $dbh = MyLibrary::DB->dbh();
		my $rv = $dbh->selectrow_hashref('SELECT * FROM resource_location_type WHERE type_id = ?', undef, $opts{id});

		if (ref($rv) eq "HASH") {
			$self = $rv;
		} else {
			return;
		}

	} elsif ($opts{name}) {

		my $dbh = MyLibrary::DB->dbh();
		my $rv = $dbh->selectrow_hashref('SELECT * FROM resource_location_type WHERE type_name = ?', undef, $opts{name});

		if (ref($rv) eq "HASH") {
			$self = $rv;
		} else {
			return;
		}
	}

	# return the object
	return bless $self, $class;

}


=head2 name()

This attribute method should be used to either set or retrieve the name for this location type. This name will appear in any context where location type labeling is required.

	# get location type name
	my $location_type_name = $location_type->name();

	# set the location type name
	$location_type->name('URL WEB SITE');

=cut

sub name {

	my ($self, $name) = @_;
	if ($name) {
		$self->{type_name} = $name;
	} else {
		return $self->{type_name};
	}
}

=head2 description()

The description should indicate the mode of access for a location type. This will assist in the usage of a particular type.

	# retrieve the current location type
	my $location_type_description = $location_type->description();

	# set the location type description
	$location_type->description('This location type applies to any resource which is web accessible.');

=cut

sub description {

	my ($self, $description) = @_;
	if ($description) {
		$self->{type_description} = $description;
	} else {
		return $self->{type_description};
	}		

}

=head2 location_type_id()

This method can only be used to retrieve the location type id of the current location type. It cannot be used to set the location type id, as this is set internally.

	# get the current location type id
	my $location_type_id = location_type_id();

=cut

sub location_type_id {

	my $self = shift;
	if ($self->{type_id}) {
		return $self->{type_id};
	} else {
		return;
	}

}

=head2 commit()

This method is used to save a location type to the database.

	# commit the location type
	$location_type->commit();

=cut

sub commit {

	my $self = shift;

	my $dbh = MyLibrary::DB->dbh();

	if ($self->location_type_id()) {

		my $return = $dbh->do('UPDATE resource_location_type SET type_name = ?, type_description = ? WHERE type_id = ?', undef, $self->name(), $self->description(), $self->location_type_id());
		if ($return > 1 || $return eq undef) { croak "Location type update in commit() failed. $return records were updated." }

	} else {
		
		my $id = MyLibrary::DB->nextID();

		my $return = $dbh->do('INSERT INTO resource_location_type (type_id, type_name, type_description) VALUES (?, ?, ?)', undef, $id, $self->name(), $self->description());
		if ($return != 1) { croak 'Location type commit() failed.'; }
		$self->{type_id} = $id;
	}

	return 1;

}

=head2 delete()

Use this method to remove a location type from the database

	# remove a location type from the database
	$location_type->delete();

=cut

sub delete {

	my $self = shift;
	my $dbh = MyLibrary::DB->dbh();
	my $rv = $dbh->do('DELETE FROM resource_location_type WHERE type_id = ?', undef, $self->location_type_id());
	my $return_code;
	if ($rv != 1) {
		croak ('Deletion of resource location failed in delete() method.');
	} else {
		$return_code = "$rv";
	}

	# delete any dangling locations using this location type
	my $location_ids = $dbh->selectcol_arrayref('SELECT resource_location_id FROM resource_location WHERE resource_location_type = ?', undef, $self->location_type_id());
	if (scalar(@{$location_ids}) >= 1) {
		foreach my $location_id (@$location_ids) {
			use MyLibrary::Resource::Location;
			my $delete_location = MyLibrary::Resource::Location->new(id => $location_id);
			$delete_location->delete();	
		}
	}

	return $return_code;

}

=head2 all_types()

This is a class method which will return upon invocation the full list of location type ids. If no location types exist in the databse, the method will return undef.

	# return a list of all location type ids
	my @location_type_ids = MyLibrary::Resource::Location::Type->all_types();

=cut

sub all_types {

	my $class = shift;

	unless ($class eq 'MyLibrary::Resource::Location::Type') {

		croak ("This method must be called as a class method. $class was the invocant.");

	}
	
	my $dbh = MyLibrary::DB->dbh();
	my $type_ids = $dbh->selectcol_arrayref('SELECT type_id FROM resource_location_type');

	if (scalar(@{$type_ids}) >= 1) {

		return @{$type_ids};

	} else {

		return;

	}

}

=head1 SEE ALSO

For more information, see the MyLibrary home page: http://dewey.library.nd.edu/mylibrary/.

=head1 AUTHOR

Robert Fox <rfox2@nd.edu>

=cut

return 1;
