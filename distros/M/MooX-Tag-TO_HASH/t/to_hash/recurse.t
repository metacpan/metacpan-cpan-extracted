#! perl

use strict;
use warnings;

use Test2::V0;
use Test::Lib;

use My::Test::TO_HASH::C1;
use constant CLASS => 'My::Test::TO_HASH::C1';

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
                cow => 'Daisy',
                hen => {
                    Camilla => 'friendly',
                    Ginger  => CLASS->new( hen => 'Ginger' ),
                    Babs    => CLASS->new( hen => 'Babs' ),
                    Bunty   => CLASS->new( hen => 'Bunty' ),
                },
                duck => [
                    'Donald',
                    CLASS->new( duck => 'Huey' ),
                    CLASS->new( duck => 'Duey' ),
                    CLASS->new( duck => 'Luey' ),
                ],
                horse          => CLASS->new( horse => 'Ed' ),
                secret_admirer => 'Nemo'
            );
        },
        'obj created'
    ) or bail_out $@;

    is( $obj, D(), 'obj defined' ) or bail_out;

    is(
        $obj->TO_HASH,
        hash {
            field cow => 'Daisy';
            field hen => hash {
                field Camilla => 'friendly';
                field Ginger  => hash {
                    field hen => 'Ginger';
                    field cow => U();
                    end;
                };
                field Babs => hash {
                    field hen => 'Babs';
                    field cow => U();
                    end;
                };
                field Bunty => hash {
                    field hen => 'Bunty';
                    field cow => U();
                    end;
                };
            };
            field goose => array {
                item 'Donald';
                item hash {
                    field goose => 'Huey';
                    field cow   => U();
                    field hen   => U();
                    end;
                };
                item hash {
                    field goose => 'Duey';
                    field cow   => U();
                    field hen   => U();
                    end;
                };
                item hash {
                    field goose => 'Luey';
                    field cow   => U();
                    field hen   => U();
                    end;
                };
                end;
            };
            field horse => meta {
                prop blessed => undef;
                prop this    => hash {
                    field horse => 'Ed';
                    field cow   => U();
                    field hen   => U();
                    end;
                };
            };
            end;
        },
        'value'
    );
};

done_testing;
