#!perl -w
use strict;
use if $] < 5.010, 'Test::More' => skip_all
    => 'This test depends on a new warnings::enabled() behaviour';
use Test::More;
use t::lib::Foo;

use warnings FATAL => 'all';

is add(x => 1, y => 2), 3;

my $file = quotemeta __FILE__;
my $line;
eval { add( x => 1, y => 2, z => 3 ) }; $line = __LINE__;
like $@, qr/unknown arguments: z .*at $file line $line/sm;

eval { add(x => 1) }; $line = __LINE__;
like $@, qr/missing mandatory parameter named '\$y'.*at $file line $line/sm;
note $@;

eval { add(x => 1, y => 'foo') }; $line = __LINE__;
like $@, qr/Validation failed for 'Num' with value foo.*at $file line $line/sm;

done_testing;

