#!/usr/bin/env perl
use lib qw(lib);
use Test::More;
plan tests => 2;
use_ok('POE::Component::TFTPd');
use_ok('POE::Component::TFTPd::Client');
