#!perl
use 5.008001; use utf8; use strict; use warnings;

use Test::More;
use version;

plan( 'tests' => 7 );

use_ok( 'Rosetta::Utility::SQLParser' );
is( $Rosetta::Utility::SQLParser::VERSION, qv('0.3.0'), 'Rosetta::Utility::SQLParser is the correct version' );

use_ok( 'Rosetta::Utility::SQLParser::L::en' );
is( $Rosetta::Utility::SQLParser::L::en::VERSION, qv('0.3.0'), 'Rosetta::Utility::SQLParser::L::en is the correct version' );

use lib 't/lib';

use_ok( 't_ROS_U_SP_Util' );
can_ok( 't_ROS_U_SP_Util', 'message' );
can_ok( 't_ROS_U_SP_Util', 'error_to_string' );

1;
