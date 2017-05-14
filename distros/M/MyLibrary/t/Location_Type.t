use Test::More tests => 7;
use strict;

# use the module
use_ok('MyLibrary::Resource::Location::Type');

# create a resource location type
my $location_type = MyLibrary::Resource::Location::Type->new();
isa_ok($location_type, 'MyLibrary::Resource::Location::Type');

# set the object's name
$location_type->name('URL Hyperlink Web');
is ($location_type->name(), 'URL Hyperlink Web', 'name() set');

# set the object's description
$location_type->description('This is a Internet link which classifies a location as being accessible via a web browser.');
is ($location_type->description(), 'This is a Internet link which classifies a location as being accessible via a web browser.', 'description() set');

# save the location type
$location_type->commit();
my $location_type_id = $location_type->location_type_id();
like ($location_type_id, qr/^\d+$/, 'get location_type_id()');

# return at least one location type
cmp_ok (scalar(MyLibrary::Resource::Location::Type->all_types()), '>=', 1, 'get all_types()');

# delete location type
is($location_type->delete(), '1', 'delete()');
