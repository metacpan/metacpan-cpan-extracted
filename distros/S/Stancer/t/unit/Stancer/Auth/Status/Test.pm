package Stancer::Auth::Status::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Auth::Status;
use TestCase;

## no critic (RequireFinalReturn)

sub constants : Tests(9) {
    is(Stancer::Auth::Status::ATTEMPTED, 'attempted', 'Constant "Stancer::Auth::Status::ATTEMPTED" exists');
    is(Stancer::Auth::Status::AVAILABLE, 'available', 'Constant "Stancer::Auth::Status::AVAILABLE" exists');
    is(Stancer::Auth::Status::DECLINED, 'declined', 'Constant "Stancer::Auth::Status::DECLINED" exists');
    is(Stancer::Auth::Status::EXPIRED, 'expired', 'Constant "Stancer::Auth::Status::EXPIRED" exists');
    is(Stancer::Auth::Status::FAILED, 'failed', 'Constant "Stancer::Auth::Status::FAILED" exists');
    is(Stancer::Auth::Status::REQUEST, 'request', 'Constant "Stancer::Auth::Status::REQUEST" exists');
    is(Stancer::Auth::Status::REQUESTED, 'requested', 'Constant "Stancer::Auth::Status::REQUESTED" exists');
    is(Stancer::Auth::Status::SUCCESS, 'success', 'Constant "Stancer::Auth::Status::SUCCESS" exists');
    is(Stancer::Auth::Status::UNAVAILABLE, 'unavailable', 'Constant "Stancer::Auth::Status::UNAVAILABLE" exists');
}

1;
