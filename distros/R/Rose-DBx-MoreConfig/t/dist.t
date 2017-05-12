#!/usr/bin/env perl

use Test::More;

use FindBin;
use File::Spec;

use lib File::Spec->catdir( $FindBin::Bin, 'lib' );

require_ok('My::Dist::Test');

my ( $db, @warnings );

{
    local $SIG{__WARN__} = sub { push @warnings, @_; };

    $db = My::Dist::Test->new( domain => 'test', type => 'dist_test' );
}

ok( @warnings == 0, 'extra data source warnings suppressed' );

is( $db->database, 'test_me_dist', 'db name from module' );

is( $db->password, 'right_pass', 'password from rc file' );

done_testing();
