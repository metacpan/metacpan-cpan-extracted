use Test::More tests => 100;
use strict;

# use the module
use_ok('MyLibrary::Resource');

# create a resource object
my $resource = MyLibrary::Resource->new();
isa_ok($resource, 'MyLibrary::Resource');

# set the resources's name
$resource->name('Alex Catalogue');
is($resource->name(), 'Alex Catalogue', 'set name()');

# set the the resources's note
$resource->note('The Catalogue is a collection of clasic texts.');
is($resource->note(), 'The Catalogue is a collection of clasic texts.', 'set note()');

# set the the resources's lcd
$resource->lcd('1');
is($resource->lcd(), '1', 'set lcd()');

# set the the resources's date stamp
$resource->date('2003-09-09');
is($resource->date(), '2003-09-09', 'set date()');

# set the the resources's fkey
$resource->fkey('123456');
is($resource->fkey(), '123456', 'set fkey()');

# set the the resources's quick search prefix
$resource->qsearch_prefix('http://example.com/search?query=');
is($resource->qsearch_prefix(), 'http://example.com/search?query=', 'set qsearch_prefix()');

# set the the resources's quick search suffix
$resource->qsearch_suffix('&theend');
is($resource->qsearch_suffix(), '&theend', 'set qsearch_suffix()');

# set the proxy
$resource->proxied(0);
is($resource->proxied(), 0, 'set proxied()');

# set creator
$resource->creator('Eric Lease Morgan');
is ($resource->creator, 'Eric Lease Morgan', 'set creator()');

# set publisher
$resource->publisher('Infomotions, Inc.');
is ($resource->publisher, 'Infomotions, Inc.', 'set publisher()');

# set contributor
$resource->contributor('The Internet Community');
is ($resource->contributor, 'The Internet Community', 'set contributor()');

# set coverage
$resource->coverage('600 BC - 1800\'s');
is ($resource->coverage, '600 BC - 1800\'s', 'set coverage()');

# set rights
$resource->rights('This stuff is in the Public Domain');
is ($resource->rights, 'This stuff is in the Public Domain', 'set rights()');

# set language
$resource->language('eng');
is ($resource->language, 'eng', 'set language()');

# set source
$resource->source('From all over the Internet');
is ($resource->source, 'From all over the Internet', 'set source()');

# set relation
$resource->relation('http://www.promo.net/pg/');
is ($resource->relation, 'http://www.promo.net/pg/', 'set relation()');

# set format
$resource->format('Computer File');
is ($resource->format, 'Computer File', 'set format()');

# set type
$resource->type('Organic Object');
is ($resource->type, 'Organic Object', 'set type()');

# set subject
$resource->subject('Japanese; Mankind;');
is ($resource->subject, 'Japanese; Mankind;', 'set subject()');

# set create date
$resource->create_date('2005-08-01');
is ($resource->create_date, '2005-08-01', 'set create_date()');

# set access note
$resource->access_note('Available on the World Wide Web.');
is ($resource->access_note, 'Available on the World Wide Web.', 'set access_note()');

# set coverage info
$resource->coverage_info('Aug. 1996 - Feb. 2002');
is ($resource->coverage_info, 'Aug. 1996 - Feb. 2002', 'set coverage_info()');

# set full text flag
$resource->full_text(1);
is ($resource->full_text, 1, 'set full_text()');

# set reference linking flag
$resource->reference_linking(0);
is ($resource->reference_linking, 0, 'set reference_linking()');

# save a new record
is($resource->commit(), '1', 'commit()');

# get the id of the record just created
my $id = $resource->id();
like ($id, qr/^\d+$/, 'get id()');

# get record based on an id
my $object = MyLibrary::Resource->new(id => $id);

# check each field
is ($object->name(), 'Alex Catalogue',                                 'get name()');
is ($object->note(), 'The Catalogue is a collection of clasic texts.', 'get note()');
is ($object->lcd(), '1',                                               'get lcd()');
is ($object->date(), '2003-09-09',                                     'get date()');
is ($object->fkey(), '123456',                                         'get fkey()');
is ($object->qsearch_prefix(), 'http://example.com/search?query=',     'get qsearch_prefix()');
is ($object->qsearch_suffix(), '&theend',                              'get qsearch_suffix()');
is ($object->proxied(), '0',                                           'get proxied()');
is ($object->creator(), 'Eric Lease Morgan',                           'get creator()');
is ($object->publisher(), 'Infomotions, Inc.',                         'get publisher()');
is ($object->contributor(), 'The Internet Community',                  'get contributor()');
is ($object->coverage(), '600 BC - 1800\'s',                           'get coverage()');
is ($object->rights(), 'This stuff is in the Public Domain',           'get rights()');
is ($object->language(), 'eng',                                        'get language()');
is ($object->source(), 'From all over the Internet',                   'get source()');
is ($object->relation(), 'http://www.promo.net/pg/',                   'get relation()');
is ($object->format(), 'Computer File',                                'get format()');
is ($object->type(), 'Organic Object',                                 'get type()');
is ($object->subject(), 'Japanese; Mankind;',                          'get subject()');
is ($object->create_date(), '2005-08-01',                              'get create_date()');
is ($object->access_note(), 'Available on the World Wide Web.',        'get access_note()');
is ($object->coverage_info(), 'Aug. 1996 - Feb. 2002',                 'get coverage_info()');
is ($object->full_text(), '1',                                         'get full_text()');
is ($object->reference_linking(), '0',                                 'get reference_linking()');

