#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More tests => 7;

use Sport::Analytics::NHL::Normalizer;

my $event_summary = {};
my $event = {
	player1 => 1111,
	player2 => 2222,
	assists => [3333, 4444 ],
	t => 0,
};
my $boxscore = { _id => 10, teams => [ {name => 'aa'}, { name => 'bb'} ]};
my $positions = {
	1111 => 'C',
};

Sport::Analytics::NHL::Normalizer::summarize_goal(
	$event_summary, $event, $boxscore, $positions, 1
);
is_deeply(
	$event_summary,
	{
		'1111' => {
			'goals' => 1,
			'shots' => 1,
		},
		'2222' => {
			'shots' => 1,
		},
		'3333' => {
			'assists' => 1,
		},
		'4444' => {
			'assists' => 1,
		},
		'aa' => {
			'score' => 1,
		},
	},
	'Summary created',
);

$event = {
	player1 => 1111,
	player2 => 2222,
	t => 0,
	ts => 10,
};
Sport::Analytics::NHL::Normalizer::summarize_goal(
	$event_summary, $event, $boxscore, $positions, 1
);

is_deeply(
	$event_summary,
	{
		'1111' => {
			'goals' => 2,
			'shots' => 2,
		},
		'2222' => {
			'shots' => 2,
			goalsAgainst => 1,
		},
		'3333' => {
			'assists' => 1,
		},
		'4444' => {
			'assists' => 1,
		},
		'aa' => {
			'score' => 2,
		},
	},
	'Summary updated',
);

$event = {
	player1 => 2222,
	player2 => 5555,
	assists => [ 1111 ],
	t => 1,
	ts => 20,
};
$positions->{2222} = 'G';

Sport::Analytics::NHL::Normalizer::summarize_goal(
	$event_summary, $event, $boxscore, $positions, 1
);

is_deeply(
	$event_summary,
	{
		'1111' => {
			'goals' => 2,
			'shots' => 2,
			assists => 1,
		},
		'2222' => {
			'shots' => 2,
			goalsAgainst => 1,
			g_goals => 1,
			g_shots => 1,
		},
		'3333' => {
			'assists' => 1,
		},
		'4444' => {
			'assists' => 1,
		},
		5555 => {
			shots => 1,
			goalsAgainst => 1,
		},
		'aa' => {
			'score' => 2,
		},
		bb => {
			score => 1,
		}
	},
	'Summary updated',
);

$event = {
	player1 => 1111,
	length => 10,
};

Sport::Analytics::NHL::Normalizer::summarize_penalty(
	$event_summary, $event, 1,
);
is_deeply(
	$event_summary,
	{
		'1111' => {
			'goals' => 2,
			'shots' => 2,
			assists => 1,
			penaltyMinutes => 10,
		},
		'2222' => {
			'shots' => 2,
			goalsAgainst => 1,
			g_goals => 1,
			g_shots => 1,
		},
		'3333' => {
			'assists' => 1,
		},
		'4444' => {
			'assists' => 1,
		},
		5555 => {
			shots => 1,
			goalsAgainst => 1,
		},
		'aa' => {
			'score' => 2,
		},
		bb => {
			score => 1,
		}
	},
	'Summary updated',
);

$event = {
	player1 => 1111,
	length => 10,
	servedby => 3333,
};


$event_summary = {};
Sport::Analytics::NHL::Normalizer::summarize_penalty(
	$event_summary, $event, 1,
);

is_deeply(
	$event_summary,
	{
		'1111' => {
			penaltyMinutes => 10,
		},
		3333 => {
			servedby => 1,
			servedbyMinutes => 10,
		}
	},
	'Summary created from penalty',
);

$event = {
	player1 => 1111,
	player2 => 6666,
	type => 'FAC',
};
Sport::Analytics::NHL::Normalizer::summarize_other_event(
	$event_summary, $event
);
is_deeply(
	$event_summary,
	{
		'1111' => {
			penaltyMinutes => 10,
		},
		3333 => {
			servedby => 1,
			servedbyMinutes => 10,
		},
	},
	'Summary unchanged: no sources',
);
$event->{sources}{PL} = 1;
Sport::Analytics::NHL::Normalizer::summarize_other_event(
	$event_summary, $event
);
is_deeply(
	$event_summary,
	{
		'1111' => {
			penaltyMinutes => 10,
			faceoffTaken => 1,
			faceOffWins => 1,
		},
		3333 => {
			servedby => 1,
			servedbyMinutes => 10,
		},
		6666 => {
			faceoffTaken => 1,
		},
		stats => ['faceoffTaken'],
	},
	'Summary updated for FAC',
);
