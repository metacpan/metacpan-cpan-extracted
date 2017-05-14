package MyLibrary::Resource::Location;

use MyLibrary::DB;
use MyLibrary::Resource::Location::Type;
use Carp qw(croak);
use strict;

=head1 NAME

MyLibrary::Resource::Location - A class for representing MyLibrary resource locations

=head1 SYNOPSIS

	# module may be called explicitly
	use MyLibrary::Resource::Location;

	# create a new resource location object
	my $resource_location = MyLibrary::Resource::Location->new();

	# set attributes of object
	$resource_location->location('http://mysite.com');
	$resource_location->location_note('This is mysite');
	$resource_location->resource_location_type(25);
	$resource_location->resource_id(45);

	# remove value for location note
	$resource_location->delete_location_note();

	# save to database
	$resource_location->commit();

	# retrieve resource location id
	my $resource_location_id = $resource_location->id();

	# retrieve object by location id
	my $resource_location = MyLibrary::Resource::Location->new(id => $resource_location_id);

	# retrieve object attributes
	my $resource_location_location = $resource_location->location();
	my $resource_location_note = $resource_location->location_note();
	my $resource_location_type_id = $resource_location->resource_location_type();

	# retrieve all location objects associated with a resource
	my @resource_location_objects = MyLibrary::Resource::Location->get_locations(id => $resource_id);

	# retrieve list (array) of all resource location ids
	my @resource_location_ids = MyLibrary::Resource::Location->id_list();

	# delete a specific resource location
	$resource_location->delete();

	# create a new resource location type
	MyLibrary::Resource::Location->location_type(action => 'set', name => 'Call Number', description => 'Call number location using the Library of Congress System');

	# retrieve a location type name based on location type id
	my $location_type_name = MyLibrary::Resource::Location->location_type(action => 'get_name', id => 25);

	# retrieve a location type id based on a location type name
	my $location_type_id = MyLibrary::Resource::Location->location_type(action => 'get_id', name => 'Call Number');

	# retrieve a location type description based on a locatin type id
	my $location_type_desc = MyLibrary::Resource::Location->location_type(action => 'get_desc', id => 25);

	# retrieve an array of all resource location type ids
	my @resource_location_types = MyLibrary::Resource::Location->location_type(action => 'get_all');

	# delete a location type based on location type id
	MyLibrary::Resource::Location->location_type(action => 'delete', id => 25);

=head1 DESCRIPTION

This is a sub-class of the Resource class which is used to represent individual resource locations and allow manipulation of resource location data. Several locations can be related to a particular resource. Each location has several attributes which describe the location and give the location information itself. Each location has a location type, and class methods are provided in this package which allow manipulation of the resource location types as well.

=head1 METHODS

=head2 new()

This constructor method is used to create a resource location object. The object can then be manipulated using the various accessor methods supplied with this module.

	# create a new resource location object
	my $resource_location = MyLibrary::Resource::Location->new();

This method can also be called using an id parameter which will then return an object using the persisten data store. If the called location does not exist, this method will return 'undef'.

	# create an object from persistent data using the location id
	my $resource_location = MyLibrary::Resource::Location->new(id => $loc_id);

The method can also retrieve and build an object or objects using the location text for the location. Please note that this will return 'undef' if an exact match is not found. The type returned is based on context. If the method is called in scalar context, a single value representing either 'undef' for no results or the number of locations matching the criteria will be returned. If called in list context, the result will be an array of location objects matching the criteria.

	# determine the number of objects matching the location parameter (scalar context)
	my $resource_location = MyLibrary::Resource::Location->new(location => 'http://mysite.com');

	# retrieve an array of location objects based on location string criteria (list context)
	my @resource_locations = MyLibrary::Resource::Location->new(location => 'http://mysite.com');

=cut

sub new {

	my ($class, %opts) = @_;
	my $self           = {};

	if ($opts{id}) {

		my $dbh = MyLibrary::DB->dbh();

		my $rv = $dbh->selectrow_hashref('SELECT * FROM resource_location WHERE resource_location_id = ?', undef, $opts{id});	

		if (ref($rv) eq "HASH") {
			$self = $rv;
		} else {
			return;
		}

	} elsif ($opts{location}) {

		my $dbh = MyLibrary::DB->dbh();
		my $rv = $dbh->selectall_hashref('SELECT * FROM resource_location WHERE resource_location = ?', 'resource_location_id', undef, $opts{location});
		if (ref($rv) eq "HASH") {
			my $num_records = keys %{$rv};
			if (wantarray) {
				my @return_records;
				foreach my $resource_id (keys %{$rv}) {
					my $resource = $rv->{$resource_id};
					push(@return_records, bless($resource, $class));
				}
				return @return_records;
			} else {
				return $num_records;
			}
		} else {
			return;
		}
		
	}

	# return the object
	return bless $self, $class;

}

