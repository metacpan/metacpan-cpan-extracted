use Test::More;
use Test::Kwalitee qw< kwalitee_ok >;
use strict;
use warnings;

BEGIN {
	$ENV{RELEASE_TESTING}
		or plan skip_all => 'these tests are for release candidate testing'
}

kwalitee_ok;
done_testing;
