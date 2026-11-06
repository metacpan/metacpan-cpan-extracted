use strict;
use warnings;
use Test::More;
use lib 'lib';
use Demo::Config;
is(Demo::Config::get()->{debug}, 0, 'default debug off');
done_testing;
