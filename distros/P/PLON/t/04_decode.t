use strict;
use warnings;
use utf8;
use Test::More;
use PLON;

is_deeply(PLON->new->decode('[]'), []);
is_deeply(PLON->new->decode('{}'), {});
is_deeply(PLON->new->decode(q!{"a"=>"b"}!), {a => "b"});
is_deeply(PLON->new->decode(q!{"a"=>"b","c" => "d"}!), {a => "b", c => "d"});
is_deeply(PLON->new->decode('[0]'), [0]);
is_deeply(PLON->new->decode('[3.14]'), [3.14]);

done_testing;

