use strict;
use warnings;

use Test::More 1;

my $class  = 'Set::CrossProduct';

subtest 'sanity' => sub {
	use_ok $class or BAIL_OUT( "$class did not compile" );
	};

done_testing();
