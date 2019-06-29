#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';

use Test::More;

use Sport::Analytics::NHL::Generator;
use Sport::Analytics::NHL::Vars  qw($DB $CACHES $MONGO_DB);
use Sport::Analytics::NHL::Util  qw(:debug);
use Sport::Analytics::NHL::Tools  qw(get_catalog_map get_game_coords_adjust);
if ($ENV{HOCKEYDB_NODB} || ! $MONGO_DB) {
        plan skip_all => 'Mongo not defined';
        exit;
}
plan tests => 704;

use Sport::Analytics::NHL::DB;
#$ENV{HOCKEYDB_DEBUG} = 1;
$ENV{HOCKEYDB_DRYRUN} = 1;
$DB = Sport::Analytics::NHL::DB->new();

my $games_c = $DB->get_collection('games');
my $game = $games_c->find_one(
	{_id => 201830125}
);

my $chl = { _id => 10 };
is(Sport::Analytics::NHL::Generator::process_broken_challenge($chl, undef, $game), 1, 'not broken');
is(Sport::Analytics::NHL::Generator::process_broken_challenge({_id => 2016204380148}, undef, $game), 0, 'invalid');
my $challenge = {};
$chl = { _id => 2015206730339, ts => 10};
is(Sport::Analytics::NHL::Generator::process_broken_challenge($chl, $challenge, $game), 0, 'broken');
is($challenge->{ts}, $chl->{ts}, 'ts inherited');
is($challenge->{type}, 'o', 'type acquired');
my @s_n_c = Sport::Analytics::NHL::Generator::get_stops_and_challenges($game->{_id});
#dumper \@s_n_c;
is(scalar(@s_n_c), 5, 'five events found');
$challenge = {};
my @rs = (1,0,0,0,1);
my $zones = get_catalog_map('zones');
my $z = get_game_coords_adjust($game, $zones);

my @ch = (
	{ t => -1, result => -1, winner => 'TOR', loser => 'BOS', type => 'x', coach => 'NHL', source => 'STOP' },
	{ t =>  1, result =>  0, winner => 'TOR', loser => 'BOS', type => 'i', source => 'CHL' },
	{ t => -1, result => -1, winner => 'BOS', loser => 'TOR', type => 'x', coach => 'NHL', source => 'STOP' },
);
for my $chl (@s_n_c) {
	my $r = Sport::Analytics::NHL::Generator::process_stop_challenge($chl, $challenge);
	is($r, shift @rs, 'expected return value');
	if ($r && $chl->{type} eq 'STOP') {
		ok(defined $chl->{t}, 'chl t defined');
	}
	next if ! $r && $chl->{type} eq 'STOP';
	$challenge = {};
	Sport::Analytics::NHL::Generator::configure_challenge($challenge, $chl, $game, $z);
	my $exch = shift @ch;
	#dumper $challenge;
	for my $f (keys %{$challenge}) {
		next if $f eq 'coach' && ! exists $exch->{$f};
		is($challenge->{$f}, exists $exch->{$f} ? $exch->{$f} : $chl->{$f}, "field $f populated correctly");
	}
}
my $challenges = Sport::Analytics::NHL::Generator::generate_challenges($game, 1);
is(scalar(@{$challenges}), 3, '3 real challenge events');
is_deeply($challenges, [
          {
            'challenger' => 'NHL',
            'coach' => 'NHL',
            'game_id' => 201830125,
            'loser' => 'BOS',
            'result' => -1,
            'ts' => 1959,
            'type' => 'x',
            'winner' => 'TOR',
          },
          {
            'challenger' => 'BOS',
            'coach' => 'BRUCE CASSIDY',
            'game_id' => 201830125,
            'loser' => 'BOS',
            'result' => 0,
            'ts' => 3093,
            'type' => 'i',
            'winner' => 'TOR',
          },
          {
            'challenger' => 'NHL',
            'coach' => 'NHL',
            'game_id' => 201830125,
            'loser' => 'TOR',
            'result' => -1,
            'ts' => 3556,
            'type' => 'x',
            'winner' => 'BOS',
          },
        ], 'expected challenges');

