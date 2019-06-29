#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More tests => 1345;

use Sport::Analytics::NHL::Report;
use Sport::Analytics::NHL::Tools qw(is_noplay_event);

my $report;
$report = Sport::Analytics::NHL::Report->new({
	file => 't/data/2011/0002/0010/BS.json',
});
$report->process();
$report->build_resolve_cache();

isa_ok($report->{resolve_cache}, 'HASH');

my $p = 0;

for my $team (keys %{$report->{resolve_cache}}) {
	like($team, qr/^\S{3}$/, 'team code ok');
	for my $number (keys %{$report->{resolve_cache}{$team}}) {
		if ($number eq 'names') {
			isa_ok($report->{resolve_cache}{$team}{$number}, 'ARRAY');
			for (@{$report->{resolve_cache}{$team}{$number}}) {
				isa_ok($_, 'REF');
			}
			next;
		}
		like($number, qr/^\d{1,2}$/, 'valid jersey number');
		isa_ok($report->{resolve_cache}{$team}{$number}, 'REF');
		like(${$report->{resolve_cache}{$team}{$number}}->{_id}, qr/^8\d{6}/, 'player id expected');
		$p++;
	}
}
is($p, 38, 'two 19-men rosters');

$report->set_event_extra_data();
for my $event (@{$report->{events}}) {
	is_deeply($event->{sources}, {BS=>1}, 'boxscore source set');
	like($event->{player1}, qr/^8\d{6}/, 'player1 ok') unless is_noplay_event($event);
	is($event->{t}, 0, 't correct') if $event->{team1} && $event->{team1} eq 'TBL';
	is($event->{t}, 1, 't correct') if $event->{team1} && $event->{team1} eq 'BOS';
	is($event->{t}, -1, 't correct') unless $event->{team1};
	like($event->{ts}, qr/^\d{1,5}/, 'timestamp a number');
}