=head2 commit()

This method will save resource location object data to the database.

	# commit the resource location
	$resource_location->commit();

=cut

sub commit {

	my $self = shift;

	my $dbh = MyLibrary::DB->dbh();
	
	if ($self->id()) {
		my $return = $dbh->do('UPDATE resource_location SET resource_location = ?, resource_location_note = ?, resource_location_type = ?, resource_id = ? WHERE resource_location_id = ?', undef, $self->location(),  $self->location_note(), $self->resource_location_type(), $self->resource_id(), $self->id());
		if ($return > 1 || ! $return) { croak "Resource location update in commit() failed. $return records were updated." }
	} else {

		my $id = MyLibrary::DB->nextID();

		my $return = $dbh->do('INSERT INTO resource_location (resource_location_id, resource_location, resource_location_note, resource_location_type, resource_id) VALUES (?,?,?,?,?)', undef, $id, $self->location(),  $self->location_note(), $self->resource_location_type(), $self->resource_id());
		if ($return != 1) { croak 'Resource location commit() failed.'; }
		$self->{resource_location_id} = $id;

	}

	return 1;

}

=head2 id()

This method can be used simply to retrieve the id (unique key) for the current object. It cannot be used to set the id, which is determined by the database.

	# retrieve the resource location id
	my $resource_loc_id = $resource_location->id();

=cut

sub id {

	my $self = shift;
	if ($self->{resource_location_id}) {
		return $self->{resource_location_id};
	} else {
		return;
	}

}

=head2 location()

This attribute method can be used to either retrieve or set the resource location attribute. The value entered should match the type of location chosen for the object.

	# get location name
	my $location_name = $resource_location->location();

	# set the location 
	$resource_location->location('http://mysite.com');

=cut

sub location {

	my ($self, $location) = @_;
	if ($location) { 
		$self->{resource_location} = $location;
	} else { 
		return $self->{resource_location};
	}

}

=head2 location_note()

This attribute method is used to either get or set the note for the resource.

	# get the resource location note
	my $resource_loc_note = $resource_location->location_note();

	# set the resource location note
	$resource_location->location_note('This is the note for my resource');

=cut

sub location_note {

	my ($self, $note) = @_;
	if ($note) {
		$self->{resource_location_note} = $note;
	} else {
		return $self->{resource_location_note};
	}

}

sub delete_location_note {

	my $self = shift;
	$self->{resource_location_note} = undef;

}

=head2 resource_location_type()

This method should be used to get or set the resource type id for this location. The input must be an integer that matches a location type id from the database.

	# get the resource location type id
	my $resource_loc_type_id = $resource_location->resource_location_type();

	# set the resource location type id
	$resource_location->location_type($type_id);

=cut

sub resource_location_type {

	my ($self, $type) = @_;
	if ($type) {
		my $dbh = MyLibrary::DB->dbh();
		my $type_ids = $dbh->selectcol_arrayref('SELECT type_id FROM resource_location_type');
		my $found = 0;
		foreach my $resource_location_type_id (@{$type_ids}) { # does this type exist?
			if ($resource_location_type_id == $type) {
				$found = 1;
			}
		}
		unless (!$found) {
			$self->{resource_location_type} = $type;
			return $self->{resource_location_type};
		} else {
			croak ('Type id used as parameter for location_type() method does not exist.');
		}
	} else {
		return $self->{resource_location_type};
	}

}

=head2 resource_id()

This method can be used either to retrieve or set the resource id which is related to this location. The resource which corresponds to this id must already exist in the database or this method will fail when used as a 'set' method. For various reasons, this behavior can also be turned off using the 'strict => 'off'' flag. Keep in mind that turning off relational integrity checks could compromise the data.

	# get the related resource id
	my $resource_id = $resource_location->resource_id();

	# set the related resource id
	$resource_location->resource_id($resource_id);

	# turn relational integrity checking off
	$resource_location->resource_id($resource_id, strict => 'off');

=cut

