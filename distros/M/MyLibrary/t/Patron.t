use Test::More tests => 40;
use strict;

# use the module
use_ok('MyLibrary::Patron');

# create a patron object
my $patron = MyLibrary::Patron->new();
isa_ok($patron, "MyLibrary::Patron");

# set an email attribute
$patron->patron_email('johan@nd.edu');
is($patron->patron_email(), 'johan@nd.edu', 'set patron_email()');

# set patron_firstname attribute
$patron->patron_firstname('Johan');
is($patron->patron_firstname(), 'Johan', 'set patron_firstname()');

# set the patron_surname attribute
$patron->patron_surname('Hamann');
is($patron->patron_surname(), 'Hamann', 'set patron_surname()');

# set the patron_address_1 attribute
$patron->patron_address_1('209 W. North Zweigen Drive');
is($patron->patron_address_1(), '209 W. North Zweigen Drive', 'set patron_address_1()');

# set the patron_address_2 attribute
$patron->patron_address_2('I do not have a second address line');
is($patron->patron_address_2(), 'I do not have a second address line', 'set patron_address_2()');

# set the patron_address_3 attribute
$patron->patron_address_3('46617');
is($patron->patron_address_3(), '46617', 'set patron_address_3()');

# set the patron_address_4 attribute
$patron->patron_address_4('South Bend');
is($patron->patron_address_4(), 'South Bend', 'set patron_address_4()');

# set the patron_address_5 attribute
$patron->patron_address_5('IN');
is($patron->patron_address_5(), 'IN', 'set patron_address_5()');

# set the patron_url attribute
$patron->patron_url('http://www.nd.edu/~jhamann');
is($patron->patron_url(), 'http://www.nd.edu/~jhamann', 'set patron_url()');

# set the patron_image attribute
$patron->patron_image('/home/images/jhamman.jpg');
is($patron->patron_image(), '/home/images/jhamman.jpg', 'set patron_image()');

# set the patron_password attribute
$patron->patron_password('mypass');
is($patron->patron_password(), crypt('mypass', substr('mypass', 0, 2)), 'set patron_password()');

# set the patron_organization attribute
$patron->patron_organization('University of Utah');
is($patron->patron_organization(), 'University of Utah', 'set patron_organization()');

# set the patron_can_contact attribute
$patron->patron_can_contact('1');
is($patron->patron_can_contact(), '1', 'set patron_can_contact()');

# set the patron_remember_me attribute
$patron->patron_remember_me('1');
is($patron->patron_remember_me(), '1', 'set patron_remember_me()');

# set the patron_username attribute
$patron->patron_username('emorgan');
is($patron->patron_username(), 'emorgan', 'set patron_username()');

# set the patron_last_visit attribute
$patron->patron_last_visit('2003-09-09');
is($patron->patron_last_visit(), '2003-09-09', 'set patron_last_visit()');

# set the patron_total_visits attribute
$patron->patron_total_visits('10');
is($patron->patron_total_visits(), '10', 'set patron_total_visits()');

# set the patron_stylesheet_id attribute
$patron->patron_stylesheet_id('4');
is($patron->patron_stylesheet_id(), '4', 'set patron_stylesheet_id()');

# save new patron record
$patron->commit();
my $id = $patron->patron_id();
like ($id, qr/^\d+$/, 'get patron_id()');

# get record based on an id
my $q = MyLibrary::Patron->new(id => $id);
is ($q->patron_firstname(), 'Johan', 'get patron_firstname()');
is ($q->patron_surname(), 'Hamann', 'get patron_surname()');
is ($q->patron_email(), 'johan@nd.edu', 'get patron_email()');

# update patron record
$q->patron_firstname('Tilly');
$q->commit();
my $r = MyLibrary::Patron->new(id => $id);
is ($r->patron_firstname(), 'Tilly', 'commit()');

# Assign some personal links to this patron
$patron->add_link(link_name => 'CNN', link_url => 'http://mysite.com');
$patron->add_link(link_name => 'CNN2', link_url => 'http://mysite2.com');
my @personal_links = $patron->get_links();
is($personal_links[0]->link_name(), 'CNN', 'add_link()');
cmp_ok(scalar(@personal_links), '>=', 2, 'get_links()');
is($patron->delete_link(link_id => $personal_links[0]->link_id()), 1, 'delete_link()');
$patron->delete_link(link_id => $personal_links[1]->link_id());

