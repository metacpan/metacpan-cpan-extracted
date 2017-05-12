use strict;
use warnings;

use Test::More q/no_plan/;

BEGIN {
    use_ok('Module::Install::DBICx::AutoDoc');
}

TODO: {
    local $TODO = "Implement proper Makefile.PL unit test";
    ok( mk_autodoc_test(), "Makefile looks good");
}

sub mk_autodoc_test {
    return 1;
}