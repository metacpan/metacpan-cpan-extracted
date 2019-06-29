#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;

use Sport::Analytics::NHL::Generator;
use Sport::Analytics::NHL::Config qw(:icing);
use Sport::Analytics::NHL::Vars  qw($DB $CACHES $MONGO_DB);
use Sport::Analytics::NHL::Util  qw(:debug);
use Sport::Analytics::NHL::Tools qw(get_catalog_map);
if ($ENV{HOCKEYDB_NODB} || ! $MONGO_DB) {
        plan skip_all => 'Mongo not defined';
        exit;
}
plan tests => 107;

use Sport::Analytics::NHL::DB;
#$ENV{HOCKEYDB_DEBUG} = 1;
$ENV{HOCKEYDB_DRYRUN} = 1;
$DB = Sport::Analytics::NHL::DB->new();
my $games_c = $DB->get_collection('games');
my $game = $games_c->find_one(
	{_id => 201830187}
);

my $icing_i = Sport::Analytics::NHL::Generator::get_icing_iterator($game);
isa_ok($icing_i, 'MongoDB::Cursor');

my $zones = get_catalog_map('zones');
my $icing = $icing_i->next();
my $faceoff = {
	zone => $zones->{DEF},
	winning_team => 'SJS',
	team2 => 'VGK',
	_id => 1,
};
my $update = Sport::Analytics::NHL::Generator::set_icing_properties($icing, $faceoff, $zones);
is_deeply(
	$update, {
		_id => $icing->{_id},
		faceoff_win => 1,
		team1 => 'SJS',
		team2 => 'VGK',
		faceoff => $faceoff->{_id},
	},
	'properties correct',
);
$faceoff->{zone} = $zones->{OFF};
$update = Sport::Analytics::NHL::Generator::set_icing_properties($icing, $faceoff, $zones);
is_deeply(
	$update, {
		_id => $icing->{_id},
		faceoff_win => 0,
		team1 => 'VGK',
		team2 => 'SJS',
		faceoff => $faceoff->{_id},
	},
	'properties correct',
);

my $event;
$faceoff->{ts} = $icing->{ts};
$event->{ts} = $faceoff->{ts} + 500;
is(Sport::Analytics::NHL::Generator::adjudicate_icing_quality(
	$event, $faceoff, $icing->{team1}, $zones
), $ICING_GOOD, 'good icing by timeout');
$event->{type} = 'STOP';
$event->{stopreasons} = [ $CACHES->{stopreasons}{icing} ];
$event->{ts} = $icing->{ts} + 1;
is(Sport::Analytics::NHL::Generator::adjudicate_icing_quality(
	$event, $faceoff, $icing->{team1}, $zones
), $ICING_NEUTRAL, 'neutral icing by icing');
$event->{stopreasons} = [ 'xjxjxjx' ];
is(Sport::Analytics::NHL::Generator::adjudicate_icing_quality(
	$event, $faceoff, $icing->{team1}, $zones
), $ICING_GOOD, 'good icing by other stop');
$event->{type} = 'PEND';
is(Sport::Analytics::NHL::Generator::adjudicate_icing_quality(
	$event, $faceoff, $icing->{team1}, $zones
), $ICING_GOOD, 'good icing by PEND');
$event->{type} = 'PENL';
$event->{team1} = $update->{team2};
$event->{zone} = $zones->{DEF};
$faceoff->{zone} = $zones->{DEF};
is(Sport::Analytics::NHL::Generator::adjudicate_icing_quality(
	$event, $faceoff, $update->{team1}, $zones
), $ICING_GOOD, 'good icing by PENL on other team');
$event->{team1} = $update->{team1};
is(Sport::Analytics::NHL::Generator::adjudicate_icing_quality(
	$event, $faceoff, $update->{team1}, $zones
), $ICING_BAD, 'bad icing by PENL on the same team');
$event->{matched} = 1;
is(Sport::Analytics::NHL::Generator::adjudicate_icing_quality(
	$event, $faceoff, $update->{team1}, $zones
), $ICING_GOOD, 'good icing by PENL by matching penalty');
$event->{type} = 'GOAL';
is(Sport::Analytics::NHL::Generator::adjudicate_icing_quality(
	$event, $faceoff, $update->{team1}, $zones
), $ICING_GOOD, 'good icing by GOAL');
$event->{team1} = 'SJS';
is(Sport::Analytics::NHL::Generator::adjudicate_icing_quality(
	$event, $faceoff, $update->{team1}, $zones
), $ICING_DISASTER, 'disaster icing by GOAL of other team');

my @updates = Sport::Analytics::NHL::Generator::generate_icings_info($game, 1);
for my $_update (@updates) {
	ok($_update->{team1}, 'team1 defined');
	ok($_update->{team2}, 'team2 defined');
	ok(defined $_update->{faceoff_win}, 'fo win defined');
	like($_update->{faceoff}, qr/^\d{13}$/, 'faceoff id set');
	ok(defined $_update->{quality}, 'quality defined');
}
