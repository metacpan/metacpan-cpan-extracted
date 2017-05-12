use Test::More tests => 1;

BEGIN { $ENV{PMIR_BASE} = 'foo' };

use PMIR;

is $INC[0], 'foo/perl5/lib', 'PMIR works';
