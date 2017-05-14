use Test::More tests => 23;
use strict;

# use the module
use_ok('MyLibrary::Resource::Location');

# create two resource location types
my $loc_type_id = MyLibrary::Resource::Location->location_type(action => 'set', name => 'URL1', description => 'This is a primary URL for a given resource.');
my $loc_type_id2 = MyLibrary::Resource::Location->location_type(action => 'set', name => 'URL2', description => 'This is a secondary URL for a given resource.');
like ($loc_type_id, qr/^\d+$/, 'location_type() set');
like ($loc_type_id2, qr/^\d+$/, 'location_type() set');

# get that resource location type name
my $resource_location_type_id = MyLibrary::Resource::Location->location_type(action => 'get_id', name => 'URL1');
my $resource_location_type_name = MyLibrary::Resource::Location->location_type(action => 'get_name', id => $resource_location_type_id);
is ($resource_location_type_name, 'URL1', 'location_type() get_name');
my $resource_location_type_desc = MyLibrary::Resource::Location->location_type(action => 'get_desc', id => $resource_location_type_id);
is ($resource_location_type_desc, 'This is a primary URL for a given resource.', 'location_type() get_desc');
# get all location type ids
# like (scalar(MyLibrary::Resource::Location->location_type(action => 'get_all')), qr/^\d+$/, 'location_type() get_all');
cmp_ok (scalar(MyLibrary::Resource::Location->location_type(action => 'get_all')), '>=', 2, 'location_type() get_all');

# create a resource location object
my $resource_location = MyLibrary::Resource::Location->new();
isa_ok($resource_location, 'MyLibrary::Resource::Location');

# set the object's resource location
$resource_location->location('http://mysite.com');
is ($resource_location->location(), 'http://mysite.com', 'location() set');

# set the object's note
$resource_location->location_note('This is my site.');
is ($resource_location->location_note(), 'This is my site.', 'location_note() set');

# set the object's type
$resource_location->resource_location_type($loc_type_id);
like($loc_type_id, qr/^\d+$/, 'resource_location_type() set');

# set the object's resource id
use MyLibrary::Resource;
my $resource = MyLibrary::Resource->new();
$resource->name('My Resource');
$resource->commit();
my $resource_id = $resource->id();
$resource_location->resource_id($resource_id);
is($resource_location->resource_id(), $resource_id, 'resource_id() set'); 

# save to the database
is ($resource_location->commit(), '1', 'commit()');

# create a second location for the same resource
my $resource_location2 = MyLibrary::Resource::Location->new();
$resource_location2->location('http://mysite2.com');
$resource_location2->location_note('This is my other site.');
$resource_location2->resource_location_type($loc_type_id);
$resource_location2->resource_id($resource_id);
$resource_location2->commit();
my $test_location_id = $resource_location2->id();

# get resource locations
my @resource_locations = MyLibrary::Resource::Location->get_locations();
cmp_ok(scalar(@resource_locations), '>=', 2, 'get_locations()');

@resource_locations = MyLibrary::Resource::Location->get_locations(id => $resource_id);
is(scalar(@resource_locations), 2, 'get_locations() by resource id');

# get object attributes
foreach my $resource_location (@resource_locations) {
	if ($resource_location->id() == $test_location_id) {
		is($resource_location->location(), 'http://mysite2.com', 'location() get');
		is(MyLibrary::Resource::Location->location_type(action => 'get_name', id => ($resource_location->resource_location_type())), 'URL1', 'location_type() get');
		is($resource_location->location_note(), 'This is my other site.', 'location_note() get');
		is($resource_location->resource_id(),  $resource_id, 'resource_id() get');
	}
} 

# get simple id list (array)
my @location_ids = MyLibrary::Resource::Location->id_list();
cmp_ok(scalar(@location_ids), '>=', 2, 'id_list()');

# delete resource locations
is ($resource_location->delete(), 1, 'delete() resource location');
is ($resource_location2->delete(), 1, 'delete() resource location');

# delete temporary resource
$resource->delete();


# delete resource location type
is (MyLibrary::Resource::Location->location_type(action => 'delete', id => $resource_location_type_id), 1, 'location_type() delete');
is (MyLibrary::Resource::Location->location_type(action => 'delete', id => $loc_type_id2), 1, 'location_type() delete ');
