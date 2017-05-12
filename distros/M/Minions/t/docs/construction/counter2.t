use strict;
use Test::Lib;
use Test::Most tests => 4;
use Example::Construction::Counter_v2;

my $counter = Example::Construction::Counter_v2->new(10);

is $counter->next => 10;
is $counter->next => 11;
is $counter->next => 12;

throws_ok { Example::Construction::Counter_v2->new(start => 'abc') } 
          qr/Parameter 'start' failed check 'is_integer'/;
