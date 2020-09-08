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

use Test::More  tests => 6;

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
    is( Local::TrapExit::exit_code(), 0,  'normal exit' );
    is( $stderr,                      '', 'no error was on STDERR' );
    ok( __PACKAGE__->DOES('Role::RunAlone'), 'role was composed' );
    my $tag_info = __PACKAGE__->_runalone_tag_pkg;
    is( $tag_info->{package}, __PACKAGE__, 'tag was found in ' . __PACKAGE__ );
    ok( $run_entered, 'script executed' );

    done_testing();
}

__END__
