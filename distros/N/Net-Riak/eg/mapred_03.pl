#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use Net::Riak;

my $riak = Net::Riak->new();

my $result =
  $riak->add('goog')->map(map_max_daily_variance())
  ->reduce(reduce_max_daily_variance())->run;
say "max daily variance";
map { say $_ . " => ". $result->[0]->{$_} } sort {$a cmp $b} keys %{$result->[0]};

sub map_max_daily_variance {
    "
function(value, keyData, arg){
  var data = Riak.mapValuesJson(value)[0];
  var month = value.key.split('-').slice(0,2).join('-');
  var obj = {};
  obj[month] = data.High - data.Low;
  return [ obj ];
}
";
}

sub reduce_max_daily_variance {
    "
function(values, arg){
  return [ values.reduce(function(acc, item){
             for(var month in item){
                 if(acc[month]) { acc[month] = (acc[month] < item[month]) ? item[month] : acc[month]; }
                 else { acc[month] = item[month]; }
             }
             return acc;
            })
         ];
}
";
}

