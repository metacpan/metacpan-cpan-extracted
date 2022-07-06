#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Regexp::From::String qw(str_to_re);

is_deeply(str_to_re('foo'), 'foo');
is_deeply(str_to_re('/foo'), '/foo');
is_deeply(str_to_re('qr(foo'), 'qr(foo');
is_deeply(str_to_re('qr|foo|'), 'qr|foo|');
is_deeply(str_to_re('qr(foo)x'), 'qr(foo)x');

is_deeply(str_to_re('/foo/'), qr(foo));
is_deeply(str_to_re('qr(foo)i'), qr(foo)i);

dies_ok { str_to_re('/foo(/') };

DONE_TESTING:
done_testing();
