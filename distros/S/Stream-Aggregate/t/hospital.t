#!/usr/bin/perl 

use strict;
use warnings;
use Stream::Aggregate;
use List::Util qw(sum);
use Test::More qw(no_plan);
use YAML;

my $finished = 0;
END { ok($finished, 'finished') }

my $aconfig = Load(<<'END_ACONFIG');
strict:                 1
debug:                  0
item_name:              $record
max_stats_to_keep:      500
filter_early:           1
filter: |
  # ignore black lines and comments
  return 0 if $record =~ /^#/;
  return 0 if $record =~ /^$/;
  return 1;
crossproduct:
  sex:                  3
  age:                  150
combinations:
  sex:                  1
  age:                  1
ephemeral0:
  #
  # We are using ephemeral0 to declare the column variables
  #
  name:                 ~
  birthday:             ~
  gender:               ~
  number_of_visits:     ~
ephemeral:
  # 
  # We are using a fake column ($column_step1) in ephemeral to initialize 
  # the raw column variables we declared in ephemeral0
  #
  step1: |
     chomp($record);
     ($column_name, $column_birthday, $column_gender, $column_number_of_visits) = split(/\t/, $record);
ephemeral2:
  #
  # We are using ephemeral2 to generate the computed input variables
  #
  age: |
    use Time::ParseDate qw(parsedate);
    my $t = parsedate($column_birthday, NO_RELATIVE => 1, DATE_REQUIRED => 1, WHOLE => 1, GMT => 1);
    return undef unless $t;
    return int ((parsedate('2011-05-01', GMT => 1) - $t) / (365.24 * 86400))
  sex: |
    return 'M' if $column_gender =~ /^m/i;
    return 'F' if $column_gender =~ /^f/i;
    return undef;
  hospital_visits: |
    $column_number_of_visits =~ /^(\d+)$/;
    $1
output:
  sample_size:          $ps->{item_counter}
median:
  avg_hospital_visits:  $column_hospital_visits
mean:                   
  avg_age:              $column_age
finalize_result: |
  #
  # Don't generate result records unless there are at
  # least five items being aggregated.
  #
  $suppress_result = 1 if $ps->{item_counter} < 5;
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

@results = sort { $a->{sample_size} <=> $b->{sample_size} } @results;

# print YAML::Dump(\@results);

my ($age10, $age9F, $M, $age9, $F, $all) = @results;

is($age10->{age}, 10, "age10 result age is 10");
is($age10->{sex}, undef, "age10 result no sex");
is($age10->{sample_size}, 5, "age10 has 5 people");

is($age9F->{age}, 9, "age9F result age is 9");
is($age9F->{sex}, 'F', "age9F - female");
is($age9F->{sample_size}, 7, "age9F has 7 people");

is($M->{sex}, 'M', "M is M");
is($M->{age}, undef, "M age undef");
is($M->{sample_size}, 8, "8 men");

is($age9->{sex}, undef, "age9 sex undef");
is($age9->{age}, 9, "age9 is 9");
is($age9->{sample_size}, 9, "age9 has 9");

is($F->{sex}, 'F', "F is F");
is($F->{age}, undef, "F age undef");
is($F->{sample_size}, 13, "13 women");

is($all->{sex}, undef, "all sex undef");
is($all->{age}, undef, "all age undef");
is($all->{sample_size}, 21, "all has 21");

$finished = 1;

__DATA__
# name<TAB>birthday<TAB>sex<TAB>number of hospital visits in the last year
Fred	Feb 6, 1982	male	0
Janet	Mar 10, 1973	female	7
Jackie	Dec 12, 1923	female	10
Jill	Sep 7, 1982	female	2
Frank	Jan 27, 1967	male	2
Franz	Jul 22, 1993	male	1
Frodo	Dec 22, 1997	male	12
# this set of 5 is enough for an age=10 result
Abby	Feb 18, 2001	female	1
Anne	Mar 21, 2001	female	3
Amy	Dec 14, 2000	female	0
Phil	Sep 1, 2000	male	9
Paul	Sep 28, 2000	male	3
# this set is enough for an age=10 & female result
Jane	Aug 9, 2001	female	0
Ambar	Dec 10, 2001	female	3
Ashley	Aug 8, 2001	female	4
June	Jul 13, 2001	female	6
Andrea	Aug 18, 2001	female	3
Josephine	Jun 3, 2001	female	1
Jennifer	Jun 18, 2001	female	3
Fagin	Jun 11, 2001	male	6
Ferdinand	Aug 10, 2001	male	2
