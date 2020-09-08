#!perl

$| = 1;

use strict;
use warnings;

# defer locking so we have a chance to see if the tag was found
BEGIN {
    $ENV{RUNALONE_DEFER_LOCK} = 1;
}

use FindBin;
use lib $FindBin::Bin . '/..';
use Local::TrapExit;

use Test::More tests => 5;

my $run_entered;
my $stderr = '';
use Role::Tiny::With;
{
    local $SIG{__WARN__} = sub { $stderr .= $_[0]; };
    with 'Role::RunAlone';
}

do {
    run();
} unless caller();

sub run {
    $run_entered = 1;
}

exit;

END {
    ok( 1, 'in the END block' );
    is( Local::TrapExit::exit_code(), 2, 'exit code 2 indicates missing tag' );
    like( $stderr, qr/FATAL: No/, 'missing tag error was on STDERR' );
    ok( !$run_entered, 'script did not execute' );

  SKIP: {
        skip qq/"DOES" is not native to Perl version $]/, 1 if $] < 5.010001;
        ok( !__PACKAGE__->DOES('Role::RunAlone'), 'role was not composed' );
    }

    done_testing();
}

