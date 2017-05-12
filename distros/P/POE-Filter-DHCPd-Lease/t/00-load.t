#!/usr/bin/env perl
use lib qw(lib);
use Test::More;
plan tests => 1;
use_ok('POE::Filter::DHCPd::Lease');