# Add some terms for this patron

# first, create the terms
use MyLibrary::Term;
my $term_1 = MyLibrary::Term->new();
$term_1->term_name('Test Term B');
$term_1->term_note('Test Term - Delete if found');
$term_1->facet_id(9999);
$term_1->commit();
my $term_1_id = $term_1->term_id();

my $term_2 = MyLibrary::Term->new();
$term_2->term_name('Test Term A');
$term_2->term_note('Test Term - Delete if found');
$term_2->facet_id(9999);
$term_2->commit();
my $term_2_id = $term_2->term_id();

# now, associate them with this patron
my @patron_terms = $q->patron_terms(new => [$term_1_id, $term_2_id], sort => 'name');
my $res_string;
foreach my $new_resource (@patron_terms) {
        $res_string .= "$new_resource ";
}
chop($res_string);
is (scalar(@patron_terms), 2, "patron_terms() 2 terms ($res_string) added to object");

# check to make sure the list is sorted by name
is ((MyLibrary::Term->new(id => $patron_terms[0]))->term_name(), 'Test Term A', 'patron_terms(sort)');

# Add some resources to this patron

# first, create the resources
use MyLibrary::Resource;
my $resource_1 = MyLibrary::Resource->new();
$resource_1->name('Test Resource B');
$resource_1->note('Test Resource - Delete if found');
$resource_1->commit();
my $resource_1_id = $resource_1->id();

my $resource_2 = MyLibrary::Resource->new();
$resource_2->name('Test Resource A');
$resource_2->note('Test Resource - Delete if found');
$resource_2->commit();
my $resource_2_id = $resource_2->id();

# now, associate them with this patron
my @patron_resources = $q->patron_resources(new => [$resource_1_id, $resource_2_id], sort => 'name');
foreach my $new_resource (@patron_resources) {
        $res_string .= "$new_resource ";
}
chop($res_string);
is (scalar(@patron_resources), 2, "patron_resources() 2 resources ($res_string) added to object");

# check to make sure the list is sorted by name
is ((MyLibrary::Resource->new(id => $patron_resources[0]))->name(), 'Test Resource A', 'patron_resources(sort)');

# increment the usage count for a resource
MyLibrary::Patron->resource_usage(action => 'increment', patron => $q->patron_id(), resource => $resource_1_id);
is (MyLibrary::Patron->resource_usage(action => 'resource_usage_count', patron => $q->patron_id(), resource => $resource_1_id), 1, 'resource_usage(action => \'resource_usage_count\')');

# determine the absolute usage count for first resource
MyLibrary::Patron->resource_usage(action => 'increment', patron => $q->patron_id(), resource => $resource_1_id);
is (MyLibrary::Patron->resource_usage(action => 'absolute_usage_count', resource => $resource_1_id), 2, 'resource_usage(action => \'absolute_usage_count\')');

# determine number of patrons having used a particular resource
is (MyLibrary::Patron->resource_usage(action => 'patron_usage_count', resource => $resource_1_id), 1, 'resource_usage(action => \'patron_usage_count\')');

# get the count of resources this patron has used
MyLibrary::Patron->resource_usage(action => 'increment', patron => $q->patron_id(), resource => $resource_2_id);
is (MyLibrary::Patron->resource_usage(action => 'patron_resource_count', patron => $q->patron_id()), 2, 'resource_usage(action => \'patron_resource_count\')');

# delete one resource association
is ($q->patron_resources(del => [$resource_2_id]), 1, "patron_resources() delete 1 resource association $resource_2_id");

# delete one term association
is ($q->patron_terms(del => [$term_2_id]), 1, "patron_terms() delete 1 term association $term_2_id");

$resource_1->delete();
$resource_2->delete();

$term_1->delete();
$term_2->delete();

# get patrons
my @p = MyLibrary::Patron->get_patrons();
my $patron_found = 0;
foreach $patron (@p) {
	if ($patron->patron_firstname() eq 'Tilly' && $patron->patron_surname() eq 'Hamann') {
		$patron_found = 1;
	}
}
is ($patron_found, 1, 'get_patrons()');

# delete record based on id
my $rv = $q->delete();
is($rv, 1, 'delete()');
