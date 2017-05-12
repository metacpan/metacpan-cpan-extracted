BEGIN{ $ENV{STRING_DIFF_PP} = 1; }
use strict;
use Test::More tests => 1;

BEGIN { use_ok 'String::Diff' }
