#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 2;

use_ok("Netflow::Parser");

diag("Testing Netflow::Parser $Netflow::Parser::VERSION, Perl $], $^X");

is($Netflow::Parser::VERSION, "0.06.002", "version");
