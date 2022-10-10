#! perl

use strict;
use warnings;

use Test2::V0;
use Test::Lib;

use My::Test::C1_R1;
use constant CLASS => 'My::Test::C1_R1';

# cow & hen are always there
# duck & horse & donkey only if not empty
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
                donkey         => 'Donkey',
                secret_admirer => 'Nemo'
            );
        },
        'obj createed'
    ) or bail_out $@;

    is( $obj, D(), 'obj defined' ) or bail_out;

    is(
        $obj->TO_HASH,
        hash {
            field cow    => 'Daisy';
            field hen    => 'Ruby';
            field donkey => 'Donkey';
            field goose  => 'Donald';
            field horse  => 'Ed';
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
        'obj createed'
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
