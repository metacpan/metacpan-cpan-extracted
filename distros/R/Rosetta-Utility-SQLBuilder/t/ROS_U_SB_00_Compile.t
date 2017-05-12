#!perl
use 5.008001; use utf8; use strict; use warnings;

use Test::More;
use version;

plan( 'tests' => 9 );

use_ok( 'Rosetta::Utility::SQLBuilder' );
is( $Rosetta::Utility::SQLBuilder::VERSION, qv('0.22.0'), 'Rosetta::Utility::SQLBuilder is the correct version' );

use_ok( 'Rosetta::Utility::SQLBuilder::L::en' );
is( $Rosetta::Utility::SQLBuilder::L::en::VERSION, qv('0.3.0'), 'Rosetta::Utility::SQLBuilder::L::en is the correct version' );

use lib 't/lib';

use_ok( 't_ROS_U_SB_Util' );
can_ok( 't_ROS_U_SB_Util', 'message' );
can_ok( 't_ROS_U_SB_Util', 'error_to_string' );

use_ok( 't_ROS_U_SB_Model' );
can_ok( 't_ROS_U_SB_Model', 'populate_model' );

1;
