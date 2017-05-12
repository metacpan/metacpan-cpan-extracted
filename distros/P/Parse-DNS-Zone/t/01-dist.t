use Test::More;

BEGIN {
	plan skip_all => "set RELEASE_TESTING to test" unless $ENV{RELEASE_TESTING};
	eval { require Test::Distribution };
	if($@) {
		plan skip_all => 'Test::Distribution not installed';
	} else {
		Test::Distribution->import(
			only => [qw(
				description
				prereq
				pod
				podcover
				sig
				use
				versions
			)]
		);
	}
}
