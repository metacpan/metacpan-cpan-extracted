#!perl -w

use strict;
use Test::More tests => 1;

BEGIN{ # Fake Term::ReadLine, which is hard coded in ShipIt::Util
    package Term::ReadLine;
    sub new{ bless {}, shift }
    sub readline{ '' };
    $INC{'Term/ReadLine.pm'} = __FILE__;
}

use ShipIt;

BEGIN { use_ok 'ShipIt::Step::ChangeAllVersions' }

diag "Testing ShipIt::Step::ChangeAllVersions/$ShipIt::Step::ChangeAllVersions::VERSION";
diag "under ShipIt $ShipIt::VERSION";
