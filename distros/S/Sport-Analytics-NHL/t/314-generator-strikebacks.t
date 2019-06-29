#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';

use Test::More;

use Sport::Analytics::NHL::Generator;
use Sport::Analytics::NHL::Vars  qw($DB $CACHES $MONGO_DB);
use Sport::Analytics::NHL::Util  qw(:debug);
if ($ENV{HOCKEYDB_NODB} || ! $MONGO_DB) {
        plan skip_all => 'Mongo not defined';
        exit;
}
plan tests => 4;

use Sport::Analytics::NHL::DB;
#$ENV{HOCKEYDB_DEBUG} = 1;
$ENV{HOCKEYDB_DRYRUN} = 1;
$DB = Sport::Analytics::NHL::DB->new();

my @goals = ({t => 0}, {t => 0}, {t => 0});
is(Sport::Analytics::NHL::Generator::check_strikeback(0, @goals), 0, 'no strikeback');
is(Sport::Analytics::NHL::Generator::check_strikeback(1, @goals), 3, 'a strikeback');

my $games_c = $DB->get_collection('games');
my $game = $games_c->find_one(
	{_id => 201830187}
);
is_deeply(
	Sport::Analytics::NHL::Generator::generate_strikebacks($game),
	{
		winner => 'SJS',
		loser  => 'VGK',
		size   => 3,
	},
	'strikeback detected',
);
$game = $games_c->find_one(
	{_id => 201830186}
);
is(
	Sport::Analytics::NHL::Generator::generate_strikebacks($game),
	0, 'no strikeback'
);
