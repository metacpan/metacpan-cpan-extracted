use strict;
use Test::Lib;
use Test::Most tests => 5;
use Example::Construction::Counter;

my $counter = Example::Construction::Counter->new(start => 10);

is $counter->next => 10;
is $counter->next => 11;
is $counter->next => 12;

throws_ok { Example::Construction::Counter->new } qr/Param 'start' was not provided/;
throws_ok { Example::Construction::Counter->new(start => 'abc') } 
          qr/Parameter 'start' failed check 'is_integer'/;
