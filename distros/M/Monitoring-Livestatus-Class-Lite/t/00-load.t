#!/usr/bin/perl

use Test::More (tests => 1);

BEGIN {
    use_ok('Monitoring::Livestatus::Class::Lite');
}

diag("Testing Monitoring::Livestatus::Class::Lite $Monitoring::Livestatus::Class::Lite::VERSION, Perl $], $^X");
