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
plan tests => 704;

use Sport::Analytics::NHL::DB;
#$ENV{HOCKEYDB_DEBUG} = 1;
$ENV{HOCKEYDB_DRYRUN} = 1;
$DB = Sport::Analytics::NHL::DB->new();

my $games_c = $DB->get_collection('games');
my $game = $games_c->find_one(
	{_id => 201830181}
);
my $icecounts = Sport::Analytics::NHL::Generator::generate_icecount_mark($game);
my $ic_types = {};
for my $icecount (values %{$icecounts}) {
	ok($icecount >= 3131, 'icecount above 3131');
	ok($icecount <= 6060, 'icecount below 6060');
	$ic_types->{$icecount} = 1;
}
is_deeply(
	[ sort keys %{$ic_types} ],
	[3131, 3141, 4141, 4151, 5141, 5151, 5160, 6051 ],
	'different ice counts',
);
$game = $games_c->find_one(
	{_id => 198020004}
);
$icecounts = Sport::Analytics::NHL::Generator::generate_icecount_mark($game);
for my $icecount (values %{$icecounts}) {
	ok($icecount >= 13131, 'icecount above 3131 with prefix');
	ok($icecount <= 16060, 'icecount below 6060 with prefix');
}
my $ic = (sort values %{$icecounts})[-1];
is($ic,  16051, 'en caught');
