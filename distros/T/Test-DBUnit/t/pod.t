use warnings;
use strict;

use Test::Pod tests => 2;
 
pod_file_ok( 'lib/DBUnit.pm', "should have value lib/DBUnit.pm POD file" );
pod_file_ok( 'lib/Test/DBUnit.pm', "should have value lib/TestDBUnit.pm POD file" );