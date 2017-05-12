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
strict:                 1
debug:                  0
item_name:              $record
max_stats_to_keep:      500
filter_early:           1
filter: |
  # print STDERR "RECORD: $record\n";
  return 0 if $record =~ /^#/;
  return 0 if $record =~ /^$/;
  return 1;
crossproduct:
  sex:                  3
  age:                  150
  stone:                20
  random:               2
combinations:
  sex:                  1
  age:                  1
  stone:                1
ephemeral0:
  # We are using ephemeral0 to declare the column variables
  name:                 1
  birthday:             ~
  gender:               ~
  number_of_visits:     ~
  weight:               ~
ephemeral:
  # 
  # We are using a fake column in ephemeral to initialize the raw
  # column variables we declared in ephemeral0
  #
  step1: |
     chomp($record);
     ($column_name, $column_birthday, $column_gender, $column_number_of_visits, $column_weight) = split(/\t/, $record);
ephemeral2:
  #
  # We are using ephemeral2 to generate the computed input variables
  #
  age: |
    use Time::ParseDate qw(parsedate);
    my $t = parsedate($column_birthday, NO_RELATIVE => 1, DATE_REQUIRED => 1, WHOLE => 1);
    return undef unless $t;
    return int ((time - $t) / (365.24 * 86400))
  sex: |
    return 'M' if $column_gender =~ /^m/i;
    return 'F' if $column_gender =~ /^f/i;
    return undef;
  hospital_visits: |
    $column_number_of_visits =~ /^(\d+)$/;
    $1
  stone: |
    int($column_weight / 13)
  random: |
    int(rand(3))
keep:
  col_name: $column_name
  col_age: $column_age
  col_sex: $column_sex
  col_hv: $column_hospital_visits
  col_stone: $column_stone
  col_random: $column_random
output:
  sample_size:          $ps->{item_counter}
  names:                join('-',@{$ps->{keep}{col_name}})
median:
  avg_hospital_visits:  $column_hospital_visits
mean:                   
  avg_age:              $column_age
finalize_result: |
  #use Data::Dumper;
  #print Dumper($row, $ps);
  # $suppress_result = 1 if $ps->{item_counter} < 5;
  # skip results when the sample size is < 5 except for the whole sample
END_ACONFIG

my $ag = generate_aggregation_func($aconfig, { 
	name	=> 'Aggregate Hospital Visits',
});

my @results;

for $_ (<DATA>, undef) {
	for my $result ($ag->($_)) {
		push(@results, $result);
	}
}

# print YAML::Dump(\@results);

$finished = 1;

__DATA__
# name<TAB>birthday<TAB>sex<TAB>number of hospital visits in the last year
Fred	Feb 6, 1982	male	0	170
Janet	Mar 10, 1973	female	7	140
Jane	Aug 9, 2001	female	0	103
Jackie	Dec 12, 1923	female	10	98
Jill	Sep 7, 1982	female	2	123
Frank	Jan 27, 1967	male	2	195
Franz	Jul 22, 1993	male	1	232
Ferdinand	Aug 10, 2001	male	2	145
Frodo	Dec 22, 1997	male	12	127

