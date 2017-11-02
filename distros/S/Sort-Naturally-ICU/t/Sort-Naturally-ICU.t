use strict;
use warnings;
use Test::More;

BEGIN { use_ok('Sort::Naturally::ICU') }

ok(defined &ncmp, 'ncmp subroutine exported');
ok(defined &nsort, 'nsort subroutine exported');

done_testing();
