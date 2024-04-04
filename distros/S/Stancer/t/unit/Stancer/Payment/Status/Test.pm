package Stancer::Payment::Status::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Payment::Status;
use TestCase;

## no critic (RequireFinalReturn)

sub constants : Tests(10) {
    is(Stancer::Payment::Status::AUTHORIZE, 'authorize', 'Constant "Stancer::Payment::Status::AUTHORIZE" exists');
    is(Stancer::Payment::Status::AUTHORIZED, 'authorized', 'Constant "Stancer::Payment::Status::AUTHORIZED" exists');
    is(Stancer::Payment::Status::CANCELED, 'canceled', 'Constant "Stancer::Payment::Status::CANCELED" exists');
    is(Stancer::Payment::Status::CAPTURE, 'capture', 'Constant "Stancer::Payment::Status::CAPTURE" exists');
    is(Stancer::Payment::Status::CAPTURE_SENT, 'capture_sent', 'Constant "Stancer::Payment::Status::CAPTURE_SENT" exists');
    is(Stancer::Payment::Status::CAPTURED, 'captured', 'Constant "Stancer::Payment::Status::CAPTURED" exists');
    is(Stancer::Payment::Status::DISPUTED, 'disputed', 'Constant "Stancer::Payment::Status::DISPUTED" exists');
    is(Stancer::Payment::Status::EXPIRED, 'expired', 'Constant "Stancer::Payment::Status::EXPIRED" exists');
    is(Stancer::Payment::Status::FAILED, 'failed', 'Constant "Stancer::Payment::Status::FAILED" exists');
    is(Stancer::Payment::Status::TO_CAPTURE, 'to_capture', 'Constant "Stancer::Payment::Status::TO_CAPTURED" exists');
}

1;
