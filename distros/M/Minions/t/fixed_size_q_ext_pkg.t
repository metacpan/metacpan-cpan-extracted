use strict;
use Test::Lib;
use Test::Most;
use FixedSizeQueue;

my $q = FixedSizeQueue->new(max_size => 3);

is($q->max_size, 3);

$q->push(1);
is($q->size, 1);

$q->push(2);
is($q->size, 2);

throws_ok { FixedSizeQueue->new() } qr/Param 'max_size' was not provided./;
throws_ok { FixedSizeQueue->new(max_size => 0) } 'Minions::Error::AssertionFailure';

done_testing();
