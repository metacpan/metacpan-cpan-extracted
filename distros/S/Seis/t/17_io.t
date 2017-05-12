use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

ok compile('"t".IO ~~ :d');
ok !compile('"t".IO !~~ :d');
ok !compile('"not-existed-directory-name".IO ~~ :d');

done_testing;

