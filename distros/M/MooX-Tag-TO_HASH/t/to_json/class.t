#! perl

use strict;
use warnings;

use Test2::V0;
use Test::Lib;

use JSON::MaybeXS ();
use My::Test::TO_JSON::C1;
use constant CLASS => 'My::Test::TO_JSON::C1';

# cow & hen are always there
# duck & horse only if not empty
# porcupine if defined
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
                porcupine      => 'Prickly',
                secret_admirer => 'Nemo'
            );
        },
        'obj created'
    ) or bail_out $@;

    is( $obj, D(), 'obj defined' ) or bail_out;

    is(
        $obj->TO_JSON,
        hash {
            field c1_bool   => exact_ref JSON::MaybeXS::true;
            field c1_num    => number 14;
            field c1_str    => '13';
            field cow       => 'Daisy';
            field hen       => 'Ruby';
            field goose     => 'Donald';
            field porcupine => 'Prickly';
            field horse     => 'Ed';
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
            $obj = CLASS->new(
                porcupine      => undef,
                secret_admirer => 'Nemo'
            );
        },
        'obj created'
    ) or bail_out $@;

    is( $obj, D(), 'obj defined' ) or bail_out;

    is(
        $obj->TO_JSON,
        hash {
            field c1_bool => exact_ref JSON::MaybeXS::true;
            field c1_num  => number 14;
            field c1_str  => '13';
            field cow     => U();
            field hen     => U();
            end;
        },
        'value'
    );
};

done_testing;
