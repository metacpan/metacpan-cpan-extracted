use Test::More tests => 48;
use strict;

# use the module
use_ok('MyLibrary::Term');

# create a term object
my $term = MyLibrary::Term->new();
isa_ok($term, "MyLibrary::Term");

# set the term's name
$term->term_name('Freshman_test');
is($term->term_name(), 'Freshman_test', 'set term_name()');

# set the term's note
$term->term_note('These are people who are in their first year of college.');
is($term->term_note(), 'These are people who are in their first year of college.', 'set term_note()');

# set the term's associated facet
$term->facet_id('123');
is($term->facet_id(), '123', 'set facet_id()');

# save a new term record
is($term->commit(), '1', 'commit() a new term record');

# get a term id
my $id = $term->term_id();
like ($id, qr/^\d+$/, 'get term_id()');

# get a term name
my $name = $term->term_name();
like ($name, qr/Freshman_test/, 'get term_name()'); 

# get record based on an id
$term = MyLibrary::Term->new(id => $id);
is ($term->term_name(), 'Freshman_test', 'get term_name()');
is ($term->term_note(), 'These are people who are in their first year of college.', 'get term_note()');
is ($term->facet_id(), '123', 'get facet_id()');

# get record based on name
$term = MyLibrary::Term->new(name => 'Freshman_test');
is ($term->term_id(), $id, 'get term_id()');
is ($term->term_note(), 'These are people who are in their first year of college.', 'get term_note()');
is ($term->facet_id(), '123', 'get facet_id()');

# update a term
$term->term_name('Sophmore_test');
$term->term_note('Generally speaking, these are folks in their second year of college.');
$term->facet_id('456');
$term->commit();
$term = MyLibrary::Term->new(id => $id);
is ($term->term_name(), 'Sophmore_test', 'commit() an updated term name');
is ($term->term_note(), 'Generally speaking, these are folks in their second year of college.', 'commit() an updated term note');
is ($term->facet_id(), '456', 'commit() an updated facet id');

# supply a list of new related resources
use_ok('MyLibrary::Resource');
my @resource_array = ();
my @del_resource_array = ();
my $resource = MyLibrary::Resource->new();
$resource->name('Test Resource 1');
$resource->note('Note for test resource one.');
$resource->lcd('0');
$resource->date('9999-09-09');
$resource->fkey('123456');
$resource->proxied(0);
$resource->commit();
my $resource_id = $resource->id();
push (@resource_array, $resource_id);
$resource = MyLibrary::Resource->new(id => $resource_id);
is ($resource->name(), 'Test Resource 1', "resource->new() => $resource_id");
$resource = MyLibrary::Resource->new();
$resource->name('Test Resource 2');
$resource->note('Note for test resource two.');
$resource->lcd('0');
$resource->date('9999-09-09');
$resource->fkey('123456');
$resource->proxied(0);
$resource->commit();
$resource_id = $resource->id();
push (@resource_array, $resource_id);
push (@del_resource_array, $resource_id);
$resource = MyLibrary::Resource->new(id => $resource_id);
is ($resource->name(), 'Test Resource 2', "resource->new() => $resource_id");
$resource = MyLibrary::Resource->new();
$resource->name('Test Resource 3');
$resource->note('Note for test resource three.');
$resource->lcd('0');
$resource->date('9999-09-09');
$resource->fkey('123456');
$resource->proxied(0);
$resource->commit();
$resource_id = $resource->id();
push (@resource_array, $resource_id);
$resource = MyLibrary::Resource->new(id => $resource_id);
is ($resource->name(), 'Test Resource 3', "resource->new() => $resource_id");
my @new_resources = $term->related_resources(new => [@resource_array]);
my $res_string;
foreach my $new_resource (@new_resources) {
	$res_string .= "$new_resource ";
}
chop($res_string);
is (scalar(@new_resources), 3, "related_resources() 3 resources ($res_string) added to object"); 

$term->commit();
$term = MyLibrary::Term->new(id => $id);
my @related_resources = $term->related_resources();
$res_string = "";
foreach my $related_resource (sort @related_resources) {
	$res_string .= "$related_resource ";
}
chop($res_string);
is ($term->related_resources(), 3, "related_resources() recursive => 3 resources ($res_string) found");

# create another term
my $term2 = MyLibrary::Term->new();
$term2->term_name('Faculty_test');
$term2->term_note('These are people who are generally instructors or researchers.');
$term2->facet_id('123');
$term2->commit();
my @overlap_terms = ($term2->term_id());

# add test resources to this new term
$term2->related_resources(new => [@related_resources]);
$term2->commit();

# and yet another term
my $term3 = MyLibrary::Term->new();
$term3->term_name('Administrator_test');
$term3->term_note('These are people who generally manage the institution.');
$term3->facet_id('123');
$term3->commit();
push(@overlap_terms, $term3->term_id());

# only add two resources this time
$term3->related_resources(new => [$related_resources[0]]);
$term3->related_resources(new => [$related_resources[1]]);
$term3->commit();

