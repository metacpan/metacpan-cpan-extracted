#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More tests => 1095;

use Sport::Analytics::NHL;
use Sport::Analytics::NHL::Normalizer;
use Storable;

my @merged = Sport::Analytics::NHL::merge({}, {reports_dir => 't/data/'}, 201120010);
my $boxscore = retrieve $merged[0];
my $event_summary = summarize $boxscore;
for my $t (0,1) {
	ok(defined $event_summary->{$boxscore->{teams}[$t]{name}}{score}, 'score defined');
}

for (keys %{$event_summary}) {
	when ('so') { is_deeply($event_summary->{so}, [0,0], 'no shootout'); }
	when (/^\d{7}$/) {
		for my $stat (keys %{$event_summary->{$_}}) {
			ok((grep {$stat eq $_} @{$event_summary->{stats}}), "stat $stat accounted");
			ok(length($event_summary->{$_}{$stat}), "stat has a value");
		}
	}
}
