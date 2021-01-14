use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok('Symbol::Approx::Sub', match => 'String::Approx');

sub aa { 'aa' }

sub test { 'test' }

is(a(), 'aa', 'a() calls aa()');

is(test_it(), 'test', 'test_it() calls test()');

throws_ok { zzz_not_there() } qr/^REALLY/, 'Correct exception thrown';

done_testing;