# overlap test
is ($term->overlap(term_ids => [@overlap_terms]), 2, "overlap() resources (2) found");

# distinct terms test
is (MyLibrary::Term->distinct_terms(resource_ids => [@related_resources]), 3, "distinct_terms() 3 found");

@related_resources = $term->related_resources(sort => 'name');
my $test_resource = MyLibrary::Resource->new(id => $related_resources[0]);
is ($test_resource->name(), 'Test Resource 1', 'related_resources(sort => name)');
is ($term->related_resources(del => [@del_resource_array]), 2, "related_resources() delete 1 resource association ($del_resource_array[0]) from object"); 
$res_string = "";
@related_resources = $term->related_resources();
foreach my $related_resource (sort @related_resources) {
	$res_string .= "$related_resource ";
}
chop($res_string);
is ($term->related_resources(), 2, "related_resources() 2 relations ($res_string) remain");
$term->commit();
$term = MyLibrary::Term->new(id => $id);
$res_string = "";
@related_resources = $term->related_resources();
foreach my $related_resource (sort @related_resources) {
	$res_string .= "$related_resource ";
}
chop($res_string);
is ($term->related_resources(), 2, "related_resources() and commit() match 2 relations ($res_string)");

# suggested resources
my $sug_string = $res_string;
is ($term->suggested_resources(new => [@related_resources]), 2, "suggested_resources() ($sug_string)"); 
$term->commit();
$term = MyLibrary::Term->new(id => $id);
my @suggested_resources = $term->suggested_resources();
$sug_string = "";
foreach my $suggested_resource (sort @suggested_resources) {
	$sug_string .= "$suggested_resource ";
}
chop($sug_string);
is ($term->suggested_resources(), 2, "suggested_resources() and commit() match 2 relations ($sug_string)");	
my $del_sug_resource = $suggested_resources[0];
is ($term->suggested_resources(del => [$del_sug_resource]), 1, "suggested_resources(del => $del_sug_resource)");
$term->commit();
@suggested_resources = $term->suggested_resources();
$sug_string = "";
foreach my $suggested_resource (sort @suggested_resources) {
	$sug_string .= "$suggested_resource ";
}
chop($sug_string);
is ($term->suggested_resources(), 1, "suggested_resources() 1 relation ($sug_string) remains");

# invent a librarian
use_ok('MyLibrary::Librarian');
my $librarian1 = MyLibrary::Librarian->new();
$librarian1->name('Jerome of Antioch');
$librarian1->email('jerome@antioch.edu');
$librarian1->telephone('1 (800) 777-7777');
$librarian1->url('http://jerome.antioch.edu/jerome/');
$librarian1->term_ids(new => [$term->term_id()]);
$librarian1->commit();

# invent a second librarian
my $librarian2 = MyLibrary::Librarian->new();
$librarian2->name('Athanasius of Alexandria');
$librarian2->email('ath@alexandria.edu');
$librarian2->telephone('1 (800) 777-7777');
$librarian2->url('http://jerome.antioch.edu/jerome/');
$librarian2->commit();

# add librarian association
my @librarians = $term->librarians(new => [$librarian2->id()]);
cmp_ok(scalar(@librarians), '>=', 2, 'librarians(new => [])');

# return list of librarian objects
@librarians = $term->librarians();
cmp_ok(scalar(@librarians), '>=', 2, 'librarians()');

# return a list of librarian ids
@librarians = $term->librarians(output => 'id');
cmp_ok(scalar(@librarians), '>=', 2, 'librarians(output => id)');

# delete a librarian association
$term->librarians(del => [$librarian2->id()]);
@librarians = $term->librarians(output => 'object');
my $found_librarian;
foreach my $librarian (@librarians) {
	if ($librarian->name() eq 'Athanasius of Alexandria') {
		$found_librarian = 1;
		last;
	} else {
		$found_librarian = 0;
	}
}
is("$found_librarian", 0, 'librarians(del => [])'); 

# delete test resources
foreach my $resource_id (@resource_array) {
	my $resource = MyLibrary::Resource->new(id => $resource_id);
	is ($resource->delete(), '1', "resource delete() => $resource_id");
}

# get_terms() class method
$term->term_name('jjjjyyyy');
$term->commit();
my @current_terms = MyLibrary::Term->get_terms();
my $found_term;
foreach my $current_term (@current_terms) {
	if ($current_term->term_name() eq 'jjjjyyyy') {
		$found_term = 1;
		last;
	}
}
is ($found_term, 1, 'get_terms()');

# get_terms() via criteria
my @test_terms = MyLibrary::Term->get_terms(field => 'name', value => 'jjjjyyyy');
cmp_ok (scalar(@test_terms), '>=', 1, 'get_terms(field, value)');

# delete a term
is ($term->delete(), '1', 'delete() a term');
is ($term2->delete(), '1', 'delete() a term');
is ($term3->delete(), '1', 'delete() a term');

# delete faux librarians
is ($librarian1->delete(), '1', 'delete() a librarian');
is ($librarian2->delete(), '1', 'delete() a librarian');

