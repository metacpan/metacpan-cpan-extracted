#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More tests => 827;

use Sport::Analytics::NHL;
use Sport::Analytics::NHL::Normalizer;
use Sport::Analytics::NHL::Tools;
use Storable qw(retrieve dclone);


my $period = [{}];
my $event = {
	stage => 2, season => 2002, game_id => 200220002,
};
Sport::Analytics::NHL::Normalizer::insert_pstr($period, 1, $event);
is_deeply(
	$period->[0],
	{
		ts => 0, period => 1, time => '00:00', type => 'PSTR',
		stage => 2, season => 2002, game_id => 200220002,
	},
	'pstr inserted',
);
Sport::Analytics::NHL::Normalizer::insert_pend($period, 1, $event, 0);
is_deeply(
	$period->[-1],
	{
		ts => 1200, period => 1, time => '20:00', type => 'PEND',
		stage => 2, season => 2002, game_id => 200220002,
	},
	'pend inserted',
);
$event->{ts} = 2350;
$event->{time} = '19:10';
$event->{stage} = 3;

Sport::Analytics::NHL::Normalizer::insert_pend($period, 4, $event, 1);
is_deeply(
	$period->[-1],
	{
		ts => 2350, period => 4, time => '19:10', type => 'PEND',
		stage => 3, season => 2002, game_id => 200220002,
	},
	'pend inserted by last event',
);

$event->{stage} = 2;
Sport::Analytics::NHL::Normalizer::insert_pend($period, 5, $event, 0);
is_deeply(
	$period->[-1],
	{
		ts => 3900, period => 5, time => '5:00', type => 'PEND',
		stage => 2, season => 2002, game_id => 200220002,
	},
	'pend inserted for shootout',
);
$period = [ grep { $_->{game_id} } @{$period} ];
for my $game_id (201120010,193020010) {
	my @merged = Sport::Analytics::NHL::merge(
		{}, {reports_dir => 't/data/'}, $game_id
	);
	my $boxscore = retrieve $merged[0];

	Sport::Analytics::NHL::Normalizer::normalize_result($boxscore);
	Sport::Analytics::NHL::Normalizer::sort_events($boxscore);
	#print_events($boxscore->{events});
	is($boxscore->{events}[-1]{type}, 'GEND', 'gend at the end');
	is($boxscore->{events}[-2]{type}, 'PEND', 'pend penultimate');
	
	is(scalar(grep{$_->{type} eq 'PSTR'} @{$boxscore->{events}}), 3, '3 pstr');
	is(scalar(grep{$_->{type} eq 'PEND'} @{$boxscore->{events}}), 3, '3 pend');
	is(scalar(grep{$_->{type} eq 'GEND'} @{$boxscore->{events}}), 1, '1 gend');

	for my $e (0..$#{$boxscore->{events}}-1) {
		#	print Dumper $boxscore->{events}[$e];
		cmp_ok(
			$boxscore->{events}[$e]{period},
			'<=',
			$boxscore->{events}[$e+1]{period},
			'period ordered'
		);
		cmp_ok(
			$boxscore->{events}[$e]{ts},
			'<=',
			$boxscore->{events}[$e+1]{ts},
			'ts ordered'
		) if $boxscore->{events}[$e]{period} ==
			$boxscore->{events}[$e+1]{period};
		cmp_ok(
			$Sport::Analytics::NHL::Normalizer::EVENT_PRECEDENCE{
				$boxscore->{events}[$e]{type}
			},
			'<=',
			$Sport::Analytics::NHL::Normalizer::EVENT_PRECEDENCE{
				$boxscore->{events}[$e+1]{type}
			},
			'precedence ordered'
		) if
			$boxscore->{events}[$e]{period} ==
			$boxscore->{events}[$e+1]{period}
			&& $boxscore->{events}[$e]{ts} ==
			$boxscore->{events}[$e+1]{ts};
	}
}

Sport::Analytics::NHL::Normalizer::assign_event_ids($period);

my $e = 1;
for my $event (@{$period}) {
	is($event->{_id}, 2002200020000 + $e, 'event _id correct');
	is($event->{event_id}, $e, 'event event_id correct');
	$e++;
}

