use strict;
use warnings;

use Test::More;

print STDOUT qq{##teamcity[progressMessage 'before']\n};

ok 1, 'ok';

print STDERR qq{##teamcity[progressMessage 'after']\n};

done_testing;
