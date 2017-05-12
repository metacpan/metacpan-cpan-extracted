#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Parse::KeyValue::Shellish qw/parse_key_value/;

my $str    = 'foo=bar buz=q\ ux hoge=(fuga piyo)';
my $parsed = parse_key_value($str);

use Data::Dumper; warn Dumper($parsed);
