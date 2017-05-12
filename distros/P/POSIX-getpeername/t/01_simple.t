use strict;
use Test::More;
use Errno;
use POSIX::getpeername;

my $ret = POSIX::getpeername::_getpeername(1, my $addr);
is($ret, -1);
is(int $!, Errno::ENOTSOCK);

done_testing;

