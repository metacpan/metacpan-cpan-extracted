#!/usr/bin/env perl

use Test::More;

use FindBin;
use File::Spec;

use lib File::Spec->catdir( $FindBin::Bin, 'lib' );

require_ok('My::EnvTest');

my $db = My::EnvTest->new( domain => 'test', type => 'env_test' );

is( $db->database, 'test_me_env', 'db name from module' );

is( $db->password, 'right_pass', 'password from rc file' );

done_testing();
