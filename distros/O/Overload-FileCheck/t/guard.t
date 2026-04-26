use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;

use Overload::FileCheck qw(
  mock_file_check_guard mock_file_check unmock_file_check
  CHECK_IS_TRUE CHECK_IS_FALSE FALLBACK_TO_REAL_OP
);

my $fake = "/guard/test/file";

# --- basic guard: mock is active inside scope, removed after ---
{
    my $guard = mock_file_check_guard( '-e' => sub { CHECK_IS_TRUE } );
    isa_ok( $guard, 'Overload::FileCheck::Guard' );
    ok( -e $fake, "mocked -e returns true inside guard scope" );
}
ok( !-e $fake, "-e falls back to real op after guard is destroyed" );

# --- guard with cancel: mock persists after scope ---
{
    my $guard = mock_file_check_guard( '-f' => sub { CHECK_IS_TRUE } );
    ok( -f $fake, "mocked -f returns true" );
    $guard->cancel;
}
# mock still active because we cancelled the guard
ok( -f $fake, "-f still mocked after cancelled guard" );
unmock_file_check('-f');    # manual cleanup
ok( !-f $fake, "-f unmocked manually" );

# --- guard handles double-destroy gracefully ---
{
    my $guard = mock_file_check_guard( '-d' => sub { CHECK_IS_TRUE } );
    ok( -d $fake, "mocked -d" );
    # explicitly destroy, then let scope destroy again
    $guard->DESTROY;
    ok( !-d $fake, "-d unmocked after explicit DESTROY" );
}
# second DESTROY from scope exit should not die
pass("double DESTROY did not die");

# --- guard unmocks even if test dies (eval) ---
eval {
    my $guard = mock_file_check_guard( '-e' => sub { CHECK_IS_TRUE } );
    ok( -e $fake, "mocked -e inside eval" );
    die "simulated test failure";
};
ok( !-e $fake, "-e unmocked after die inside eval" );

# --- guard works with dash-less check names ---
{
    my $guard = mock_file_check_guard( 'e' => sub { CHECK_IS_TRUE } );
    ok( -e $fake, "mocked with dash-less 'e'" );
}
ok( !-e $fake, "unmocked after dash-less guard" );

# --- guard with FALLBACK_TO_REAL_OP ---
{
    my $guard = mock_file_check_guard( '-e' => sub { FALLBACK_TO_REAL_OP } );
    ok( !-e $fake, "FALLBACK_TO_REAL_OP falls through to real check" );
}

done_testing;
