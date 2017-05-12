use Test::Pod::Coverage tests=>1;

pod_coverage_ok( "POE::Session::GladeXML2", {
		coverage_class => 'Pod::Coverage::CountParents',
		trustme => [qr/SE_DATA/],
	});

