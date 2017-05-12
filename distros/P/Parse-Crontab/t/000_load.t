#!perl -w
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok 'Parse::Crontab';
}

diag "Testing Parse::Crontab/$Parse::Crontab::VERSION";
