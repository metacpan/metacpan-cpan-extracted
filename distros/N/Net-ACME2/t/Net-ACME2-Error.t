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
        status => 400,
        type => 'urn:ietf:params:acme:error:rejectedIdentifier',
        detail => 'Error creating new order :: Cannot issue for "*.lottasubs.tld": Domain name does not end with a valid public suffix (TLD) (and 1 more problems. Refer to sub-problems for more information.)',
        subproblems => [
                {
                    'type'       => 'urn:ietf:params:acme:error:rejectedIdentifier',
                    'status'     => 400,
                    'identifier' => {
                        'type'  => 'dns',
                        'value' => '*.lottasubs.tld'
                    },
                    'detail' => 'Error creating new order :: Domain name does not end with a valid public suffix (TLD)'
                },
                {
                    'detail'     => 'Error creating new order :: Domain name does not end with a valid public suffix (TLD)',
                    'identifier' => {
                        'value' => 'www.sub103.lottasubs.tld',
                        'type'  => 'dns'
                    },
                    'status' => 400,
                    'type'   => 'urn:ietf:params:acme:error:rejectedIdentifier'
                },
        ],
    );

    unlike(
        $err->to_string(),
        qr<HASH>,
        'no HASH in a real-world error’s to_string()',
    );
}

{
    my $err = Net::ACME2::Error->new(
        status      => 490,
        type        => 'some:general:error',
        subproblems => [
            { status => 499, type => 'some:weird:error_yo',
                identifier => { type => 'dns', value => 'domain1' }, },
            { status => 499, type => 'some:weird:error2',
                identifier => { type => 'dns', value => 'domain2' }
             },
        ],
    );

    cmp_deeply(
        [ $err->subproblems() ],
        [
            all(
                Isa('Net::ACME2::Error::Subproblem'),
                methods(
                    identifier => { type => 'dns', value => 'domain1' },
                    to_string  => re(qr<dns/domain1: .*499.*some:weird:error_yo>),
                ),
            ),
            all(
                Isa('Net::ACME2::Error::Subproblem'),
                methods(
                    identifier => { type => 'dns', value => 'domain2' },
                    to_string  => re(qr<dns/domain2: .*499.*some:weird:error2>),
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
            dns/domain1: [ ] 499 [ ] some:weird:error_yo
            .+
            dns/domain2: [ ] 499 [ ] some:weird:error2
        >x,
        'to_string()',
    );
}

done_testing();
