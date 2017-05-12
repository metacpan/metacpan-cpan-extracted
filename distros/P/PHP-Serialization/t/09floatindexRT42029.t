#!/usr/bin/env perl
use strict;
use warnings;

use PHP::Serialization;
use Test::More tests => 1;

my $hash = { 'Volkswagen' => { 'Touareg' => { '2.5' => 1 } }, };

my $str = PHP::Serialization::serialize($hash);

is($str,'a:1:{s:10:"Volkswagen";a:1:{s:7:"Touareg";a:1:{s:3:"2.5";i:1;}}}','Keys are string or int');
