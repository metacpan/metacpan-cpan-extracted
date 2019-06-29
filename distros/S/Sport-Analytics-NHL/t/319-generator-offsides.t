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
use Sport::Analytics::NHL::Tools qw(get_catalog_map get_zones);
if ($ENV{HOCKEYDB_NODB} || ! $MONGO_DB) {
        plan skip_all => 'Mongo not defined';
        exit;
}
plan tests => 94;

use Sport::Analytics::NHL::DB;
#$ENV{HOCKEYDB_DEBUG} = 1;
$ENV{HOCKEYDB_DRYRUN} = 1;
$DB = Sport::Analytics::NHL::DB->new();
my $games_c = $DB->get_collection('games');
my $game = $games_c->find_one(
	{_id => 198720187}
);
my $offsides_i = Sport::Analytics::NHL::Generator::get_offsides_iterator($game);
is($offsides_i, undef, 'no offsides that early');

$game = $games_c->find_one(
	{_id => 201830187}
);

$offsides_i = Sport::Analytics::NHL::Generator::get_offsides_iterator($game);
isa_ok($offsides_i, 'MongoDB::Cursor');
my $FAC_c    = $DB->get_collection('FAC');
my @faceoffs = $FAC_c->find({ game_id => $game->{_id} })->sort({ ts => 1 })->all();
my $zones  = get_zones();
my $f_n = scalar @faceoffs;
my $o = 0;
while (my $offside = $offsides_i->next()) {
	$o++;
	my $faceoff = Sport::Analytics::NHL::Generator::get_offside_faceoff($offside, \@faceoffs, $zones);
	if ($offside->{_id} == 2018301870340) {
		ok (! $faceoff, 'bad offside faceoff expected');
		next;
	}
	is($faceoff->{ts}, $offside->{ts}, 'same ts');
	ok($faceoff->{_id} > $offside->{_id}, 'fo id past offside');
	ok(scalar(@faceoffs) < $f_n, 'faceoff list shrunk');
	ok($faceoff->{coordinates}{x}, 'x is not 0');
	ok($faceoff->{coordinates}{y}, 'y is not 0');
	is($faceoff->{zone}, $zones->{NEU}, 'it is in neutral zone');
}

my @updates = Sport::Analytics::NHL::Generator::generate_offsides_info($game, 1);
is(scalar(@updates), $o-1, 'one bad offside omitted');
for my $update (@updates) {
	like($update->{team1}, qr/^[A-Z]{3}$/, 'team1 set');
	like($update->{team2}, qr/^[A-Z]{3}$/, 'team2 set');
	like($update->{t},     qr/^(0|1)$/,    't set');
	isnt($update->{team1}, $update->{team2}, 'team1 team2 different');
}

__END__
my $zones = get_catalog_map('zones');
my $offsides = $offsides_i->next();
my $faceoff = {
	zone => $zones->{DEF},
	winning_team => 'SJS',
	team2 => 'VGK',
	_id => 1,
};
my $update = Sport::Analytics::NHL::Generator::set_offsides_properties($offsides, $faceoff, $zones);
is_deeply(
	$update, {
		_id => $offsides->{_id},
		faceoff_win => 1,
		team1 => 'SJS',
		team2 => 'VGK',
		faceoff => $faceoff->{_id},
	},
	'properties correct',
);
$faceoff->{zone} = $zones->{OFF};
$update = Sport::Analytics::NHL::Generator::set_offsides_properties($offsides, $faceoff, $zones);
is_deeply(
	$update, {
		_id => $offsides->{_id},
		faceoff_win => 0,
		team1 => 'VGK',
		team2 => 'SJS',
		faceoff => $faceoff->{_id},
	},
	'properties correct',
);

my $event;
$faceoff->{ts} = $offsides->{ts};
$event->{ts} = $faceoff->{ts} + 500;
is(Sport::Analytics::NHL::Generator::adjudicate_offsides_quality(
	$event, $faceoff, $offsides->{team1}, $zones
), $OFFSIDES_GOOD, 'good offsides by timeout');
$event->{type} = 'STOP';
$event->{stopreasons} = [ $CACHES->{stopreasons}{offsides} ];
$event->{ts} = $offsides->{ts} + 1;
is(Sport::Analytics::NHL::Generator::adjudicate_offsides_quality(
	$event, $faceoff, $offsides->{team1}, $zones
), $OFFSIDES_NEUTRAL, 'neutral offsides by offsides');
$event->{stopreasons} = [ 'xjxjxjx' ];
is(Sport::Analytics::NHL::Generator::adjudicate_offsides_quality(
	$event, $faceoff, $offsides->{team1}, $zones
), $OFFSIDES_GOOD, 'good offsides by other stop');
$event->{type} = 'PEND';
is(Sport::Analytics::NHL::Generator::adjudicate_offsides_quality(
	$event, $faceoff, $offsides->{team1}, $zones
), $OFFSIDES_GOOD, 'good offsides by PEND');
$event->{type} = 'PENL';
$event->{team1} = $update->{team2};
$event->{zone} = $zones->{DEF};
$faceoff->{zone} = $zones->{DEF};
is(Sport::Analytics::NHL::Generator::adjudicate_offsides_quality(
	$event, $faceoff, $update->{team1}, $zones
), $OFFSIDES_GOOD, 'good offsides by PENL on other team');
$event->{team1} = $update->{team1};
is(Sport::Analytics::NHL::Generator::adjudicate_offsides_quality(
	$event, $faceoff, $update->{team1}, $zones
), $OFFSIDES_BAD, 'bad offsides by PENL on the same team');
$event->{matched} = 1;
is(Sport::Analytics::NHL::Generator::adjudicate_offsides_quality(
	$event, $faceoff, $update->{team1}, $zones
), $OFFSIDES_GOOD, 'good offsides by PENL by matching penalty');
$event->{type} = 'GOAL';
is(Sport::Analytics::NHL::Generator::adjudicate_offsides_quality(
	$event, $faceoff, $update->{team1}, $zones
), $OFFSIDES_GOOD, 'good offsides by GOAL');
$event->{team1} = 'SJS';
is(Sport::Analytics::NHL::Generator::adjudicate_offsides_quality(
	$event, $faceoff, $update->{team1}, $zones
), $OFFSIDES_DISASTER, 'disaster offsides by GOAL of other team');

my @updates = Sport::Analytics::NHL::Generator::generate_offsides_info($game, 1);
for my $_update (@updates) {
	ok($_update->{team1}, 'team1 defined');
	ok($_update->{team2}, 'team2 defined');
	ok(defined $_update->{faceoff_win}, 'fo win defined');
	like($_update->{faceoff}, qr/^\d{13}$/, 'faceoff id set');
	ok(defined $_update->{quality}, 'quality defined');
}
