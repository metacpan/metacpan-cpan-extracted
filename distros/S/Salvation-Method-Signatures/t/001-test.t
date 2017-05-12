#!/usr/bin/perl -w

use strict;
use warnings;

package main;

use Salvation::Method::Signatures;

use Test::More tests => 10;

method new() {

    subtest 'new()' => sub {

        plan tests => 2;

        is( $self, 'main' );
        is( scalar( @_ ), 0 );
    };

    return bless( {}, ( ref( $self ) || $self ) );
}

method first( Str arg, Int second_arg, HashRef third_arg ) {

    subtest 'first()' => sub {

        plan tests => 5;

        isa_ok( $self, 'main' );
        is( $arg, 'asd' );
        is( $second_arg, 100500 );
        is_deeply( $third_arg, { a => 1, b => 2 } );
        is( scalar( @_ ), 0 );
    };

    return 'qwe';
}

method second( Str :named_arg1!, Int :named_arg2! ) {

    subtest 'second()' => sub {

        plan tests => 4;

        isa_ok( $self, 'main' );
        is( $named_arg1, 'zxc' );
        is( $named_arg2, 200300 );
        is( scalar( @_ ), 0 );
    };

    return;
}

method third( ! Str :named_arg3, Int :named_arg4 ) {

    subtest 'third()' => sub {

        plan tests => 4;

        isa_ok( $self, 'main' );
        ok( ! defined $named_arg3 );
        is( $named_arg4, 400500 );
        is( scalar( @_ ), 0 );
    };

    return;
}

method fourth( Int positional, Str :named ) {

    subtest 'fourth()' => sub {

        plan tests => 4;

        isa_ok( $self, 'main' );
        is( $positional, 500600 );
        is( $named, 'mnb' );
        is( scalar( @_ ), 0 );
    };

    return;
}

method fifth( Int required, Int optional? ) {

    subtest 'fifth()' => sub {

        plan tests => 4;

        isa_ok( $self, 'main' );
        is( $required, 500600 );
        ok( ! defined $optional );
        is( scalar( @_ ), 0 );
    };
}

method fifth2( Int required, Int optional? ) { fail() }

method sixth( ! Int required, Int optional? ) {

    subtest 'sixth()' => sub {

        plan tests => 4;

        isa_ok( $self, 'main' );
        is( $required, 500600 );
        is( $optional, 600700 );
        is( scalar( @_ ), 0 );
    };
}

{
    my $obj = new_ok( 'main' => [] );

    is( $obj -> first( 'asd', 100500, { a => 1, b => 2 } ), 'qwe' );

    $obj -> second( named_arg1 => 'zxc', named_arg2 => 200300 );

    $obj -> third( named_arg4 => 400500 );

    $obj -> fourth( 500600, named => 'mnb' );

    $obj -> fifth( 500600 );

    eval{ $obj -> fifth2( 500600, undef ); 1 } || ok( $@, 'fifth2() failed' );

    $obj -> sixth( 500600, 600700 );


}

exit 0;

__END__
