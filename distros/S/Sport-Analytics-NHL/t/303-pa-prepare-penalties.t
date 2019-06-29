#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Storable qw(dclone);
use Test::More; 

use Sport::Analytics::NHL::PenaltyAnalyzer;
use Sport::Analytics::NHL::Vars qw($DB $MONGO_DB);
use Sport::Analytics::NHL::DB;
use Sport::Analytics::NHL::Test;
use Sport::Analytics::NHL::Util qw(:debug);
use Sport::Analytics::NHL::Tools qw(get_catalog_map);

if ($ENV{HOCKEYDB_NODB} || ! $MONGO_DB) {
        plan skip_all => 'Mongo not defined';
        exit;
}
plan tests => 52;
$DB = Sport::Analytics::NHL::DB->new();
my $PENL_c = $DB->get_collection('PENL');
my $penalty_names = get_catalog_map('penalties');

my $p;
my $_p = {};

$p = dclone $_p;
my $p10 = { length => 10 };
my $_p10 = dclone $p10;
Sport::Analytics::NHL::PenaltyAnalyzer::stack_penalties($p10, $p);
is_deeply($p,   $_p, 'no stack on 10');
is_deeply($p10, $_p10, '10 not stacked');
my $p0 = {	length => 0, };
my $_p0 = dclone $p0;
Sport::Analytics::NHL::PenaltyAnalyzer::stack_penalties($p0, $p);
is_deeply($p, $_p, 'no stack on 0');
is_deeply($p0, $_p0, '0 not stacked');
my $p5 = { link => 1, length => 5 };
my $_p5 = dclone $p5;
Sport::Analytics::NHL::PenaltyAnalyzer::stack_penalties($p5, $p);
is_deeply($p, $_p, 'no stack on link');
is_deeply($p5, $_p5, 'link not stacked');
delete $p5->{link};
$p5->{begin} = 10;
$p->{end}    = 5;
$_p = dclone $p;
$_p5 = dclone $p5;

Sport::Analytics::NHL::PenaltyAnalyzer::stack_penalties($p5, $p);
is_deeply($p, $_p, 'no stack on begin/end');
is_deeply($p5, $_p5, 'begin/end not stacked');

delete $p5->{begin};
delete $p->{end};
$p->{begin} = 10;
$p->{length} = 2;
$p->{player1} = 10;
$p->{length} = 5;
$p->{_id} = 1;
$p->{t} = 1;
$p5->{_id} = 2;
$p5->{player1} = 10;
$p5->{t} = 1;
$_p = dclone $p;
$_p5 = dclone $p5;

Sport::Analytics::NHL::PenaltyAnalyzer::stack_penalties($p5, $p);
is($p5->{begin}, 310, 'begin stack correct');
is_deeply($p5->{link}, $p, 'link stack correct');
is($p5->{end}, 610, 'end stack correct');
is($p->{end}, 310, 'end previous correct');
is($p->{linked_id}, $p5->{_id}, 'linked id stack correct');
is_deeply($p->{linked}, $p5, 'linked stack correct');
$p->{length} = 2;
$p5->{length} = 2;
delete $p->{end};
Sport::Analytics::NHL::PenaltyAnalyzer::stack_penalties($p5, $p, 1);
is($p5->{begin}, 130, 'begin stack correct');
is_deeply($p5->{link}, $p, 'link stack correct');
is($p5->{end}, 250, 'end stack correct');
is($p->{end}, 130, 'end previous correct');
is($p->{linked_id}, $p5->{_id}, 'linked id stack correct');
is_deeply($p->{linked}, $p5, 'linked stack correct');
ok($p->{double}, 'double minor detected');

delete $p->{link};
delete $p->{double};
my $penalties = [$p];

Sport::Analytics::NHL::PenaltyAnalyzer::split_double_minor($p, $penalties, 1);
is(scalar @{$penalties}, 2, 'penalty split');
is($penalties->[-1]{_id}, 10, 'penalty pseudo id added');
ok($p->{double}, 'double set');

$penalties = [{
	player1 => 1,
	begin => 10,
	end => 130,
}];
$p = {
	player1 => 1,
	ts => 70,
};
my @same = Sport::Analytics::NHL::PenaltyAnalyzer::check_multiple_penalties_by_player($p, $penalties);
is(scalar(@same), 1, 'same found');
$p->{player1} = 2;
@same = Sport::Analytics::NHL::PenaltyAnalyzer::check_multiple_penalties_by_player($p, $penalties);
is(scalar(@same), 0, 'same NOT found');

my $pbox = [];
$Sport::Analytics::NHL::PenaltyAnalyzer::CACHE = {2 => 'G'},
$penalties = [{
	player1 => 1,
	length  => 4,
	t       => 1,
	_id     => 1,
	ts      => 10,
	penalty => $penalty_names->{SLASHING},
	description => 'xjxjxj',
}, {
	player1 => 2,
	ts => 1000,
	_id => 2,
	t       => 1,
	length => 2,
	penalty => $penalty_names->{HOLDING},
	description => 'xjxjxj',
}, {
	player1 => 3,
	ts => 2000,
	t       => 1,
	length => 10,
	_id => 3,
	penalty => $penalty_names->{MISCONDUCT},
	description => 'MISCONDUCT',
}];
Sport::Analytics::NHL::PenaltyAnalyzer::prepare_penalties(
	$penalty_names, $penalties, $pbox
);
is($penalties->[-1]{end}, 1999, '10 penalty is not on the clock');
is($penalties->[-1]{expired}, 1, '10 penalty never on the clock');
is($penalties->[-1]{begin}, 2000, 'begin set');
ok(! $penalties->[-1]{linked_id}, 'linked id blank');
ok(! $penalties->[-1]{double}, 'not a double');

is($penalties->[-2]{end}, 1120, 'penalty ends in 120 sec');
ok(!defined $penalties->[-2]{expired}, 'expiration not defined');
is($penalties->[-2]{begin}, 1000, 'begin set');
ok(! $penalties->[-2]{linked_id}, 'linked id blank');
ok(! $penalties->[-2]{double}, 'not a double');

is(scalar(@{$penalties}), 4, 'double split successfully');

is($penalties->[1]{end}, 250, 'penalty is stacked on the clock');
ok(! defined $penalties->[1]{expired}, 'expiration not yet defined');
is($penalties->[1]{begin}, 130, 'begin set to stack');
is($penalties->[1]{length}, 2, 'length set');
is($penalties->[1]{_id}, 10, 'extra id set');
is($penalties->[1]{link}, $penalties->[0], 'link set');
ok(! $penalties->[1]{linked_id}, 'linked id blank');
ok(! $penalties->[1]{double}, 'not a double');

is($penalties->[0]{end}, 130, 'penalty is on the clock');
is($penalties->[0]{expired}, undef, 'expiration not yet defined');
is($penalties->[0]{begin}, 10, 'begin set to ts');
is($penalties->[0]{length}, 2, 'length adjusted');
is($penalties->[0]{linked}, $penalties->[1], 'linked set');
is($penalties->[0]{linked_id}, $penalties->[1]{_id}, 'linked id correct');
ok($penalties->[0]{double}, 'a double');
#dumper $penalties;
