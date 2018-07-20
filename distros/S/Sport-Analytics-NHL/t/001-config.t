#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;
plan tests => 201;

use Sport::Analytics::NHL::Config;

ok(defined $FIRST_SEASON,    'first season defined');
ok(scalar(@LOCKOUT_SEASONS), 'lockout seasons defined');

my $first = 0;
for my $doc (keys %FIRST_REPORT_SEASONS) {
	ok($FIRST_REPORT_SEASONS{$doc}, 'first season for each report defined');
	like($FIRST_REPORT_SEASONS{$doc}, qr/^\d{4}$/, 'each season is a YYYY');
	$first = 1 if $FIRST_REPORT_SEASONS{$doc} == $FIRST_SEASON;
}
ok($first, "a doc traces to $FIRST_SEASON");

ok(defined $MAIN_GAME_FILE,      'main game file defined');
ok(defined $SECONDARY_GAME_FILE, 'secondary game file defined');

ok(defined $REGULAR, 'regular stage defined');
ok(defined $PLAYOFF, 'playoff stage defined');

for my $team (keys %TEAMS) {
	like($team, qr/^[A-Z]{3}/, 'team id three digit code');
	for my $key (keys %{$TEAMS{$team}}) {
		if ($key eq 'defunct') {
			like($TEAMS{$team}->{$key}, qr/^0|1$/, 'defunct is 0 or 1');
		}
		else {
			isa_ok($TEAMS{$team}->{$key}, 'ARRAY', 'a list of alternative names for teams');
		}
	}
}
