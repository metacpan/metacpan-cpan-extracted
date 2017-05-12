#!/usr/bin/perl
#Copyright 2007 Arthur S Goldstein
use Test::More tests => 2;
use Carp;
BEGIN { use_ok('Parse::Stallion') };

use strict;

sub split_time {
  my $time = shift || time;
  my ($seconds, $minutes, $hour, $mday, $month, $year) = localtime($time);
  return {year => $year + 1900, month => $month+1, mday => $mday,
   hour => $hour, minutes => $minutes, seconds => $seconds};
}

my %full_months = (
january => 1,
february => 2,
march => 3,
april => 4,
may => 5,
june => 6,
july => 7,
august => 8,
september => 9,
october => 10,
november => 11,
december => 12,
);
my %abbreviated_months = (
jan => 1,
feb => 2,
mar => 3,
apr => 4,
may => 5,
jun => 6,
jul => 7,
aug => 8,
sep => 9,
oct => 10,
nov => 11,
dec => 12,
);

my %days_in_month = (
  1 => 31,
  3 => 31,
  4 => 30,
  5 => 31,
  6 => 30,
  7 => 31,
  8 => 31,
  9 => 30,
  10 => 31,
  11 => 30,
  12 => 31,
);

sub valid_mday {
  my ($mday, $month, $year) = @_;
#print STDERR "trying to validate $mday and $month and $year\n";
  if ($month == 2) {
    my $is_leap_year = 0;
    my $leap_year = $year % 4;
    if ($leap_year) {
      my $not_leap_year = $year % 100;
      if ($not_leap_year) {
        my $leap_year = $year % 400;
        if ($leap_year) {
          $is_leap_year = 1;
        }
      }
      else {
        $is_leap_year = 1;
      }
    }
    return ((1 <= $mday) && ($mday <= $28 + $is_leap_year));
  }
  return ((1 <= $mday) && ($mday <= $days_in_month{$month}));
}

my %keywords = (
  when => 'when',
  what => 'details',
  details => 'details',
  where => 'where',
  location => 'where',
);

my %event_rules = (

event => 
  A('event_detail', L(qr/\z/),
  E(sub {
#use Data::Dumper;
  #print STDERR "parms in ".Dumper(\@_)."\n";
  #print STDERR "hoo\n";
   return $_[0]->{event_detail}})
),

event_detail => M(
  'event_detail_item',
  E(sub {
    my $parameters = shift;
    my %detail;
#use Data::Dumper;
  #print STDERR "parms out ".Dumper($parameters)."\n";
#print STDERR "edi\n";
    if (defined $parameters->{event_detail_item}) {
#print STDERR "defined\n";
      foreach my $i (@{$parameters->{event_detail_item}}) {
        $detail{$i->{keyword}} = $i->{information};
      }
    }
#print STDERR "detail back is ".Dumper(\%detail)."\n";
    return \%detail;
  })
),

event_detail_item => A(
  'keyword', 'separator', 'information'
),

separator => L(qr/\s*\:\s*/),

keyword => L(
  qr/\w+/,
  E(sub {
    my $word = shift;
    if (defined $keywords{lc $word}) {
      return $keywords{lc $word};
    }
    else {
      return (undef, 1);
    }
  }),
),

any_char => L(
  qr/./s
),

information => M(
  'any_char', MATCH_MIN_FIRST(), E(
  sub {
#use Data::Dumper; print STDERR "information is ".Dumper(\@_)."\n";
    my $param = shift;
    if ($param->{any_char}) {return join ('',@{$param->{any_char}})};
  })
),

);


use Parse::Stallion;
my $event_parser = new Parse::Stallion(
 \%event_rules,
  { start_rule => 'event',
 do_evaluation_in_parsing => 1,
});

my $event_in = 'when: yesterday
what: nothing';

my $result = $event_parser->parse_and_evaluate($event_in);
#use Data::Dumper;
#print STDERR "Results out ".(Dumper($ne_result))."\n";
#foreach my $tr (@{$result->{parse_trace}}) {
#  print STDERR "tr is now ".Dumper($tr)."\n";
#};
#my $result = $event_parser->do_tree_evaluation($ne_result);
#print STDERR "result is ".Dumper($result)."\n";

is_deeply ($result, {
          'when' => 'yesterday
',
          'details' => 'nothing'
        }, 'event break down');

1;
