#!/usr/bin/perl


use lib '../lib';

use strict;
use warnings;

use Test::More tests => 1;

my @modules = qw(
  Exporter
);

foreach my $module (@modules) {
    eval " use $module ";
    ok(!$@, "$module compiles");
}

1;
