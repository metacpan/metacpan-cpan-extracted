#!perl

use strict;
use warnings;
use lib '../lib';
use Test::More tests => 11;
use Test::CallFlow qw(:all);    # package under test

my $mocked = mock_object( 'Mocked::Pkg', { 'some field' => 'some value' } );
my $remains = qr/^End mock with[\s\d]+calls remaining\b/;

eval {
    $mocked->first->anytime;
    my $end = $mocked->second(2)->anytime->result(-2)->result(-2.2)->min(3);
    $mocked->optional->min(0)->end( $end, $end );
    $mocked->final;
};
is( $@, '', "Planning unordered calls" );

eval { mock_run; };
is( $@, '', "Run" );

eval { mock_end; };
like( $@, $remains, "End before first call fails" );

eval {
    mock_reset;
    mock_run;
    $mocked->second(2);
    $mocked->first;
    $mocked->second(2);
    $mocked->optional;
    $mocked->final;
    mock_end;
};
like( $@, qr/^Expected\b.*\bsecond\b/,
      "End without enough second calls fails" );

eval {
    mock_reset;
    mock_run;
};

is( $mocked->second(2), -2,   "Call past an anytime declaration" );
is( $mocked->second(2), -2.2, "Second call produces second result" );
is( $mocked->second(2), -2.2,
    "Call after last specified result produces last result" );
is( $mocked->first, undef, "First anytime is still callable" );

eval { mock_end; };
like( $@, $remains, "End with only final call unmade fails" );

eval {
    mock_reset;
    mock_run;
    $mocked->second(2);
    $mocked->second(2);
    $mocked->optional;
};
like( $@, qr/\bsecond\b/,
      "Test run fails when an unordered call is ended unsatisfied" );

eval {
    mock_reset;
    mock_run;
    $mocked->second(2);
    $mocked->second(2);
    $mocked->second(2);
    $mocked->optional;
    $mocked->first;
    $mocked->final;
    mock_end;
};
is( $@, '', "Test run succeeds when enough calls have been made" );
