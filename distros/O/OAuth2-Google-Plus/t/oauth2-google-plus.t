#! /usr/bin/perl
use FindBin;
use lib "$FindBin::Bin/./lib";

use Test::OAuth2::Google::Plus;

# run all the test methods in Example::Test
Test::OAuth2::Google::Plus->runtests;