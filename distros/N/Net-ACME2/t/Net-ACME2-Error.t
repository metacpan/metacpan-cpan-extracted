#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Deep;

use Net::ACME2::Error ();

{
    my $err = Net::ACME2::Error->new(
        type => 'some:general:error',
    );

    is(
        $err->to_string(),
        'some:general:error',
        'to_string() when there’s no “status”',
    );
}

{
    my $err = Net::ACME2::Error->new(
        status => '499',
    );

    like(
        $err->to_string(),
        qr/499/,
        'to_string() when there’s no “type”',
    );
}

{
    my $err = Net::ACME2::Error->new(
        status => 490,
        type => 'some:general:error',
        subproblems => [
            { status => 499, type => 'some:weird:error_yo', identifier => 'id1' },
            { status => 499, type => 'some:weird:error2', identifier => 'id2' },
        ],
    );

    cmp_deeply(
        [ $err->subproblems() ],
        [
            all(
                Isa('Net::ACME2::Error::Subproblem'),
                methods(
                    identifier => 'id1',
                    to_string => re( qr<id1: .*499.*some:weird:error_yo> ),
                ),
            ),
            all(
                Isa('Net::ACME2::Error::Subproblem'),
                methods(
                    identifier => 'id2',
                    to_string => re( qr<id2: .*499.*some:weird:error2> ),
                ),
            ),
        ],
        'subproblems()',
    );

    like(
        $err->to_string(),
        qr<
            490 [ ] some:general:error
            .+
            id1: [ ] 499 [ ] some:weird:error_yo
            .+
            id2: [ ] 499 [ ] some:weird:error2
        >x,
        'to_string()',
    );
}

done_testing();
