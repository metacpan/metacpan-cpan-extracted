#! perl

use strict;
use warnings;

use Test2::V0;
use Test::Lib;

use My::Test::TO_HASH::C4_deprecated;
use constant CLASS => 'My::Test::TO_HASH::C4_deprecated';

# cow & hen are always there
# duck & horse only if not empty
# duck becomes goose
# secret_admirer is never there

#--------------------------------------------------------#

subtest 'specify all values' => sub {

    my $obj;

    ok(
        lives {
            $obj = CLASS->new(
                cow            => 'Daisy',
                hen            => 'Ruby',
                duck           => 'Donald',
                horse          => 'Ed',
                secret_admirer => 'Nemo'
            );
        },
        'obj created'
    ) or bail_out $@;

    is( $obj, D(), 'obj defined' ) or bail_out;

    is(
        $obj->TO_HASH,
        hash {
            field cow   => 'DAISY';
            field hen   => 'RUBY';
            field goose => 'DONALD';
            field horse => 'ED';
            end;
        },
        'value'
    );
};

#--------------------------------------------------------#

subtest 'omit values' => sub {

    my $obj;

    ok(
        lives {
            $obj = CLASS->new( secret_admirer => 'Nemo' );
        },
        'obj created'
    ) or bail_out $@;

    is( $obj, D(), 'obj defined' ) or bail_out;

    is(
        $obj->TO_HASH,
        hash {
            field cow => U();
            field hen => U();
            end;
        },
        'value'
    );
};


done_testing;
