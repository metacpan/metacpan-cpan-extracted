#!perl -T

use Test::More;
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
pod_file_ok( "lib/Net/Rexster/Client.pm", "Valid POD file" );

done_testing();
