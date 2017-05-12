#!perl

use strict;
use warnings;
use lib '../lib';
use Test::More tests => 17;
use Test::CallFlow qw(:all);    # package under test

my $mocked = mock_object( 'Mocked::Pkg', { 'some field' => 'some value' } );

my @args1 = ( 'arg 1', 2, 3.3, $mocked );
my @ret1  = ();
my @args2 = @args1;
my @ret2  = qw(returned);
my @args3 = ();
my @ret3  = qw(multiple returned values);

# create test call plan

eval {
    $mocked->call_a_method(@args1);    # result is ()
    $mocked->call_another_method(@args2)->result(@ret2);
    $mocked->call_multivalue_method(@args3)->result(@ret3);
};
is( $@, '', "Create a plan without errors" )
    or die "No point to continue, plan failed: $@";

# start tests

mock_run();
is( $Test::CallFlow::instances[0]{state},
    $Test::CallFlow::state{execute},
    "Mock run started" );

eval "use Mocked::Pkg";
is( $@, '', "After mock_run use won't load mocked library anymore" );

eval { $mocked->call_wrong_method(@args1); };
like( $@, qr/\bcall_wrong_method\b/, "Call to wrong method fails" );

eval {
    mock_reset;
    mock_run;
};
is( $@, '', "Restart mock plan" );

eval { $mocked->call_a_method('wrong argument'); };
like( $@, qr/\bwrong argument\b/, "Call with wrong argument fails" );

mock_reset;
mock_run;

my @got;
eval { @got = $mocked->call_a_method(@args1); };
is( $@, '', "Correct call accepted" );
is_deeply( \@got, [], "Nothing returned" );

my $got2;
eval { $got2 = $mocked->call_another_method(@args2); };
is( $@, '', "Second call accepted" );
is_deeply( [$got2], \@ret2, "Single value returned" );

eval { @got = $mocked->call_multivalue_method(); };
is( $@, '', "Third call accepted" );
is_deeply( [@got], \@ret3, "Multiple values returned" );

eval { $mocked->unplanned_call; };
like( $@, qr/\bunplanned_call\b/, "Unplanned call fails" );

eval { $mocked->call_after_failure; };
like( $@, qr/^Mock call in a bad state: /, "Call after failure fails" );

mock_reset;
mock_run;

eval { $mocked->call_a_method(@args1); };
is( $@, '', "Correct call accepted after reset" );

eval { $mocked->unexpected_call; };
like( $@, qr/\bunexpected_call\b/, "Unexpected call fails" );

eval { mock_end; };
like( $@, qr/^End mock /, "mock_end should fail due to earlier failure" );
