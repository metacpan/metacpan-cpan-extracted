#!perl

use warnings;
use strict;
use utf8;
use MorboDB;
use Test::More tests => 28;
use Try::Tiny;
use Tie::IxHash;

# create a new MorboDB object
my $morbo = MorboDB->new;
ok($morbo, 'Got a proper MorboDB object');

# create a MorboDB database
my $db = $morbo->get_database('morbodb_test');
ok($db, 'Got a proper MorboDB::Database object');

# create a MorboDB collection
my $coll = $db->get_collection('tv_shows');
ok($coll, 'Got a proper MorboDB::Collection object');

# create some documents
my $id1 = $coll->insert({
	title => 'Undeclared',
	year => 2001,
	seasons => 1,
	genres => [qw/comedy drama/],
	starring => ['Jay Baruchel', 'Carla Gallo', 'Jason Segel'],
});
my ($id2, $id3) = $coll->batch_insert([
	{
		title => 'How I Met Your Mother',
		year => 2005,
		seasons => 7,
		genres => [qw/comedy romance/],
		starring => ['Josh Radnor', 'Jason Segel', 'Cobie Smulders', 'Neil Patrick Harris', 'Alyson Hannigan'],
	}, {
		title => 'Freaks and Geeks',
		year => 1999,
		seasons => 1,
		genres => [qw/comedy drama/],
		starring => ['Linda Cardellini', 'John Francis Daley', 'James Franco'],
	},
]);
# When there's no _id, save() should perform an insert
my $id4 = $coll->save({
   title => 'My Name Is Earl',
   year => 2005,
   seasons => 4,
   genres => [qw/comedy/],
   starring => ['Jason Lee', 'Ethan Suplee', 'Jaime Pressly'],
});

is(ref $id1, 'MorboDB::OID', 'insert() returned a MorboDB::OID object');
is(length($id1->value), 36, 'insert() returned a 36-character long OID');
is(ref $id4, 'MorboDB::OID', 'save() returned a MorboDB::OID object');
is(length($id4->value), 36, 'save() returned a 36-character long OID');

# find some documents
my $curs1 = $coll->find({ _id => $id1 });
is($curs1->count, 1, 'count is 1 when searching for a known ID');
my $doc1_from_cursor = $curs1->next;
is($doc1_from_cursor->{title}, 'Undeclared', 'document has the correct title attribute');
my $doc1_from_fone = $coll->find_one({ _id => $id1 });
is_deeply($doc1_from_fone, $doc1_from_cursor, 'find_one by ID finds the same thing as find');
my $curs2 = $coll->find({ starring => 'Jason Segel' });
is($curs2->count, 2, 'Jason Segel stars in two shows');

# update Freaks and Geeks 'cause Jason Segel stars in that one too
my $up1 = $coll->update({ title => qr/^Freaks/ }, { '$push' => { starring => 'Jason Segel' } });
ok($up1->{ok} == 1 && $up1->{n} == 1, 'update seems to have succeeded');

# let's see in how many shows Jason Segel stars now
my $curs3 = $coll->find({ starring => 'Jason Segel' });
is($curs3->count, 3, 'Jason Segel now stars in three shows');

# let's find all documents in the collection
my $curs4 = $coll->find;
is($curs4->count, 4, 'find() with no arguments found all documents');

# let's try to sort the cursor (this should fail)
my $sort = Tie::IxHash->new(year => -1, title => 1);
eval { $curs4->sort($sort) };
ok($@ =~ m/cannot set sort after querying/, 'cannot set sort after querying');

# let's reset the cursor and try again
ok($curs4->started_iterating, 'cursor started iterating');
$curs4->reset;
ok(!$curs4->started_iterating, 'cursor has been reset');
eval { $curs4->sort($sort) };
ok(!$@, 'sort succeeded this time');

# let's see if sort was made correctly, we'll also check the next method
# on the way:
my @docs;
while ($curs4->has_next) {
	push(@docs, $curs4->next);
}

is_deeply([map($_->{_id}, @docs)], [$id2, $id4, $id1, $id3], 'results were sorted correctly');

# let's try an upsert
my $up2 = $coll->update({ title => 'Buffy the Vampire Slayer' }, {
	'$set' => {
		seasons => 7,
		starring => ['Sarah Michelle Gellar', 'Alyson Hannigan'],
	},
	'$inc' => {
		year => 1997,
	},
	'$pushAll' => {
		genres => [qw/action drama fantasy/],
	},
}, { upsert => 1 });
is(ref($up2->{upserted}), 'MorboDB::OID', 'upsert seems to have succeeded');

# let's find the upserted document
my $doc3 = $coll->find_one({ year => { '$gt' => 1996, '$lte' => 1997 } });
ok($doc3->{title} eq 'Buffy the Vampire Slayer', 'upserted document exists in the database');

# let's try to remove all Jason Segel starring shows
my $rem1 = $coll->remove({ starring => 'Jason Segel' });
is($rem1->{n}, 3, 'removed three documents as expected');
my $curs5 = $coll->find({ starring => 'Jason Segel' });
is($curs5->count, 0, 'No more Jason Segel shows');

# how many documents do we have left?
is($coll->count, 2, 'we have two documents left');

# let's remove that document too
$coll->remove;
is($coll->count, 0, 'we have on more documents');

# let's reinsert a document
$coll->insert({ _id => 1, title => 'WOOOOOOEEEEE' });
is($coll->count, 1, 'new document created');
# and now drop the collection
$coll->drop;
is($coll->count, 0, 'dropped collection is empty (as it does not exist)');

# let's check child collections
my $child = $coll->get_collection('child');
is($child->name, 'tv_shows.child', 'child collection okay');

# let's drop the database

done_testing();
