#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't/lib';
use Test::More;
use Local::Helpers;

use Net::RCON::Minecraft;

# Not looking for every possible valid and invalid combination,
# just \n and \r\n.

is cmd(newline => "Foo\nBar"),      "Foo\nBar",   '\n accepted';
is cmd(newline => "Foo\r\nBar"),    "Foo\nBar",   '\r\n accepted';
is cmd(newline => "Foo\r\n\r\nBar"),"Foo\n\nBar", '\r\n\r\n accepted';

done_testing;
