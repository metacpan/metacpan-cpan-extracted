#!perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use PDL;


{
    package Moo::PDL;

    use PDL::Lite;

    use Moo;
    extends 'PDLx::DetachedObject';

    has PDL => ( is => 'rw' );

    sub requires_hash { 0 };
}

{
    package Class::Tiny::PDL;

    use Class::Tiny qw[ PDL ];

    use parent 'PDLx::DetachedObject';

    sub requires_hash { 0 };
}

{
    package Object::Tiny::PDL;

    use Object::Tiny qw[ PDL ];
    use parent 'PDLx::DetachedObject';

    sub requires_hash { 0 };

}

{
    package Class::Accessor::PDL;

    use parent 'Class::Accessor', 'PDLx::DetachedObject';
    __PACKAGE__->follow_best_practice;
    __PACKAGE__->mk_accessors( 'PDL' );

    sub requires_hash { 1 };
}

{
    package Class::Accessor::Antlers::PDL;

    use Class::Accessor "antlers";
    use parent 'PDLx::DetachedObject';

    has PDL => ( is => 'ro' );

    sub requires_hash { 1 };
}


for my $Class ( qw[
    Object::Tiny::PDL
    Moo::PDL
    Class::Tiny::PDL
    Class::Accessor::PDL
    Class::Accessor::Antlers::PDL
    ] )
{

    subtest $Class => sub {

        my @args = ( PDL => pdl( 0, 1 ) );

        my $mpdl = $Class->new( $Class->requires_hash ? { @args } : @args  );

        isa_ok( $mpdl, $Class );
        isa_ok( $mpdl, 'PDL' );

        cmp_deeply( $mpdl->unpdl, [ 0, 1 ], 'constructor initialization' );

        {
            # copy constructor is just a pass through
            my $pdl = $mpdl;
            isa_ok( $pdl, $Class );
            isa_ok( $pdl, 'PDL' );
            cmp_deeply( $pdl->unpdl, [ 0, 1 ], 'copy' );
        }

        {
            # operations!
            my $pdl = $mpdl + 2;

            ok( $pdl->isa( 'PDL' ) && !$pdl->isa( $Class ),
                "result is normal piddle" );

            cmp_deeply( $mpdl->unpdl, [ 0, 1 ], 'mpdl untouched' );
            cmp_deeply( $pdl->unpdl,  [ 2, 3 ], 'result' );
        }

        {
            # operations!
            $mpdl *= 2;

            isa_ok( $mpdl, $Class );
            isa_ok( $mpdl, 'PDL' );

            cmp_deeply( $mpdl->unpdl, [ 0, 2 ], 'mpdl * 2' );
        }

        {
            my $pdl = $mpdl->sequence(10);
            isa_ok( $pdl, 'PDL' );
            ok ( ! $pdl->isa( $Class ),"new pdl is not a $Class" );
            cmp_deeply( $pdl->unpdl, [0..9], "result of sequence call" );
        }

    };

}

done_testing;

