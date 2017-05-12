#!/usr/bin/perl

use strict;
use warnings;

use Data::Dump qw( pp );
use Test::More tests => 44;
BEGIN { 
    use_ok('POEx::HTTP::Server');
}

my $W = POEx::HTTP::Server->new( options => {},
                                 inet => {
                                        LocalPort => 808
                                    },
                                 handlers => 'poe:honk/bonk'
                                );
isa_ok( $W, 'POEx::HTTP::Server' );
is( $W->{alias}, 'HTTPd', " ... default alias" );
# ok( $W->D, " ... debugging on" );
is_deeply( $W->{headers}, { Server => "POEx::HTTP::Server/$POEx::HTTP::Server::VERSION"}, 
                    " ... default headers" );
is_deeply( $W->{inet}, { Listen=>1, BindPort=>808, Reuse=>1 }, 
                " ... correct Inet" ) or warn pp $W->{inet};
is_deeply( $W->{todo}, [ '' ], " ... correct handler priority" );
isa_ok( $W->{handlers}{''}, 'URI' );
is_deeply( $W->{handlers}, { '' => 'poe:honk/bonk' }, " ... correct handler list" );

$W->{options}{debug} = 0;
$W->{name} = 'test';
my( $re, $handler ) = POEx::HTTP::Server::Client::find_handler( $W, "/" );
is( $re, '', "Found handler for /" );
is( $handler, 'poe:honk/bonk', " ... correctly" );


#####
$W->__init_handlers( { handlers => {
                                 'bonk' => 'poe:bonk/bonk',
                                 'honk' => 'poe:honk/honk'
                    } } );
pass( "Setting handlers doesn't die" );
# is_deeply( $W->{todo}, [ qw( bonk honk) ], " ... correct handler priority" );
isa_ok( $W->{handlers}{bonk}, 'URI' );
is_deeply( $W->{handlers}, { 'bonk' => 'poe:bonk/bonk',
                             'honk' => 'poe:honk/honk' }, 
                                " ... correct handler list" );

( $re, $handler ) = POEx::HTTP::Server::Client::find_handler( $W, "/" );
is( $re, undef, "No handler for /" );


#####
$W->__init_handlers( { handlers => [
                                 'honk' => 'poe:honk/honk',
                                 'onk' => 'poe:onk/onk',
                                 'bonk' => 'poe:bonk/bonk'
                    ] } );
pass( "Setting handlers doesn't die" );
is_deeply( $W->{todo}, [ qw( honk onk bonk) ], " ... correct handler priority" );
isa_ok( $W->{handlers}{onk}, 'URI' );
is_deeply( $W->{handlers}, { 'bonk' => 'poe:bonk/bonk',
                             'onk' => 'poe:onk/onk',
                             'honk' => 'poe:honk/honk' }, 
                                " ... correct handler list" );

( $re, $handler ) = POEx::HTTP::Server::Client::find_handler( $W, "/path/to/honk" );
is( $re, 'honk', "Not anchored" );

( $re, $handler ) = POEx::HTTP::Server::Client::find_handler( $W, "/path/to/bonk" );
is( $re, 'onk', "Correct priority" );

#####
$W->__init_handlers( { handlers => [ 
                                 'on_error' => 'something/error',
                                 'pre_request' => 'something/before',
                                 'post_request' => 'something/after',
                                 'honk' => 'poe:honk/honk',
                                 'onk' => 'poe:onk/onk',
                                 'bonk' => 'poe:bonk/bonk'
                    ] } );
pass( "Setting handlers doesn't die" );
is_deeply( $W->{todo}, [ qw( honk onk bonk) ], " ... correct handler priority" );
isa_ok( $W->{specials}{on_error}, 'URI' );
is_deeply( $W->{specials}, { 'on_error' => 'poe:something/error',
                             'pre_request' => 'poe:something/before',
                             'post_request' => 'poe:something/after' }, 
                                " ... correct special handler list" );


#########################################################
##### add as scalar
$W->handlers_add( 'poe:/honk/honk' );
pass( "Adding a handler doesn't die" );
is_deeply( $W->{todo}, [ qw( honk onk bonk), '' ], " ... correct handler priority" );
isa_ok( $W->{handlers}{''}, 'URI' );

##### add as arrayref
$W->handlers_add( [ zonk => 'poe:/honk/honk' ] );
pass( "Adding a handlers doesn't die" );
is_deeply( $W->{todo}, [ qw( honk onk bonk), '', 'zonk' ], 
                    " ... correct handler priority" );
isa_ok( $W->{handlers}{''}, 'URI' ) or die pp $W->{handlers};
isa_ok( $W->{handlers}{'zonk'}, 'URI' );

##### add as hashref
$W->handlers_add( { thunk => 'poe:/honk/honk' } );
pass( "Adding a handlers doesn't die" );
is_deeply( $W->{todo}, [ qw( honk onk bonk), '', qw( zonk thunk ) ], 
                    " ... correct handler priority" );
isa_ok( $W->{handlers}{''}, 'URI' ) or die pp $W->{handlers};
isa_ok( $W->{handlers}{'thunk'}, 'URI' );


##### remove scalar
$W->handlers_remove( 'honk' );
pass( "Removing a handler doesn't die" );
is_deeply( $W->{todo}, [ qw( onk bonk), '', qw( zonk thunk ) ], " ... correct handler priority" );
isa_ok( $W->{handlers}{''}, 'URI' );

##### add as arrayref
$W->handlers_remove( [ qw( zonk bonk ) ] );
pass( "Removing a handler doesn't die" );
is_deeply( $W->{todo}, [ qw( onk ), '', qw( thunk ) ], 
                    " ... correct handler priority" );
isa_ok( $W->{handlers}{''}, 'URI' ) or die pp $W->{handlers};

##### add as hashref
$W->handlers_remove( { '' => 'poe:/honk/honk', 'onk' => 1  } );
pass( "Removing a handlers doesn't die" );
is_deeply( $W->{todo}, [ qw( thunk ) ], 
                    " ... correct handler priority" );
isa_ok( $W->{handlers}{'thunk'}, 'URI' );
