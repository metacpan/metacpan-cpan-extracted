#! perl

use strict;
use warnings;

use Test2::Bundle::Extended;

use PDL::Lite;

{
    package MyPDL;
    use Moo;
    extends 'MooX::PDL2';

    has '+_PDL' => (
                    init_arg => 'pdl',
                   );

    around BUILDARGS => sub {

        my ( $orig, $class, @args ) = @_;

        return { pdl => $args[0] }
          if @args == 1 && 'HASH' ne ref $args[0];

        return $class->$orig( @args );
    };

}


subtest '$pdl' => sub {

    subtest 'new($pdl)' => sub {

        my $pdl = PDL->ones( 5 );

        my $mxp = MyPDL->new( $pdl );

        is( $mxp->unpdl, $pdl->unpdl, "value" );

        ok( lives { $mxp++ }, "increment object" );

        ok( PDL::all( $mxp == 2 ), "object incremented" );
        ok( PDL::all( $pdl == 2 ), "original piddle incremented" );

    };

    subtest 'new(pdl => $pdl)' => sub {

        my $pdl = PDL->ones( 5 );

        my $mxp = MyPDL->new( pdl => $pdl );

        is( $mxp->unpdl, $pdl->unpdl, "value" );

        ok( lives { $mxp++ }, "increment object" );

        ok( PDL::all( $mxp == 2 ), "object incremented" );
        ok( PDL::all( $pdl == 2 ), "original piddle incremented" );

    };

};

subtest 'scalar' => sub {

    subtest 'new( $scalar )' => sub {

        my $mxp = MyPDL->new( 3 );
        is( $mxp->unpdl, [3], "value" );
    };

    subtest 'new( pdl => $scalar )' => sub {

        my $mxp = MyPDL->new( pdl => 3 );
        is( $mxp->unpdl, [3], "value" );
    };
};


done_testing
