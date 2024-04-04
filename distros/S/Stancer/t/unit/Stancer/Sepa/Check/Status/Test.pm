package Stancer::Sepa::Check::Status::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Sepa::Check::Status;
use TestCase;

## no critic (RequireFinalReturn)

sub constants : Tests(5) {
    is(Stancer::Sepa::Check::Status::AVAILABLE, 'available', 'Constant "Stancer::Sepa::Check::Status::AVAILABLE" exists');
    is(Stancer::Sepa::Check::Status::CHECK_ERROR, 'check_error', 'Constant "Stancer::Sepa::Check::Status::CHECK_ERROR" exists');
    is(Stancer::Sepa::Check::Status::CHECK_SENT, 'check_sent', 'Constant "Stancer::Sepa::Check::Status::CHECK_SENT" exists');
    is(Stancer::Sepa::Check::Status::CHECKED, 'checked', 'Constant "Stancer::Sepa::Check::Status::CHECKED" exists');
    is(Stancer::Sepa::Check::Status::UNAVAILABLE, 'unavailable', 'Constant "Stancer::Sepa::Check::Status::UNAVAILABLE" exists');
}

1;
