#! perl

use strict;
use warnings;

use Test2::Bundle::Extended;

use MooX::PDL2;

our @log;

# make sure we can detect if PDL's constructors being called.
our @Constructors = qw[ new new_from_specification ];

{
    package PDL;
    use Class::Method::Modifiers ();

    for my $method ( @::Constructors ) {

        Class::Method::Modifiers::before "$method" => sub {
            push @::log, __PACKAGE__ . "::$method";
        };
    }
}


{
    package MyPDL;
    use Moo;
    extends 'MooX::PDL2';

    before BUILDARGS => sub {
        push @::log, __PACKAGE__ . '::BUILDARGS';
    };


    sub BUILD {
        push @::log, __PACKAGE__ . '::BUILD';
    }

    sub DEMOLISH {
        push @::log, __PACKAGE__ . '::DEMOLISH';
    }
}

{
    package MyPDLg1;
    use Moo;
    extends 'MyPDL';

    # don't have any extra params, so create full fledged MyPDLg1
    sub initialize { shift->new }

    before BUILDARGS => sub {
        push @::log, __PACKAGE__ . '::BUILDARGS';
    };


    sub BUILD {
        push @::log, __PACKAGE__ . '::BUILD';
    }

    sub DEMOLISH {
        push @::log, __PACKAGE__ . '::DEMOLISH';
    }
}

subtest "PDL constructor logging" => sub {

    use Safe::Isa;
    require PDL;

    for my $method ( @::Constructors ) {

        subtest $method => sub {
            @::log = ();
            my $pdl = PDL->$method();
            # Test2::Tools::Class::isa_ok == 0.000061 doesn't handle
            # classes with overloaded bool operators correctly
            ok( $pdl->isa( 'PDL' ), 'class is correct' );
            is( \@log, ["PDL::$method"], "logged" );
        };
    }
};



subtest "Moo Machinery" => sub {

    subtest '0th generation' => sub {

        @log = ();

        my $m = MyPDL->new;
        is( \@log, [ 'MyPDL::BUILDARGS', 'MyPDL::BUILD' ], "construct" );

        @log = ();
        undef $m;
        is( \@log, ['MyPDL::DEMOLISH'], "destruct" );
    };

    subtest '1st generation' => sub {

        @log = ();

        my $m = MyPDLg1->new;
        is(
            \@log,
            [
                'MyPDLg1::BUILDARGS', 'MyPDL::BUILDARGS',
                'MyPDL::BUILD',       'MyPDLg1::BUILD'
            ],
            "construct"
        );

        @log = ();
        undef $m;
        is( \@log, [ 'MyPDLg1::DEMOLISH', 'MyPDL::DEMOLISH' ], "destruct" );

    };
};

subtest "inheritance" => sub {

    subtest "class" => sub {
        my $s = MyPDLg1->sequence( 10 );
        ok( $s->isa( 'MyPDLg1' ), "is a subclass" );

        is( [ $s->list ], [ 0 .. 9 ], "value" );
    };

    subtest "object" => sub {
        my $s = MyPDLg1->new->sequence( 10 );
        ok( $s->isa( 'MyPDLg1' ), "is a subclass" );

        is( [ $s->list ], [ 0 .. 9 ], "sequence" );
    };

};


done_testing;
