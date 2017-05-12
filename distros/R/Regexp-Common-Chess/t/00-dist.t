use Test::More;

BEGIN {
	eval {
		require Test::Distribution;
	};
	
	if($@) {
		plan skip_all => 'Test::Distribution not installed';
	} else {
		Test::Distribution->import(
			only => [qw/
				description
				prereq
				pod
				podcover
				use
				versions
			/],
		);
	}
}

