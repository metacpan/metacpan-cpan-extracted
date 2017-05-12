#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use YAML;
use Net::Riak;

my $riak = Net::Riak->new();

my $result = $riak->add('goog')->map(days_where_close_is_lower_than_open())->run;
say "days where close is lower than open";
map { say $_ } sort {$a cmp $b} @$result;

sub days_where_close_is_lower_than_open {
    "
function(value, keyData, arg) {
  var data = Riak.mapValuesJson(value)[0];
  if(data.Close < data.Open)
    return [value.key];
  else
    return [];
}
";
}

