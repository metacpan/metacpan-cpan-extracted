#!/usr/bin/perl 

use strict;
use warnings;
use Test::More qw(no_plan);
use YAML;
use Stream::Aggregate;
use Stream::Aggregate::Random;

srand(10);

my $finished = 0;

END { ok($finished, 'finished') }

my $aconfig = Load(<<'END_ACONFIG');
debug:                  0
strict:                 1
item_name:              $glide
max_stats_to_keep:      4
context:                return ($glide->{query}, $glide->{cid} || '')
context2columns:        return (query => $current_context[0], cid => (defined($current_context[1]) ? $current_context[1] : '*'))
preprocess: |
  $glide->{headwind} = 0 unless defined $glide->{headwind};
  $glide->{hang_time} = 0 unless defined $glide->{hang_time};
  $glide->{wingspan} = 0 unless defined $glide->{wingspan};
ephemeral:
  glide_ratio:          defined($glide->{drop}) ? ($glide->{distance} / $glide->{drop}) : 1
sum:
  sum_hang_time:        $glide->{hang_time}
  sum_distance:         $glide->{distance}
mean:
  mean_headwind:        $glide->{headwind}
  mean_distance:        $glide->{distance}
  mean_wingspan:        $glide->{wingspan}
counter:
  odd_distance:         int($glide->{distance})%2 == 1
percentage:
  headwind_over_10:     $glide->{headwind} >= 10 
min:
  min_headwind:         $glide->{headwind}
max:
  max_distance:         $glide->{distance}
  max_glide_ratio:      $column_glide_ratio
output:
  launch_count:         $ps->{item_counter}
median:
  median_distance:      $glide->{distance} 
standard_deviation:
  drop_dev:             $glide->{drop}
  distance_dev:         $glide->{distance}
keep:
  distance:             $glide->{distance}
stat:
  distances:            join('-', sort @{$ps->{keep}{distance}})
  top_dists:            percentile(distance => 85)
  kept_items:           scalar(@{$ps->{keep}{distance}});
END_ACONFIG

my $ag = generate_aggregation_func($aconfig, { 
	name	=> 'JobName',
});

my %results;
for $_ (<DATA>, undef) {
	my $glide;
	if (defined $_) {
		chomp;
		my %log = map { split(/:/, $_, -1) } split(/\t/, $_);
		$glide = \%log;
	}
	for my $result ($ag->($glide)) {
		die if $results{$result->{query}}{$result->{cid}};
		$results{$result->{query}}{$result->{cid}} = $result;
	}
}

is($results{bird}{''}{sum_hang_time}, 113);
is($results{bird}{''}{launch_count}, 9);
is($results{bird}{'*'}{launch_count}, 16);
is($results{bird}{38}{sum_hang_time}, 190);
is(sprintf("%.8f", $results{bird}{''}{mean_distance}), 54.33333333);
is($results{bird}{38}{mean_wingspan}, 23);
is($results{bird}{'*'}{max_distance}, 1570);
is($results{bird}{25}{max_distance}, 1570);
is($results{bird}{38}{max_distance}, 597);
is($results{bird}{''}{min_headwind}, 3);
is($results{bird}{'*'}{min_headwind}, 3);
is($results{bird}{25}{min_headwind}, 20);
is($results{bird}{25}{max_glide_ratio}, 19.625);
is($results{bird}{'*'}{max_glide_ratio}, 19.625);
is($results{bird}{38}{max_glide_ratio}, 4.975);
is($results{bird}{38}{median_distance}, 490);
is($results{bird}{25}{median_distance}, 1530);
is($results{bird}{''}{median_distance}, 55);
is($results{bird}{''}{median_distance}, 55); # somewhat random
is($results{bird}{38}{sum_distance}, 2000); 
is(sprintf("%.8f", $results{bird}{38}{distance_dev}), 63.474404290); 
is($results{bird}{38}{odd_distance}, 4);
is($results{bird}{25}{odd_distance}, 0);
is($results{bird}{25}{distances}, '1520-1530-1570');
is($results{bird}{38}{distances}, '423-473-507-597');
ok($results{bird}{''}{kept_items} < 7); 
ok($results{bird}{''}{kept_items} > 3); 
ok($results{bird}{'*'}{kept_items} < 7); 
ok($results{bird}{'*'}{kept_items} > 3); 
is($results{bird}{38}{headwind_over_10},50); 
is($results{bird}{25}{headwind_over_10},100); 
is($results{bird}{''}{headwind_over_10},0); 
is($results{bird}{'*'}{headwind_over_10},31.25); 
is($results{'something else'}{'*'}{mean_distance}, 45);

$finished = 1;

#use Data::Dumper;
#print Dumper(\%results);

__DATA__
query:bird	cid:38	hang_time:40	distance:423	wingspan:22	headwind:8	drop:120
query:bird	cid:38	hang_time:47	distance:473	wingspan:22	headwind:5	drop:120
query:bird	cid:38	hang_time:51	distance:597	wingspan:24	headwind:11	drop:120
query:bird	cid:38	hang_time:52	distance:507	wingspan:24	headwind:10	drop:120
query:bird	cid:25	hang_time:320	distance:1530	wingspan:20	headwind:22	drop:80
query:bird	cid:25	hang_time:350	distance:1520	wingspan:20	headwind:21	drop:80
query:bird	cid:25	hang_time:380	distance:1570	wingspan:22	headwind:20	drop:80
query:bird	cid:	hang_time:10	distance:50	wingspan:14	headwind:3	drop:15
query:bird	cid:	hang_time:11	distance:52	wingspan:14	headwind:3	drop:15
query:bird	cid:	hang_time:11	distance:53	wingspan:14	headwind:3	drop:15
query:bird	cid:	hang_time:12	distance:53	wingspan:14	headwind:3	drop:15
query:bird	cid:	hang_time:12	distance:54	wingspan:14	headwind:3	drop:15
query:bird	cid:	hang_time:12	distance:55	wingspan:14	headwind:3	drop:15
query:bird	cid:	hang_time:13	distance:56	wingspan:14	headwind:3	drop:15
query:bird	cid:	hang_time:14	distance:57	wingspan:14	headwind:3	drop:15
query:bird	cid:	hang_time:18	distance:59	wingspan:14	headwind:4	drop:15
query:something else	distance:45
