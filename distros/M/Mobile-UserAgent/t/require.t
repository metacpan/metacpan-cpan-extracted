#!/usr/bin/perl -w
use strict;
use Test;

BEGIN {
 plan tests => 1;
}

eval{require Mobile::UserAgent;};
ok($@ ? 0 : 1);
