use Test::Pod::Coverage tests=>1;

pod_coverage_ok( "POE::Session::Irssi", {
		coverage_class => 'Pod::Coverage::CountParents',
                trustme => [qw(SE_DATA)],
	});