# generate a qsearch redirect
is (MyLibrary::Resource->qsearch_redirect(resource_id => $object->id(), qsearch_arg => 'search_arg'), 'http://example.com/search?query=search_arg&theend', 'qsearch_redirect()');

# get record(s) based on a name
my @objects = MyLibrary::Resource->new(name => 'Alex Catalogue');

# is our object in the mix?
cmp_ok (scalar(@objects), '>=', 1, 'new(name => xyz)');
# find last resource object
foreach my $res_object (@objects) {
	if ($res_object->id() == $id) {
		$object = $res_object;
	}
}
# check certain fields
is ($object->note(), 'The Catalogue is a collection of clasic texts.', 'get note()');
is ($object->rights, 'This stuff is in the Public Domain',             'get rights()');
is ($object->full_text, '1',                                           'get full_text()');

# get record based on the fkey
$object = MyLibrary::Resource->new(fkey => '123456');

# check certain fields
is ($object->id(), $id, 'get id()');
is ($object->note(), 'The Catalogue is a collection of clasic texts.', 'get note()');
is ($object->relation, 'http://www.promo.net/pg/',                     'get relation()');
is ($object->reference_linking, '0',                                   'get reference_linking()');

# update a resources record
$object->name('xyzzy');
$object->note('These items are classic works in the public domain.');
$object->commit();

# get the newly updated record
my $thingee = MyLibrary::Resource->new(id => $id);
is ($thingee->name(), 'xyzzy', 'commit() update name');
is ($thingee->note(), 'These items are classic works in the public domain.', 'commit() update note');

# add a location to a resource
use MyLibrary::Resource::Location;
MyLibrary::Resource::Location->location_type(action => 'set', name => 'URL1');
my $location_type_id = MyLibrary::Resource::Location->location_type(action => 'get_id', name => 'URL1');
is($thingee->add_location(location => 'http://mysite.com', location_type => $location_type_id), 1, 'add_location()');
is($thingee->add_location(location => 'http://mysite2.com', location_type => $location_type_id), 1, 'add_location()');
is($thingee->add_location(location => 'http://mysite3.com', location_type => $location_type_id), 1, 'add_location()');

# get a specific location
my $location = $thingee->get_location(resource_location => 'http://mysite2.com');
cmp_ok($location->id(),  '>=', 1, 'get_location() via resource_location');
my $location_id = $location->id();
my $location2 = $thingee->get_location(id => $location_id);
is($location2->location(), 'http://mysite2.com', 'get_location() via id');

# retrieve all location objects for this resource
my @resource_locations = $thingee->resource_locations();
cmp_ok (scalar(@resource_locations), '>=', 3, 'resource_locations()');  

# modify a location attribute
my $location3 = $thingee->get_location(resource_location => 'http://mysite3.com');
is($thingee->modify_location($location3, resource_location => 'http://mysite4.com'), 1, 'modify_location()');

# delete one of the locations
is ($thingee->delete_location($location), 1, 'delete_location()');

# relate the resource to several terms
$resource = $thingee;
use_ok('MyLibrary::Term');
my @term_array = ();
my @del_term_array = ();
my $term = MyLibrary::Term->new();
$term->term_name('Test Term 1');
$term->term_note('Test note for first term');
$term->facet_id(999999);
$term->commit();
my $term_id = $term->term_id();
push (@term_array, $term_id);
$term = MyLibrary::Term->new(id => $term_id);
is ($term->term_name(), 'Test Term 1', "term->new() => $term_id");
$term = MyLibrary::Term->new();
$term->term_name('Test Term 2');
$term->term_note('Test note for second term');
$term->facet_id(999999);
$term->commit();
$term_id = $term->term_id();
push (@term_array, $term_id);
push (@del_term_array, $term_id);
$term = MyLibrary::Term->new(id => $term_id);
is ($term->term_name(), 'Test Term 2', "term->new() => $term_id");
$term = MyLibrary::Term->new();
$term->term_name('Test Term 3');
$term->term_note('Test note for third term');
$term->facet_id(999999);
$term->commit();
$term_id = $term->term_id();
my $test_term_id = $term->term_id();
push (@term_array, $term_id);
$term = MyLibrary::Term->new(id => $term_id);
is ($term->term_name(), 'Test Term 3', "term->new() => $term_id");
my @new_terms = $resource->related_terms(new => [@term_array]);
my $term_string;
foreach my $new_term (@new_terms) {
	$term_string .= "$new_term ";
}
chop($term_string);
is (scalar(@new_terms), 3, "related_terms() 3 terms ($term_string) added to object");
$resource->commit();
$id = $resource->id();
$resource = MyLibrary::Resource->new(id => $id);
my @related_terms = $resource->related_terms();
$term_string = "";
foreach my $related_term (sort @related_terms) {
	$term_string .= "$related_term ";
}
chop($term_string);
is ($resource->related_terms(), 3, "related_terms() recursive => 3 resources ($term_string) found");
is ($resource->related_terms(del => [@del_term_array]), 2, "related_terms() delete 1 resource association ($del_term_array[0]) from object");
$term_string = "";
@related_terms = $resource->related_terms();
foreach my $related_term (sort @related_terms) {
		$term_string .= "$related_term ";
}
chop($term_string);
is ($resource->related_terms(), 2, "related_terms() 2 relations ($term_string) remain");
$resource->commit();
$resource = MyLibrary::Resource->new(id => $id);
$term_string = "";
@related_terms = $resource->related_terms();
foreach my $related_term (sort @related_terms) {
	$term_string .= "$related_term ";
}
chop($term_string);
is ($resource->related_terms(), 2, "related_terms() and commit() match 2 relations ($term_string)");

