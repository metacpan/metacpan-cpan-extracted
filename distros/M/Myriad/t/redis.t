use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Myriad::Transport::Redis;

isa_ok('Myriad::Transport::Redis', 'IO::Async::Notifier');

done_testing;
