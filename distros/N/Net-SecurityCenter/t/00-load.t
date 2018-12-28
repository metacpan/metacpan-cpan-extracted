#!perl -T

use strict;
use warnings;
use Test::More;

require_ok('Net::SecurityCenter::REST');

done_testing();

diag("Net::SecurityCenter::REST $Net::SecurityCenter::REST::VERSION, Perl $], $^X");
