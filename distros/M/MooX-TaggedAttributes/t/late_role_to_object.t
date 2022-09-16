#!perl

use Test2::V0;
use Test::Lib;
use My::Test;

todo "do not track changes to objects after instantiation" => sub {

    subtest( $_, \&test_it, $_ )
      for 'My::Class::LateApply',
      'My::Role::LateApply',
      ;

};

sub test_it {
    my $type = shift;

    my ( $class ) = load( 'C1', $type );

    my $q = $class->new;

    is(
        $q,
        object {
            call t1_1  => 't1_1.v';
            call c1_1  => 'c1_1.v';
            call c1_2  => 'c1_2.v';
            call _tags => hash {
                field tag1 => hash {
                    field c1_1 => 'c1_1.t1';
                    end;
                };
                field tag2 => hash {
                    field c1_1 => 'c1_1.t2';
                    field c1_2 => 'c1_2.t2';
                    end;
                };
                end;
            };
        },
    );

    # now apply a role to the object and make sure things work.

    Moo::Role->apply_roles_to_object( $q, "${type}::R1" );

    is(
        $q,
        object {
            call t1_1  => 't1_1.v';
            call c1_1  => 'c1_1.v';
            call c1_2  => 'c1_2.v';
            call r1_1  => 'r1_1.v';
            call _tags => hash {
                field tag1 => hash {
                    field c1_1 => 'c1_1.t1';
                    field r1_1 => 'r1_1.t1';
                    end;
                };
                field tag2 => hash {
                    field c1_1 => 'c1_1.t2';
                    field c1_2 => 'c1_2.t2';
                    field r1_1 => 'r1_1.t2';
                    end;
                };
                end;
            };
        },
    );

}

done_testing;
