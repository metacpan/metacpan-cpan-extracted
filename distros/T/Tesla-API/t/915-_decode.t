use warnings;
use strict;

use Data::Dumper;
use Tesla::API;
use Test::More;

my $t = Tesla::API->new(unauthenticated => 1);

my $j = '{"a" : 99}';

my $p = $t->_decode($j);

is $p->{a}, 99, "_decode() does the right thing ok";

done_testing();