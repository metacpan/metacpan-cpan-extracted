#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use Net::Riak;

my $riak = Net::Riak->new();

my $result = $riak->add('goog')->map(get_day_where_high_is('600.00'))->run;
say "days where high is over 600:";
map { say $_ } sort {$a cmp $b } @$result;

sub get_day_where_high_is {
    my $val = shift;
"
function(value, keyData, arg) {
  var data = Riak.mapValuesJson(value)[0];
  if(data.High && data.High > $val)
    return [value.key];
  else
    return [];
}
";
}
