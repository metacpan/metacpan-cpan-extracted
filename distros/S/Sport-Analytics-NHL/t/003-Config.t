#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;
plan tests => 1990;

use Sport::Analytics::NHL::Config qw(:all);
use Sport::Analytics::NHL::Vars qw($CURRENT_SEASON);

ok(defined $FIRST_SEASON,    'first season defined');
ok(scalar(@LOCKOUT_SEASONS), 'lockout seasons defined');

my $first = 0;
for my $doc (keys %FIRST_REPORT_SEASONS) {
	ok($FIRST_REPORT_SEASONS{$doc}, 'first season for each report defined');
	like($FIRST_REPORT_SEASONS{$doc}, qr/^\d{4}$/, 'each season is a YYYY');
	$first = 1 if $FIRST_REPORT_SEASONS{$doc} == $FIRST_SEASON;
}
ok($first, "a doc traces to $FIRST_SEASON");
while (my ($k, $v) = each %DEFAULTED_GAMES) {
	like($k, qr/^\d{9}$/, 'game id defaulted is key');
	is($v, 1, 'value is set');
}
ok(defined $MAIN_GAME_FILE,      'main game file defined');
ok(defined $SECONDARY_GAME_FILE, 'secondary game file defined');

ok(defined $REGULAR, 'regular stage defined');
ok(defined $PLAYOFF, 'playoff stage defined');

for my $team (keys %TEAMS) {
	like($team, qr/^[A-Z]{3}/, 'team id three digit code');
	for my $key (keys %{$TEAMS{$team}}) {
		next if $key eq 'timeline';
		if ($key eq 'founded' || $key eq 'folded') {
			like($TEAMS{$team}->{$key}, qr/^\d{4}$/, 'founded is a year');
		}
		elsif ($key eq 'defunct') {
			like($TEAMS{$team}->{$key}, qr/^0|1$/, 'defunct is 0 or 1');
		}
		elsif ($key eq 'color') {
			like($TEAMS{$team}->{$key}, qr/^\w+/, 'color is a word');
		}
		elsif ($key eq 'twitter') {
			like($TEAMS{$team}->{$key}, qr/^\@|\#\w+/, 'hashtag / @ for twitter');
		}
		else {
			isa_ok($TEAMS{$team}->{$key}, 'ARRAY', "a list of alternative names for team $team");
		}
	}
}

ok($UNDRAFTED_PICK, 'undrafted pick defined');

for ($UNKNOWN_PLAYER_ID, $BENCH_PLAYER_ID, $COACH_PLAYER_ID, $EMPTY_NET_ID) {
	like($_, qr/^800000\d/, 'dummy player starts with 80');
}

for my $vb (keys %VOCABULARY) {
	like($vb, qr/^\w+$/, 'vocabulary key is a word');
	while (my ($k, $v) = each %{$VOCABULARY{$vb}}) {
		like($k, qr/^(\S| )+$/, "term $k a word");
		unlike($k, qr/[a-z]/, 'no lowercase');
		isa_ok($v, 'ARRAY', 'meaning is array');
	}
}

while (my ($k, $v) = each %DATA_BY_SEASON) {
	like($k, qr/^\w+$/, "data type $k is a word");
	isa_ok($v, 'HASH', 'value is a HASH by itself');
	like($v->{season}, qr/^(0|\d{4})$/, 'season is 0 or year');
	like($v->{source}, qr/^(json|html)$/, 'source is json or html');
	ok($v->{descr}, 'data type defined');
}
while (my ($k, $v) = each %STAT_RECORD_FROM) {
	like($k, qr/(^[a-z]|[A-Z0-9])[a-z]*$/, "player stat $k is camelCase");
	like($v, qr/^\d{4}$/, 'player stat value is integer');
}
is($REASONABLE_EVENTS{old}, 1,   'at least 1 event in old reports');
is($REASONABLE_EVENTS{new}, 150, 'at least 150 events in new reports');

while (my ($k, $v) = each %PENALTY_POSSIBLE_NO_OFFENDED) {
	like($k, qr/^(\S| )+$/, "penalty $k can have no offended");
	unlike($k, qr/[a-z]/, 'no lowercase');
	is($v, 1, 'just a defined key');
}
while (my ($k, $v) = each %ZERO_EVENT_GAMES) {
	like($k, qr/^\d{9}$/, 'zero event game id key ok');
	is($v, 1, 'event defined');
}

while (my ($k, $v) = each %REVERSE_STAT) {
	like($k, qr/^[A-Z]+$/, "all-caps stat $k is key");
	like($v, qr/^[a-z]+_[a-z]+$/, "snake case stat $v is value");
}

is($LAST_PLAYOFF_GAME_INDEX, 417, 'game 30417 is the last one');
is($LEAGUE_NAME, 'NHL', "We're NHL, right?");
for (1917 .. $CURRENT_SEASON) {
	like(
		get_games_per_season($_),
		$_ == 2004 ? qr/^0$/ : qr/^\d\d$/,
		'# of games ok'
	);
}

for my $span (@PO_SCHEME) {
	like($span->{first}, qr/^\d{4}/, 'po scheme span first is a year');
	like($span->{last},  qr/^\d{4}/, 'po scheme span last is a year');
	like($span->{style}, qr/^(L|D|C)$/, 'style: league/division/conference');
}

is_deeply(\@STAGES, [$REGULAR, $PLAYOFF], 'stages defined');

is($ICING_GOOD    , 1, "icing good is 1 point");
is($ICING_NEUTRAL , 0, "icing neutral is 0 points");
is($ICING_BAD     ,-1, "icing bad is -1 point (modifier?)");
is($ICING_DISASTER,-2, "icing disaster is -2 point (modifier?)");
is($ICING_TIMEOUT ,30, "icing timeout is 30");

while (my ($k, $v) = each %LOCATION_ALIAS) {
	like(
		$v,
		qr/(^0$|\S+\s+\S+)/,
		"$k location alias is either 0 or another location - in the db"
	);
}

use Data::Dumper;

while (my ($k, $v) = each %SEASONS) {
	$k =~ /^(\d{4})_(\d{4})$/;
	ok($1, "span $k start year $1 ok");
	ok($2, "span $k finish year $2 ok");
	ok($2 >= $1, "finish is not smaller than start");
	isa_ok($v, 'HASH', 'League level ok');
	while (my ($k1, $v1) = each %{$v}) {
		isa_ok($v, 'HASH', 'Conference level ok');
		while (my ($k2, $v2) = each %{$v1}) {
			isa_ok($v2, 'ARRAY', 'Division level ok');
			for my $t (@{$v2}) {
				like($t, qr/^[A-Z]{3}$/, 'teams in divison');
			}
		}
	}
}
