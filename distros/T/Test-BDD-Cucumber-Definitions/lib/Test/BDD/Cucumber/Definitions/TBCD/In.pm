package Test::BDD::Cucumber::Definitions::TBCD::In;

use strict;
use warnings;
use utf8;

use Test::BDD::Cucumber::Definitions::Base::In;
use Test::BDD::Cucumber::Definitions::File::In;
use Test::BDD::Cucumber::Definitions::HTTP::In;
use Test::BDD::Cucumber::Definitions::Struct::In;
use Test::BDD::Cucumber::Definitions::Var::In;
use Test::BDD::Cucumber::Definitions::Zip::In;

our $VERSION = '0.37';

sub import {

    Test::BDD::Cucumber::Definitions::Base::In->import;
    Test::BDD::Cucumber::Definitions::File::In->import;
    Test::BDD::Cucumber::Definitions::HTTP::In->import;
    Test::BDD::Cucumber::Definitions::Struct::In->import;
    Test::BDD::Cucumber::Definitions::Var::In->import;
    Test::BDD::Cucumber::Definitions::Zip::In->import;

    return;
}

1;
