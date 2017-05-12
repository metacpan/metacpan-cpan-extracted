#!/usr/bin/perl -w
use strict;
use Test;

BEGIN {
 plan tests => 1;
}

eval{require Mobile::UserAgentFactory;};
ok($@ ? 0 : 1);
