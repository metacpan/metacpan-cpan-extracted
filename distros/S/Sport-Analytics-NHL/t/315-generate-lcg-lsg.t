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
plan tests => 36;

use Sport::Analytics::NHL::DB;
#$ENV{HOCKEYDB_DEBUG} = 1;
$ENV{HOCKEYDB_DRYRUN} = 1;
$DB = Sport::Analytics::NHL::DB->new();

my $games_c = $DB->get_collection('games');
my $game = $games_c->find_one(
	{_id => 201830187}
);
my @lcglsg = Sport::Analytics::NHL::Generator::generate_lead_changing_goals($game);
my @lcg = (1,0,0,0,0,1,1,1,1);
my @lsg = (0,0,0,0,0,0,1,0,0);
for my $g (@lcglsg) {
	like($g->{_id}, qr/^\d{13}$/, 'goal id present');
	is($g->{lcg}, shift(@lcg), 'lcg adjudication correct');
	is($g->{lsg}, shift(@lsg), 'lsg adjudication correct');
}
@lcg = (1,1,1), @lsg = (0,0,0);
$game = $games_c->find_one(
	{_id => 201830186}
);
@lcglsg = Sport::Analytics::NHL::Generator::generate_lead_changing_goals($game);
for my $g (@lcglsg) {
	like($g->{_id}, qr/^\d{13}$/, 'goal id present');
	is($g->{lcg}, shift(@lcg), 'lcg adjudication correct');
	is($g->{lsg}, shift(@lsg), 'lsg adjudication correct');
}
