#! /usr/bin/perl -wT

use Test::More(tests => 2);
use strict;
use warnings;

eval { require Net::SMS::MessageNet; };
ok($@ eq '', "Loaded Net::SMS::MessageNet:$@");
eval { require Net::HTTPS; };
ok($@ eq '', "Loaded Net::HTTPS:$@");

