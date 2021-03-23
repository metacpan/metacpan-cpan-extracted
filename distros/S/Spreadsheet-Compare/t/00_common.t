#!/usr/bin/env perl

use Spreadsheet::Compare::Common test => 1;

use_ok('Spreadsheet::Compare');

lives_ok {
    throws_ok(
        sub {
            Spreadsheet::Compare->new( result => {} );
        },
        qr/attribute "result" is readonly/,
        'throw readonly in constructor',
    );

    throws_ok(
        sub {
            Spreadsheet::Compare->new()->result( {} );
        },
        qr/attribute "result" is readonly/,
        'throw readonly in setter',
    );

    my $cmp = new_ok('Spreadsheet::Compare');

    is_deeply( $cmp->result, {}, 'default value' );

    $cmp->{__ro__result} = { bla => {} };
    is_deeply( $cmp->result, { bla => {} }, 'set via internal hash' );

    throws_ok(
        sub {
            $cmp->run;
        },
        qr/no configuration given!/,
        'throw no config',
    );

    my $cfg = {
        type => 'FIX',
        rootdir => 't',
        title => 'fixed format',
        files => [
            'left/simple01.fix',
            'right/simple01.fix',
        ],
        record_format => 'A2A3A3A3A3',
        identity => [0],
    };

    lives_ok(
        sub {
            $cmp->config($cfg)->run;
            is($cmp->result->{'00_common/fixed format'}->{left}, 4, 'result ok');
        },
        'simple test',
    );

}
'no dying tests';


done_testing();
