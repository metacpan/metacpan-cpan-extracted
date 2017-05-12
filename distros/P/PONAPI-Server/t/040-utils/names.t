#!perl
use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('PONAPI::Names', 'check_name');
}

### ...

subtest '... basic name checks' => sub {

    ok( !check_name([]),   '... bad:  []'    );
    ok( !check_name(""),   '... bad:  ""'    );
    ok( !check_name("-"),  '... bad:  "-"'   );
    ok( !check_name("-A"), '... bad:  "-A"'  );
    ok( check_name("A-A"), '... good: "A-A"' );
};

done_testing;
