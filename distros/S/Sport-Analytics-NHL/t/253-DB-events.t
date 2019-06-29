#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;
use List::MoreUtils qw(uniq);
use Storable;

use JSON;

use Sport::Analytics::NHL::Vars qw($IS_AUTHOR $MONGO_DB);
use Sport::Analytics::NHL::DB;
use Sport::Analytics::NHL;

use t::lib::Util;

if ($ENV{HOCKEYDB_NODB} || ! $MONGO_DB) {
	plan skip_all => 'Mongo not defined';
	exit;
}
plan qw(no_plan);
test_env();
my @collections = ();
my $db = Sport::Analytics::NHL::DB->new();
$ENV{HOCKEYDB_DEBUG} = $IS_AUTHOR;

my $location = $db->create_location({
	name => 'Aba baa  baa ',
	capacity => 15000,
});
isa_ok($location->{_id}, 'BSON::OID', '_id created');
is($location->{capacity}, 15000, 'capacity installed');
is($location->{name}, 'ABA BAA BAA', 'name normalized');

my $new_location = $db->create_location({
	name => 'Aba baa  baa ',
	capacity => 15000,
});
is_deeply($location, $new_location, 'no update');

$new_location = $db->create_location({
	name => 'Aba baa  baa ',
	capacity => 16000,
});
is($location->{_id}, $new_location->{_id}, 'no new _id created');
is($new_location->{capacity}, 16000, 'capacity updated');
is($new_location->{name}, 'ABA BAA BAA', 'name normalized and kept the same');

push(@collections, $db->get_collection('locations'));
my $hdb = Sport::Analytics::NHL->new();
use Data::Dumper;
push(@collections, $db->get_collection('test'));
my $entry = $db->get_catalog_entry('test', {just => 'ref'});
is_deeply($entry, { just => 'ref'}, 'ref detected');

$entry = $db->get_catalog_entry('test', 'JAJA');
isa_ok($entry->{_id}, 'BSON::OID', 'new entry created');
is($entry->{name}, 'JAJA', 'name preserved');
my $new_entry = $db->get_catalog_entry('test', 'JAJA');
is_deeply($new_entry, $entry, 'no new entry inserted');
my $indices = [$db->get_collection('test')->indexes()->list->all()];
is_deeply($indices->[0]{key}, {_id => 1}, '_id a key');
is_deeply($indices->[1]{key}, {name => 1}, 'name a key');
is($indices->[1]{unique}, 1, 'name a unique key');

for (201120010, 193020010) {
	my @normalized = $hdb->normalize({data_dir => 't/data/'}, $_);
	my $boxscore = retrieve $normalized[0];

	for my $event (@{$boxscore->{events}}) {
		my $event_c  = $db->get_collection($event->{type});
		push(@collections, $event_c);
		$db->ensure_event_indices($event, $event_c);
		my $indices = [$event_c->indexes()->list->all()];
		is($indices->[1]{key}{game_id},1, 'game_id an index');
		for ($event->{type}) {
			when ('GEND') {
				is($indices->[1]{unique}, 1, 'gend unique for game');
			}
			when ('PEND') {
				is($indices->[1]{unique}, 1, 'pend unique for game');
				is($indices->[1]{key}{period},1, 'period part of key');
			}
			when ('PSTR') {
				is($indices->[1]{unique}, 1, 'pstr unique for game');
				is($indices->[1]{key}{period},1, 'period part of key');
			}
			when ('STOP') {
				ok(@{$event->{stopreasons}}, 'some stopreasons');
				for my $stopreason (@{$event->{stopreasons}}) {
					isa_ok($stopreason, 'BSON::OID', 'stopreason an OID');
				}
			}
		}
	}
	$_->drop() for @collections;
	my $events_c = $db->get_collection('events');
	push(@collections, $events_c);
	for my $event (@{$boxscore->{events}}) {
		my $event_c = $db->get_collection($event->{type});
		my $event_id = $db->create_event($event);
		push(@collections, $event_c);
		my $_event = $events_c->find_one({event_id => $event_id});
		my $event_db = $event_c->find_one({_id => $event_id});
		isa_ok($_event->{_id}, 'BSON::OID', '_event has an OID');
		is($_event->{event_id}, $event_db->{_id}, 'id referenced');
		is($_event->{game_id}, $boxscore->{_id}, 'game id referenced');
		is($event_db->{game_id}, $boxscore->{_id}, 'game id referenced');
		is($_event->{type}, $event->{type}, 'type preserved');
		for my $field (qw(location shot_type miss penalty strength zone)) {
			if (exists $event->{$field}) {
				isa_ok($event_db->{$field}, 'BSON::OID', 'event field has a catalog OID');
			}
		}
	}
}


END {
	$_->drop() for uniq @collections;
}
