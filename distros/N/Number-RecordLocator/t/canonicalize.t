use strict;
use warnings;

use Test::More tests => 5;
use_ok('Number::RecordLocator');

my $g = Number::RecordLocator->new;

is($g->canonicalize('10BS'), 'IOPF', '10BS == IOPF');
is($g->canonicalize('10bs'), 'IOPF', '10bs == IOPF');
is($g->canonicalize('3RTD'), '3RTD', '3RTD == 3RTD');
is($g->canonicalize('3rtd'), '3RTD', '3rtd == 3RTD');