# test for certain relation
is ($resource->test_relation(term_name => 'Test Term 3'), 1, 'test_relation() via term_name');
is ($resource->test_relation(term_id => $test_term_id), 1, 'test_relation() via term_id');

# delete terms
foreach my $term_id (@term_array) {
	my $term = MyLibrary::Term->new(id =>$term_id);
	is ($term->delete(), '1', "term delete() => $term_id");
}

# second resource for name sort test
my $resource_2 = MyLibrary::Resource->new();
$resource_2->name('!AAAAbbbbbcc');
$resource_2->note('Note for !AAAAbbbbbcc');
$resource_2->commit();

# get resources
my @res_array = ();
push (@res_array, $resource_2->id());
my @resources = MyLibrary::Resource->get_resources();
my $flag = 0;
foreach my $r (@resources) { 
	if ($r->name() =~ /xyzzy/) { 
		$flag = 1; 
	}
}
is ($flag, 1, 'get_resources()');
my @selected_resource = MyLibrary::Resource->get_resources(list => [@res_array]);
is ($selected_resource[0]->name(), '!AAAAbbbbbcc', "get_resources(list => [@res_array])");

@resources = MyLibrary::Resource->get_resources(sort => 'name');
$flag = 0;
is ($resources[0]->name(), '!AAAAbbbbbcc', 'get_resources(sort => name)');
@selected_resource = MyLibrary::Resource->get_resources(list => [@res_array], sort => 'name');
is ($selected_resource[0]->name(), '!AAAAbbbbbcc', "get_resources(list => [@res_array], sort => name)");
my @resource_by_name = MyLibrary::Resource->get_resources(field => 'name', value => 'AAAAbbbbbcc', sort => 'name');
cmp_ok (scalar(@resource_by_name), '>=', 1, 'get_resources(field => name)');
my @resource_by_note = MyLibrary::Resource->get_resources(field => 'description', value => 'AAAAbbbbbcc');
cmp_ok (scalar(@resource_by_note), '>=', 1, 'get_resources(field => description)');
my @resources_by_date = MyLibrary::Resource->get_resources(field => 'date_range', value => '2003-09-01_2003-09-10', output => 'id');
cmp_ok (scalar(@resources_by_date), '>=', 1, 'get_resources(field => date_range)');

# get list of resource ids
my @resource_ids = MyLibrary::Resource->get_ids();
cmp_ok(scalar(@resource_ids), '>=', 1, 'get_ids()');

# get lcd list
my @lcd_resources = MyLibrary::Resource->lcd_resources();
foreach my $r (@lcd_resources) {
	if ($r->lcd() =~ /1/) { $flag = 1 }
}
is ($flag, 1, 'lcd_resources()');
MyLibrary::Resource->lcd_resources(del => $resource->id());
$resource = MyLibrary::Resource->new(id => $resource->id());
is ($resource->lcd(), 0, 'lcd_resources() del parameter');
MyLibrary::Resource->lcd_resources(new => $resource->id());
$resource = MyLibrary::Resource->new(id => $resource->id());
is ($resource->lcd(), 1, 'lcd_resources() new parameter');

# get fkey list
my @fkey_objects = MyLibrary::Resource->get_fkey();
my $fkey_resource;
# find the appropriate resource
foreach my $fkey_object (@fkey_objects) {
	if ($fkey_object->id() == $resource->id()) {
		$fkey_resource = $fkey_object;
	}
}	
is ($fkey_resource->fkey(), '123456', 'get_fkey()'); 

# delete a resource record
is ($resource->delete(), '1', 'delete() first resource');
is ($resource_2->delete(), '1', 'delete() second resource');

# delete test resource location type
is (MyLibrary::Resource::Location->location_type(action => 'delete', id => $location_type_id), 1, 'location_type() deleted');