sub resource_id {

	my $self = shift;
	my $resource_id = shift;
	my %opts = @_;
	if ($resource_id && $resource_id !~ /^\d+$/) {
		croak ('Resource id input for resource_id method must be an integer.');
	}
	if ($resource_id) {
		unless ($opts{strict} and $opts{strict} eq 'off') { 
			my $dbh = MyLibrary::DB->dbh();
			my $resource_ids = $dbh->selectcol_arrayref('SELECT resource_id FROM resources');
			my $found = 0;
			foreach my $database_resource_id (@{$resource_ids}) { # does this resource exist?
				if ($database_resource_id == $resource_id) {
					$found = 1;
				}
			}
			unless (!$found) {
				$self->{resource_id} = $resource_id;
				return $self->{resource_id};
			} else {
				croak ('Resource id used as parameter for resource_id() method does not exist.');
			}
		} else {
			$self->{resource_id} = $resource_id;
			return $self->{resource_id};
		}
	} else {
		return $self->{resource_id};
	}
}

=head2 get_locations()

This class method serves, primarily, the requirements of the parent resource object (defined in Resource.pm). This method will retrieve all of the resource objects associated with a particular resource. The accessor methods in this package are then used to access the attributes of the location objects. This method returns an array of object references.

	# retrieve the complete set of resource location objects
	my @resource_locations = MyLibrary::Resource::Location->get_locations();

	# via a specific resource id
	my @resource_locations = MyLibrary::Resource::Location->get_locations(id => 27);

	# the method called from Resource.pm is similar
	my @resource_locations = $resource->get_locations();

The attributes of the objects can be manipulated using either the local package methods or methods which are supplied with the resource module itself. In the latter instance, only locations associated with that particular resource can be accessed.

	# access attributes using local (Resource::Location.pm) methods
	my $resource_location = $resource_location->location();
	my $resource_location_note = $resource_location->note();

	# manipulate the attributes (Resource.pm methods)
	my $location_name = $resource->location_name();
	my $location_note = $resource->location_note();

=cut

sub get_locations {

	my $self = shift;
	my %opts = @_;

	my $resource_id = $opts{'id'};
	my @location_objs;
	my $dbh = MyLibrary::DB->dbh();
	if ($resource_id) {
		my $locations_ids = $dbh->selectcol_arrayref('SELECT resource_location_id FROM resource_location WHERE resource_id = ? ORDER BY resource_location_id', undef, $resource_id);
		foreach my $location_id (@{$locations_ids}) {
			push(@location_objs, MyLibrary::Resource::Location->new(id => $location_id));
		}
	} else {
		my $locations_ids = $dbh->selectcol_arrayref('SELECT resource_location_id FROM resource_location ORDER BY resource_location_id');
		foreach my $location_id (@{$locations_ids}) {
			push(@location_objs, MyLibrary::Resource::Location->new(id => $location_id));
		}
	}

	return @location_objs;
}

=head2 id_list()

If only the list of resource location ids is required in order to avoid the overhead of dealing with fully fleged objects, that array can be retrieved using this class method. As implied, this method will simply return a list of location ids which can then be subsequently used to process through the list of location ids.

	# get full list of location ids
	my @resource_loc_ids = MyLibrary::Resource::Location->id_list();

=cut

sub id_list {

	my $self = shift;
	my @location_ids;
	my $dbh = MyLibrary::DB->dbh();
	my $locations_ids = $dbh->selectcol_arrayref('SELECT resource_location_id FROM resource_location');
	return @{$locations_ids};

}

=head2 delete()

This method can be used to delete a specific resource location.

	# delete a resource location
	$resource_location->delete();

=cut

sub delete {

	my $self = shift;
	my $dbh = MyLibrary::DB->dbh();
	my $rv = $dbh->do('DELETE FROM resource_location WHERE resource_location_id = ?', undef, $self->id());
	if ($rv != 1) {
		croak ('Deletion of resource location failed in delete() method.');
	} else {
		return $rv;
	}
}
	
=head2 location_type()

Location types for resource locations may be retrieved, set or deleted with this method. The required parameter is the type name. A description may also optionally be supplied. This is a class method.

Location types can be created by supplying the required parameter and a flag must be set to indicate that this location type should be created. Location types that have identical names with types that already exist in the database will not be created. The key id for each new location type is generated by incrementing the highest key integer in the set of location type keys.

A list of all of the current location type ids can be obtained by passing the action parameter 'get_all'. This will return an array of location type ids.

