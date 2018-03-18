use strict;
use warnings;

use Test::More tests => 17;

use_ok $_ for qw(
    Test::BDD::Cucumber::Definitions
    Test::BDD::Cucumber::Definitions::TBCD::In
    Test::BDD::Cucumber::Definitions::TBCD::Ru
    Test::BDD::Cucumber::Definitions::Types
    Test::BDD::Cucumber::Definitions::HTTP
    Test::BDD::Cucumber::Definitions::HTTP::In
    Test::BDD::Cucumber::Definitions::HTTP::Ru
    Test::BDD::Cucumber::Definitions::Struct
    Test::BDD::Cucumber::Definitions::Struct::In
    Test::BDD::Cucumber::Definitions::Struct::Ru
    Test::BDD::Cucumber::Definitions::Validator
    Test::BDD::Cucumber::Definitions::Var
    Test::BDD::Cucumber::Definitions::Var::In
    Test::BDD::Cucumber::Definitions::Var::Ru
    Test::BDD::Cucumber::Definitions::Zip
    Test::BDD::Cucumber::Definitions::Zip::In
    Test::BDD::Cucumber::Definitions::Zip::Ru
);
