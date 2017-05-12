#!perl

use strict;
use warnings;
use UNIVERSAL qw(isa);
use lib '../lib';
use Test::More tests => 3;
use Test::CallFlow qw(:all);    # package under test

my $mocked = mock_object( 'Mocked::Pkg', { 'some field' => 'some value' } );

eval {

    # catcher for static calls
    Test::CallFlow::instance()->mock_call( arg_check(qr/^Mocked::Pkg::/),
                     arg_check( sub { !isa( $_[2][ $_[1] ], 'Mocked::Pkg' ) } ),
                     arg_any( 0, 99 ) )->max(9)->anytime;

    mock_run;
    Mocked::Pkg::first_ok_call( 'any', 'args' );
    Mocked::Pkg::second_ok_call();
    Mocked::Pkg::finally_fail( bless {}, 'Mocked::Pkg' );
};
unlike( $@, qr/_ok_call/, "Regex matcher accepts any static calls" )
    or diag $@;
like( $@, qr/\bfinally_fail\b/,
      "ArgCheck::Code correctly denies an argument blessed as class to deny" )
    or diag $@;

mock_clear;

TODO: {
    local $TODO = "write more complex tests";
    ok( 0, "unimplemented" );
}
