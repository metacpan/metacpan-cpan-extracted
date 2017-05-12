use Test::More;
eval "use Test::Pod::Coverage 1.00";

plan $@ ? ( skip_all => "Test::Pod::Coverage 1.00 required for testing POD" )
	: 
	( tests => 1 )
	;

pod_coverage_ok(
               "Module::Release",
               { also_private => [ qw/DASHES/ ], },
           );

