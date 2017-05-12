use strict;
use warnings;
use Test::More;
use Test::Method;

{
	package Test;
	use Moose;
	use MooseX::RemoteHelper::Types qw( Bool );

	has test => (
		isa    => Bool,
		is     => 'rw',
		coerce => 1,
	);
}

my $t = new_ok( 'Test' );

method_ok $t, test => ['true'    ], 1;
method_ok $t, test => ['True'    ], 1;
method_ok $t, test => ['TRUE'    ], 1;
method_ok $t, test => ['T'       ], 1;
method_ok $t, test => ['Enabled' ], 1;
method_ok $t, test => ['Enable'  ], 1;
method_ok $t, test => ['Yes'     ], 1;
method_ok $t, test => ['false'   ], 0;
method_ok $t, test => ['False'   ], 0;
method_ok $t, test => ['FALSE'   ], 0;
method_ok $t, test => ['F'       ], 0;
method_ok $t, test => ['Disabled'], 0;
method_ok $t, test => ['Disable' ], 0;
method_ok $t, test => ['No'      ], 0;

done_testing;
