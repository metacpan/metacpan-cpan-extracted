use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

is compile(q!eval '"a" ~ "b"'!), 'ab';
is compile(q!eval '"a" . "b"', :lang<perl5>!), 'ab';
ok !compile(q/try { 0 }; defined $!/);
ok compile(q/try { die }; defined $!/);

done_testing;