NOTE: The MyLibrary::Resource::Location::Type class also allows for direct manipulation of location types. That class was developed after these methods, and thus, these methods are now deprecated. Use these class methods at your own risk.

	# create a resource location type
	MyLibrary::Resource::Location->location_type(action => 'set', name => 'Call Number', description => 'Call number location using the Library of Congress System');

	# retrieve a location type name based on location type id
	my $location_type_name = MyLibrary::Resource::Location->location_type(action => 'get_name', id => 25);

	# retrieve a location type id based on a location type name
	my $location_type_id = MyLibrary::Resource::Location->location_type(action => 'get_id', name => 'Call Number');

	# retrieve a location type description based on a locatin type id
	my $location_type_desc = MyLibrary::Resource::Location->location_type(action => 'get_desc', id => 25);

	# retrieve an array of all location type ids
	my @resource_location_types = MyLibrary::Resource::Location->location_type(action => 'get_all');

	# delete a location type based on location type id
	MyLibrary::Resource::Location->location_type(action => 'delete', id => 25);

=cut

sub location_type {

    my $class = shift;
    my %opts = @_;
    my $action_type;

    if (!$opts{'action'}) {

        croak ('location_type() method requires an action parameter');

    } elsif ($opts{'action'}) {

        $action_type = $opts{'action'};

    }

    if ($action_type eq 'set') {

        my $name;
        my $description;

        if (defined($opts{'name'})) {

            $name =  $opts{'name'};

        } else {

            croak ('Set action called without required name parameter in location_type() method');

        }

        if (defined($opts{'description'})) {

            $description = $opts{'description'};
        } else {

            $description = 'No description supplied.';
        }

		my $found_type = MyLibrary::Resource::Location::Type->new(name => $name);

        unless ($found_type) {

			# create a new type
			my $new_type = MyLibrary::Resource::Location::Type->new();
			$new_type->name($name);
			$new_type->description($description);
			$new_type->commit();
			my $id = $new_type->location_type_id();
            return $id;

        } else {

			croak ('Duplicate resource location type found for location_type() method.');

		}

    } elsif ($action_type eq 'get_name') {

        my $id;

        if (defined($opts{'id'})) {

            $id = $opts{'id'};

        } else {

            croak ('get_name action called for location_type() method without required id parameter');
        }

		my $location_type = MyLibrary::Resource::Location::Type->new(id => $id);

		if ($location_type && $location_type->isa('MyLibrary::Resource::Location::Type')) {

			my $name = $location_type->name();
            return $name;

        } else {

            return;

        }

    } elsif ($action_type eq 'get_desc') {

        my $id;
        my $type_name;

        if (defined($opts{'id'})) {

            $id = $opts{'id'};

        } elsif (defined($opts{'name'})) {

            $type_name = $opts{'name'};

        } else {

            croak ('A required parameter was not submitted to the location_type() method using the get_desc parameter');

        }

        if ($id) {

			my $location_type = MyLibrary::Resource::Location::Type->new(id => $id);

			if ($location_type && $location_type->isa('MyLibrary::Resource::Location::Type')) {

				my $description = $location_type->description();
                return $description;

            } else {

                return;

            }

        } elsif ($type_name) {

			my $location_type = MyLibrary::Resource::Location::Type->new(name => $type_name);

			if ($location_type && $location_type->isa('MyLibrary::Resource::Location::Type')) {

				my $description = $location_type->description();
                return $description;

            } else {

                return;

            }
        }

    } elsif ($action_type eq 'get_id') {

        my $name;

        if (defined($opts{'name'})) {

            $name = $opts{'name'};

        } else {

            croak ('get_id action called for location_type() method without required name parameter');
        }

		my $location_type = MyLibrary::Resource::Location::Type->new(name => $name);

		if ($location_type && $location_type->isa('MyLibrary::Resource::Location::Type')) {

			my $id = $location_type->location_type_id();
            return $id;

        } else {

            return;

        }

    } elsif ($action_type eq 'get_all') {

		return(MyLibrary::Resource::Location::Type->all_types());

    } elsif ($action_type eq 'delete') {

        my $id;

        if (defined($opts{'id'})) {

            $id = $opts{'id'};

        } else {

            croak ('delete action called for location_type() method without required id parameter');

        }

		my $rv;

		my $location_type = MyLibrary::Resource::Location::Type->new(id => $id);

		unless ($location_type && $location_type->isa('MyLibrary::Resource::Location::Type')) {

            croak ('delete action called for location_type() failed');

        } else {

			$rv = $location_type->delete();

		}

        return $rv;
    }
}

=head1 SEE ALSO

For more information, see the MyLibrary home page: http://dewey.library.nd.edu/mylibrary/.

=head1 AUTHORS

Eric Lease Morgan <emorgan@nd.edu>
Robert Fox <rfox2@nd.edu>

=cut 

1;
