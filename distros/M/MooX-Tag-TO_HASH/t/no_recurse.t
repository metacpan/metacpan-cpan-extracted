#! perl

use strict;
use warnings;

use Test2::V0;
use Test::Lib;

use My::Test::C3;
use constant CLASS => 'My::Test::C3';

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
                horse          => CLASS->new( horse => 'Ed' ),
                secret_admirer => 'Nemo'
            );
        },
        'obj createed'
    ) or bail_out $@;

    is( $obj, D(), 'obj defined' ) or bail_out;

    is(
        $obj->TO_HASH,
        hash {
            field cow   => 'Daisy';
            field hen   => 'Ruby';
            field goose => 'Donald';
            field horse => object {
                call horse => 'Ed';
                call cow   => U();
                call hen   => U();
            };
            end;
            end;
        },
        'value'
    );
};

done_testing;
