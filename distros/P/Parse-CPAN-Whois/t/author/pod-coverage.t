use Test::Pod::Coverage tests=>2;

pod_coverage_ok( "Parse::CPAN::Whois", {
		coverage_class => 'Pod::Coverage::CountParents',
	});

pod_coverage_ok( "Parse::CPAN::Whois::Author", {
		coverage_class => 'Pod::Coverage::CountParents',
	});
