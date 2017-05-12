#!perl

use strict;
use warnings;
use lib '../lib';
use Test::More tests => 9;
use Test::CallFlow qw(:all);    # package under test

my $mocked = mock_object( 'Mocked::Pkg', { 'some field' => 'some value' } );

eval {
    $mocked->any( arg_any( 0, 3 ) )->min(2)->max(3);
    mock_run;
    $mocked->any;
    $mocked->any( undef, "12765", {} );
};
is( $@, '', "Any args pass ArgCheck::Any" );

eval { $mocked->any( 1, 2, 3, 4 ); };
like( $@, qr/^Too many arguments\b/, "Too many any args fail" );

eval {
    mock_clear;
    mock_package('Mocked::Pkg');
    $mocked->regex( arg_check qr/ok/ )->max(2);
    mock_run;
    $mocked->regex('this is ok');
};
is( $@, '', "Regexp ArgCheck can make a call pass" );

eval { $mocked->regex('this is wrong'); };
like( $@,
      qr/\bnot match argument\b/,
      "Regexp ArgCheck can make a call not pass" );

my $sub_called;

eval {
    mock_clear;
    mock_package('Mocked::Pkg');
    $mocked->run( arg_check( sub { ++$sub_called; $_[2][ $_[1] ] }, 1, 2 ) )
        ->max(2);
    mock_run;
    $mocked->run( 'anything', 'that evaluates as true' );
};
is( $sub_called, 2,
    "Code ArgCheck actually calls given code for each argument to check" );
is( $@, '', "Code ArgCheck can make a call pass" );

eval { $mocked->run( undef, undef ); };
is( $sub_called, 3,
    "Code ArgCheck stops getting called after first failing argument" );
like( $@, qr/\bnot match argument\b/,
      "Code ArgCheck can make a call not pass" );

eval { mock_end; };
is( $@, '', "Test set is complete" );
