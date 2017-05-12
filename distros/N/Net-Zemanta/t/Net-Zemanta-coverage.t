BEGIN {
	eval 'use Test::Pod::Coverage tests => 2';
	if ($@) {
		use Test;
		plan tests => 1;
		skip('Test::Pod::Coverage not found');
		exit(0);
	}
}

pod_coverage_ok('Net::Zemanta::Suggest');
pod_coverage_ok('Net::Zemanta::Preferences');
