# -*- perl -*-

use Test::Pod tests => 7;

pod_file_ok( './lib/Module/Generic.pm' );
pod_file_ok( './lib/Module/Generic/Array.pod' );
pod_file_ok( './lib/Module/Generic/Boolean.pod' );
pod_file_ok( './lib/Module/Generic/Exception.pod' );
pod_file_ok( './lib/Module/Generic/Null.pod' );
pod_file_ok( './lib/Module/Generic/Scalar.pod' );
pod_file_ok( './lib/Module/Generic/Tie.pod' );

