#!perl

use Test2::V0;
use Test::Lib;
use Moo::Role ();

{
    package C;

    use Moo;
    use R1;
}

is(
    C->_tags,
    hash {
        field T1_1 => hash {
            field r1_1 => 'r1_1.t1_1';
            field r1_2 => 'r1_2.t1_1';
        };
        field T1_2 => hash {
            field r1_1 => 'r1_1.t1_2';

        };
    },
    'initial tags',
);

Moo::Role->apply_roles_to_package( 'C', 'R2' );

is(
    C->_tags,
    hash {
        field T1_1 => hash {
            field r1_1 => 'r1_1.t1_1';
            field r1_2 => 'r1_2.t1_1';
        };
        field T1_2 => hash {
            field r1_1 => 'r1_1.t1_2';

        };
        field T2_1 => hash {
            field r2_1 => 'r2_1.t2_1';
            field r2_2 => 'r2_2.t2_1';
        };
        field T2_2 => hash {
            field r2_1 => 'r2_1.t2_2';
        };
    },
    'overloaded hashref operator',
);

is(
    C->_tags->tag_hash,
    hash {
        field T1_1 => hash {
            field r1_1 => 'r1_1.t1_1';
            field r1_2 => 'r1_2.t1_1';
        };
        field T1_2 => hash {
            field r1_1 => 'r1_1.t1_2';

        };
        field T2_1 => hash {
            field r2_1 => 'r2_1.t2_1';
            field r2_2 => 'r2_2.t2_1';
        };
        field T2_2 => hash {
            field r2_1 => 'r2_1.t2_2';
        };
    },
    'tag_hash',
);

is(
    C->_tags->attr_hash,
    hash {
        field r1_1 => hash {
            field T1_1 => 'r1_1.t1_1';
            field T1_2 => 'r1_1.t1_2';
        };
        field r1_2 => hash {
            field T1_1 => 'r1_2.t1_1';
        };
        field r2_1 => hash {
            field T2_1 => 'r2_1.t2_1';
            field T2_2 => 'r2_1.t2_2'
        };
        field r2_2 => hash {
            field T2_1 => 'r2_2.t2_1';
        };
    },
    'attr_hash',
);

subtest 'tags' => sub {

    is(
        C->_tags->tags,
        bag {
            item 'T1_1';
            item 'T1_2';
            item 'T2_1';
            item 'T2_2';
            end;
        },
        'all tags'
    );

    is(
        C->_tags->tags( 'r1_1' ),
        bag {
            item 'T1_1';
            item 'T1_2';
            end;
        },
        'r1_1'
    );

    is(
        C->_tags->tags( 'r1_2' ),
        bag {
            item 'T1_1';
            end;
        },
        'r1_2'
    );

    is(
        C->_tags->tags( 'r2_1' ),
        bag {
            item 'T2_1';
            item 'T2_2';
            end;
        },
        'r2_1',
    );

    is(
        C->_tags->tags( 'r2_2' ),
        bag {
            item 'T2_1';
            end;
        },
        'r2_2',
    );

};

subtest 'value' => sub {

    my @tuples = (
        [ 'r1_1' => 'T1_1' => 'r1_1.t1_1' ],
        [ 'r1_1' => 'T1_2' => 'r1_1.t1_2' ],
        [ 'r1_2' => 'T1_1' => 'r1_2.t1_1' ],
        [ 'r2_1' => 'T2_1' => 'r2_1.t2_1' ],
        [ 'r2_1' => 'T2_2' => 'r2_1.t2_2' ],
        [ 'r2_2' => 'T2_1' => 'r2_2.t2_1' ],
    );

    my $cache = C->_tags;
    for my $tuple ( @tuples ) {
        my ( $attr, $tag, $value ) = @$tuple;
        is( $cache->value( $attr, $tag ), $value, "$attr:$tag" );
    }

};

done_testing;
