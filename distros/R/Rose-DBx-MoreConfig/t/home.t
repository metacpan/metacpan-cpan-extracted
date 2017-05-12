#!/usr/bin/env perl

use Test::More;

use FindBin;
use File::Spec;

use lib File::Spec->catdir( $FindBin::Bin, 'lib' );

require_ok('My::HomeTest');

my $db = My::HomeTest->new( domain => 'test', type => 'home_test' );

is( $db->database, 'test_me_home', 'db name from module' );

is( $db->password, 'right_pass', 'password from rc file' );

done_testing();
