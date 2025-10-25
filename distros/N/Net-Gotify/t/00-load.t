#!perl

use strict;
use warnings;

use Test::More;

use_ok('Net::Gotify');

done_testing();

diag("Net::Gotify $Net::Gotify::VERSION, Perl $], $^X");
