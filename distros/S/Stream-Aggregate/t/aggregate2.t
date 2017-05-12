#!/usr/bin/perl 

use strict;
use warnings;
use Test::More qw(no_plan);
use YAML;
use Stream::Aggregate;
use Stream::Aggregate::Random;
use List::Util qw(sum);

srand(10);

my $finished = 0;

END { ok($finished, 'finished') }

my $aconfig = Load(<<'END_ACONFIG');
debug:                  0
strict:                 1
item_name:              $shoe
max_stats_to_keep:      4
crossproduct:
  style:                10
  size:                 3
  color:                5
simplify:
  color:                return 'black'
ephemeral:
  style:                $shoe->{style}
  size:                 $shoe->{size}
  color:                $shoe->{color}
min:
  min_discount:         $shoe->{discount}
max:
  max_price:            $shoe->{price}
output:
  number_sold:          $ps->{item_counter}
mean:
  averge_price:         $shoe->{price}
median:
  avg_discount:         $shoe->{price} / ( 100 - $shoe->{discount} ) * 100 * $shoe->{discount} / 100
END_ACONFIG

my $ag = generate_aggregation_func($aconfig, { 
	name	=> 'JobName',
});


my $number_sold = 0;
my $result_sum = 0;
my %results;
for $_ (<DATA>, undef) {
	my $shoe;
	if (defined $_) {
		chomp;
		my %log = map { split(/:/, $_, -1) } split(/\t/, $_);
		$shoe = \%log;
		$number_sold++;
	}
	for my $result ($ag->($shoe)) {
		die if $_;
		die if $results{$result->{style}}{$result->{color}}{$result->{size}};
		$result_sum += $result->{number_sold};
		$results{$result->{style}}{$result->{color}}{$result->{size}} = $result;
	}
}

# print YAML::Dump(\%results);

is($result_sum, $number_sold);
is($results{dots}{grey}{7}{max_price}, 87);
is($results{solid}{red}{7}{max_price}, 57);
is($results{wing}{brown}{7}{number_sold}, 3);

$finished = 1;

__DATA__
style:wing	size:7	color:brown	price:47	discount:15
style:wing	size:7	color:brown	price:57	discount:10
style:wing	size:7	color:brown	price:37	discount:10
style:wing	size:8	color:brown	price:47	discount:20
style:wing	size:8	color:grey	price:37	discount:15
style:wing	size:7	color:grey	price:37	discount:10
style:wing	size:7	color:grey	price:37	discount:15
style:wing	size:7	color:grey	price:57	discount:15
style:wing	size:7	color:grey	price:57	discount:10
style:wing	size:7	color:grey	price:57	discount:10
style:dots	size:7	color:grey	price:47	discount:10
style:dots	size:8	color:grey	price:37	discount:20
style:dots	size:7	color:grey	price:37	discount:20
style:dots	size:8	color:grey	price:47	discount:20
style:dots	size:7	color:grey	price:47	discount:20
style:dots	size:7	color:grey	price:37	discount:10
style:dots	size:8	color:grey	price:37	discount:10
style:dots	size:7	color:grey	price:87	discount:10
style:dots	size:7	color:grey	price:47	discount:10
style:dots	size:7	color:grey	price:47	discount:10
style:solid	size:7	color:grey	price:37	discount:10
style:solid	size:7	color:grey	price:57	discount:10
style:solid	size:7	color:grey	price:57	discount:15
style:solid	size:8	color:grey	price:47	discount:15
style:solid	size:8	color:green	price:37	discount:25
style:solid	size:7	color:green	price:37	discount:20
style:solid	size:7	color:green	price:47	discount:10
style:solid	size:7	color:green	price:47	discount:10
style:solid	size:8	color:green	price:57	discount:10
style:solid	size:8	color:green	price:37	discount:10
style:solid	size:7	color:green	price:37	discount:10
style:solid	size:7	color:green	price:37	discount:15
style:solid	size:7	color:green	price:47	discount:20
style:solid	size:7	color:green	price:47	discount:20
style:solid	size:7	color:green	price:37	discount:10
style:solid	size:7	color:red	price:37	discount:10
style:solid	size:9	color:red	price:57	discount:10
style:solid	size:10	color:red	price:37	discount:25
style:solid	size:11	color:red	price:37	discount:20
style:solid	size:12	color:red	price:57	discount:10
style:solid	size:3	color:red	price:57	discount:10
style:solid	size:2	color:red	price:37	discount:15
style:solid	size:1	color:red	price:37	discount:10
style:solid	size:4	color:red	price:37	discount:15
style:solid	size:5	color:red	price:47	discount:15
style:solid	size:6	color:red	price:37	discount:15
style:solid	size:7	color:red	price:37	discount:10
style:solid	size:7	color:red	price:57	discount:20
style:solid	size:7	color:red	price:57	discount:20
style:solid	size:7	color:red	price:37	discount:20
style:solid	size:7	color:red	price:47	discount:10
style:solid	size:7	color:red	price:57	discount:20
style:solid	size:7	color:red	price:57	discount:20
style:solid	size:7	color:red	price:37	discount:10
style:solid	size:7	color:red	price:57	discount:25
