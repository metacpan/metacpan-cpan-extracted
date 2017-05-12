use Test::Pod::Coverage tests=>1;

pod_coverage_ok( "Module::Install::POE::Test::Loops", {
		coverage_class => 'Pod::Coverage::CountParents',
	});

