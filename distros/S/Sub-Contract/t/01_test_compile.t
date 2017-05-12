#-------------------------------------------------------------------
#
#   $Id: 01_test_compile.t,v 1.6 2009/06/01 20:43:06 erwan_lemonnier Exp $
#

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Test::More;

BEGIN {

    use check_requirements;
    plan tests => 7;

    use_ok("Sub::Contract::Debug");
    use_ok("Sub::Contract::Pool");
    use_ok("Sub::Contract::Cache");
    use_ok("Sub::Contract::ArgumentChecks");
    use_ok("Sub::Contract::Memoizer");
    use_ok("Sub::Contract::Compiler");
    use_ok("Sub::Contract");
};

