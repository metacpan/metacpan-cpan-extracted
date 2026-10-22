#!perl -T

use strict;
use warnings;

use Test::More;

my @CLASSES = qw(
    Net::ADB
    Net::ADB::Device
    Net::ADB::Shell::Result
    Net::ADB::Util
);

use_ok($_) for @CLASSES;

done_testing();

diag("Net::ADB $Net::ADB::VERSION, Perl $], $^X");
