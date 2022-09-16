#!perl

use Test2::V0;
use Test::Lib;
use My::Test;
use Moo::Role ();

subtest( $_, \&test_it, $_ ) for ( 'My::Class::Cache', 'My::Role::Cache' );

sub test_it {

    my $type = shift;
    ( my $root = $type ) =~ s/::[^:]+$//;

    my ( $class, $is_role ) = load( C => $type );

    subtest '_tags' => sub {
        is(
            $class->_tags,
            hash {
                field T1_1 => hash {
                    field r1_1 => 'r1_1.t1_1';
                    field r1_2 => 'r1_2.t1_1';
                    field c1   => 't1_1_common';
                    field c2   => 't1_1_common';
                    end;
                };
                field T1_2 => hash {
                    field r1_1 => 'r1_1.t1_2';
                    end;
                };
                end;
            },
            'initial tags',
        );

        Moo::Role->apply_roles_to_package( $class, join '::', $root, 'R2' );

        is(
            $class->_tags,
            hash {
                field T1_1 => hash {
                    field r1_1 => 'r1_1.t1_1';
                    field r1_2 => 'r1_2.t1_1';
                    field c1   => 't1_1_common';
                    field c2   => 't1_1_common';
                    end;
                };
                field T1_2 => hash {
                    field r1_1 => 'r1_1.t1_2';
                    end;

                };
                field T2_1 => hash {
                    field r2_1 => 'r2_1.t2_1';
                    field r2_2 => 'r2_2.t2_1';
                    end;
                };
                field T2_2 => hash {
                    field r2_1 => 'r2_1.t2_2';
                    end;
                };
                end;
            },
            'overloaded hashref operator',
        );
    };

    subtest 'tag_attr_hash' => sub {
        is(
            $class->_tags->tag_attr_hash,
            hash {
                field T1_1 => hash {
                    field r1_1 => 'r1_1.t1_1';
                    field r1_2 => 'r1_2.t1_1';
                    field c1   => 't1_1_common';
                    field c2   => 't1_1_common';
                    end;
                };
                field T1_2 => hash {
                    field r1_1 => 'r1_1.t1_2';
                    end;

                };
                field T2_1 => hash {
                    field r2_1 => 'r2_1.t2_1';
                    field r2_2 => 'r2_2.t2_1';
                    end;
                };
                field T2_2 => hash {
                    field r2_1 => 'r2_1.t2_2';
                    end;
                };
            },
            'tag_attr_hash',
        );

    };

    subtest 'tag_value_hash' => sub {

        is(
            $class->_tags->tag_value_hash,
            hash {
                field T1_1 => hash {
                    field 'r1_1.t1_1'   => bag { item 'r1_1'; end; };
                    field 'r1_2.t1_1'   => bag { item 'r1_2'; end; };
                    field 't1_1_common' => bag { item 'c1';   item 'c2'; end; };
                    end;
                };
                field T1_2 => hash {
                    field 'r1_1.t1_2' => bag { item 'r1_1'; end; };
                    end;

                };
                field T2_1 => hash {
                    field 'r2_1.t2_1' => bag { item 'r2_1'; end; };
                    field 'r2_2.t2_1' => bag { item 'r2_2'; end; };
                    end;
                };
                field T2_2 => hash {
                    field 'r2_1.t2_2' => bag { item 'r2_1'; end; };
                    end;
                };
            },
            'tag_value_hash',
        );

    };

    subtest 'attr_hash' => sub {

        is(
            $class->_tags->attr_hash,
            hash {
                field c1 => hash {
                    field T1_1 => 't1_1_common';
                    end;
                };
                field c2 => hash {
                    field T1_1 => 't1_1_common';
                    end;
                };
                field r1_1 => hash {
                    field T1_1 => 'r1_1.t1_1';
                    field T1_2 => 'r1_1.t1_2';
                    end;
                };
                field r1_2 => hash {
                    field T1_1 => 'r1_2.t1_1';
                    end;
                };
                field r2_1 => hash {
                    field T2_1 => 'r2_1.t2_1';
                    field T2_2 => 'r2_1.t2_2';
                    end;
                };
                field r2_2 => hash {
                    field T2_1 => 'r2_2.t2_1';
                    end;
                };
                end;
            },
            'attr_hash',
        );

    };

    subtest 'tags' => sub {

        is(
            $class->_tags->tags,
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
            $class->_tags->tags( 'r1_1' ),
            bag {
                item 'T1_1';
                item 'T1_2';
                end;
            },
            'r1_1'
        );

        is(
            $class->_tags->tags( 'r1_2' ),
            bag {
                item 'T1_1';
                end;
            },
            'r1_2'
        );

        is(
            $class->_tags->tags( 'r2_1' ),
            bag {
                item 'T2_1';
                item 'T2_2';
                end;
            },
            'r2_1',
        );

        is(
            $class->_tags->tags( 'r2_2' ),
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

        my $cache = $class->_tags;
        for my $tuple ( @tuples ) {
            my ( $attr, $tag, $value ) = @$tuple;
            is( $cache->value( $attr, $tag ), $value, "$attr:$tag" );
        }

    };

}

done_testing;
