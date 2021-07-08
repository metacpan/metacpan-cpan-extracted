#!perl
use 5.006;
use strict;
use warnings;
use Test::More tests => 5;

use Sub::Deprecate qw(sub_rename_with);


{
	sub to1 {7};
	my $ret = eval {
		sub_rename_with( __PACKAGE__, 'from1', 'to1' );
		to1();
	};
	die $@ if $@;
	is( $ret, 7, 'To function returns properly');
}

{
	sub to2 {7}
	my $ret = eval {
		sub_rename_with( __PACKAGE__, 'from2', 'to2', sub { die 42 } );
		from2();
	};
	like( $@, qr/42/, 'CB triggered');
	
	my $ret2 = eval { to2(); };
	is( $ret2, 7, 'To function returns properly');
}

{
	sub from3 {7}
	sub to3 {7}
	eval {
		sub_rename_with( __PACKAGE__, 'from3', 'to3' );
	};
	like( $@, qr/must not exist/, 'From function must not exist');
}

{
	sub to4 {7}
	eval {
		sub_rename_with( __PACKAGE__, 'from4', 'does_not_exist', sub {"hi"} );
	};
	like( $@, qr/must exist/, 'From function must exist');
}

1;
