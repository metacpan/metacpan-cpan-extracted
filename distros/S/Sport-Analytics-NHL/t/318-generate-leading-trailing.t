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
plan tests => 7;

use Sport::Analytics::NHL::DB;
#$ENV{HOCKEYDB_DEBUG} = 1;
$ENV{HOCKEYDB_DRYRUN} = 1;
$DB = Sport::Analytics::NHL::DB->new();

my $games_c = $DB->get_collection('games');
my $game = $games_c->find_one(
	{_id => 201830187}
);

my $lt = {};
for my $delta (-1, 0, 1) {
	Sport::Analytics::NHL::Generator::apply_leading_trailing($lt, $delta, 10+$delta, $game);
}
is_deeply($lt, { tied => 10, leading => {VGK => 9, SJS => 11}});
$lt = Sport::Analytics::NHL::Generator::generate_leading_trailing($game);
ok($lt->{tied} > 1500, 'more than 25 minutes tied');
ok($lt->{leading}{VGK} > 2400, 'more than 40 minutes VGK ahead');
ok($lt->{leading}{SJS} < 600, 'less than 10 minutes SJS ahead');
is($lt->{leading}{VGK}, $lt->{trailing}{SJS}, 'leading VGK = trailing SJS');
is($lt->{leading}{SJS}, $lt->{trailing}{VGK}, 'leading SJS = trailing VGK');
is($lt->{tied} + $lt->{leading}{VGK} + $lt->{leading}{SJS}, $game->{length}, 'time accounted');
