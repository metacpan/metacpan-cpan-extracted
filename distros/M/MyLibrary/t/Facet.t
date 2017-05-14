use Test::More tests => 31;
use strict;

# use the module
use_ok('MyLibrary::Facet');

# create a facet object
my $facet = MyLibrary::Facet->new();
isa_ok($facet, "MyLibrary::Facet");

# set the facet's name
$facet->facet_name('ZZZZZ Test Audiences');
is($facet->facet_name(), 'ZZZZZ Test Audiences', 'set name()');

# set the the facet's note
$facet->facet_note('Listed here are types of people who use MyLibrary.');
is($facet->facet_note(), 'Listed here are types of people who use MyLibrary.', 'set note()');

# save a new facet record
is($facet->commit(), '1', 'commit()');

# get a facet id
my $id = $facet->facet_id();
like ($id, qr/^\d+$/, 'get facet_id()');

# get record based on an id
$facet = MyLibrary::Facet->new(id => $id);
is ($facet->facet_name(), 'ZZZZZ Test Audiences', 'get name() matches based on id');
is ($facet->facet_note(), 'Listed here are types of people who use MyLibrary.', 'get note() matches based on id');

# get record based on facet name
$facet = MyLibrary::Facet->new(name => 'ZZZZZ Test Audiences');
is ($facet->facet_id(), $id, 'get id() matches based on name');
is ($facet->facet_note(), 'Listed here are types of people who use MyLibrary.', 'get note() matches based on name');

# update a facet record
$facet->facet_name('ZZZZZ Test Types');
$facet->facet_note('These are selected sorts of information resources.');
$facet->commit();
$facet = MyLibrary::Facet->new(id => $id);
is ($facet->facet_name(), 'ZZZZZ Test Types', 'commit() update');
is ($facet->facet_note(), 'These are selected sorts of information resources.', 'commit() update');

# get an array of related term ids
use_ok('MyLibrary::Term');
my @term_array = ();
my $term = MyLibrary::Term->new();
$term->term_name('Type One');
$term->term_note('This is a test term.');
$term->facet_id($facet->facet_id());
$term->commit();
my $term_id = $term->term_id();
push (@term_array, $term_id);
$term = MyLibrary::Term->new(id => $term_id);
is ($term->term_name(), 'Type One', "term->new() => $term_id"); 
$term = MyLibrary::Term->new();
$term->term_name('Type Two');
$term->term_note('This is a test term.');
$term->facet_id($facet->facet_id());
$term->commit();
$term_id = $term->term_id();
push (@term_array, $term_id);
$term = MyLibrary::Term->new(id => $term_id);
is ($term->term_name(), 'Type Two', "term->new() => $term_id");
$term = MyLibrary::Term->new();
$term->term_name('Type Three');
$term->term_note('This is a test term.');
$term->facet_id($facet->facet_id());
$term->commit();
$term_id = $term->term_id();
push (@term_array, $term_id);
$term = MyLibrary::Term->new(id => $term_id);
is ($term->term_name(), 'Type Three', "term->new() => $term_id");
$term = MyLibrary::Term->new();
$term->term_name('AAAAbbbcc');
$term->term_note('This is a test term.');
$term->facet_id($facet->facet_id());
$term->commit();
$term_id = $term->term_id();
push (@term_array, $term_id);
$term = MyLibrary::Term->new(id => $term_id);
is ($term->term_name(), 'AAAAbbbcc', "term->new() => $term_id");
$facet = MyLibrary::Facet->new(id => $id);
is ($facet->facet_name(), 'ZZZZZ Test Types', "new() called => facet $id found");
my @related_terms = $facet->related_terms();
is (scalar(@related_terms), 4, 'related_terms() found 3 terms');
@term_array = sort(@term_array);
@related_terms = sort(@related_terms);
for (my $i = 0; $i < scalar(@related_terms); $i++) {
	is ("$related_terms[$i]", "$term_array[$i]", "related_terms() found => $term_array[$i]");
}
@related_terms = $facet->related_terms(sort => 'name');
my $alpha_sort_term = MyLibrary::Term->new(id => $related_terms[0]);
is ($alpha_sort_term->term_name(), 'AAAAbbbcc', 'related_terms(sort => name)');
foreach my $term_del_id (@term_array) {
	my $term = MyLibrary::Term->new(id => $term_del_id);
	is ($term->delete(), '1', "term delete() => $term_del_id");
}

# get facets
my @f = MyLibrary::Facet->get_facets(sort => 'name');
my $facet_count = scalar(@f);
like ($facet_count, qr/^\d+$/, "get_facets() $facet_count found");

# get facets by criteria
@f = MyLibrary::Facet->get_facets(value => 'ZZZZZ Test Types', field => 'name', sort => 'name');
my $facet_test_name = $f[0]->facet_name();
is ("$facet_test_name", 'ZZZZZ Test Types', 'get_facets(value, field)');

# delete a facet record
is ($facet->delete(), '1', 'delete() a facet');
