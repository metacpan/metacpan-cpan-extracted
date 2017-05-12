#! perl

use strict;
use warnings FATAL => 'all';

use Test::More 0.88;
use Signal::Safety;

is($Signal::Safety, 1, 'Signals are initially safe');

{
	local $Signal::Safety = 0;
	is ($Signal::Safety, 0, 'Signals are temporarily unsafe');
}

is($Signal::Safety, 1, 'Signals are safe again');
done_testing;
