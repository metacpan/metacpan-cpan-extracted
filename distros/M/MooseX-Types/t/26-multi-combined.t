use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use Test::Fatal;
use lib 't/lib';

BEGIN { use_ok 'MultiCombined', qw/Foo2Alias MTFNPY/ }

# test that a type from TestLibrary was exported
ok Foo2Alias;
ok MTFNPY;

done_testing();

