#!perl -T

use warnings FATAL => 'all';
use strict;

use Test::More tests => 2;

BEGIN{
	use_ok('Ruby');
}

use Ruby -variable => '$SAFE', -function => 'String';

cmp_ok $SAFE, '>', 0, 'safe > 0';
