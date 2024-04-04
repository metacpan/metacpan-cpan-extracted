#! /usr/bin/env perl

use 5.020;
use strict;
use warnings;
use Test::Most;

use lib './t/unit';

{
    require_ok('Stancer::Auth');

    ok(scalar keys %main::Stancer::Auth::Status::, 'Should import status');
}

{
    require_ok('Stancer::Refund');

    ok(scalar keys %main::Stancer::Refund::Status::, 'Should import status');
}

{
    require_ok('Stancer::Payment');

    my @ns = keys %main::Stancer::;
    my @expected = (
        'Auth::',
        'Card::',
        'Config::',
        'Customer::',
        'Device::',
        'Dispute::',
        'Payment::',
        'Refund::',
        'Sepa::',
    );

    cmp_deeply(\@ns, supersetof(@expected), 'Should have exported the whole lib');

    ok(scalar keys %main::Stancer::Auth::Status::, 'Stancer::Auth::Status included');
    ok(scalar keys %main::Stancer::Payment::Status::, 'Stancer::Payment::Status included');
    ok(scalar keys %main::Stancer::Refund::Status::, 'Stancer::Refund::Status included');
}

done_testing();
