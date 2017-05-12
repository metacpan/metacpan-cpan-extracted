#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;
use 5.010;
my $str = "세글자";

say length ($str);
$str=~/(..)/;

my @arr = split(/(.{1})/,$str);
say $arr[0];
