# -*- perl -*-

# t/00.load.t - check module loading and create testing directory
BEGIN
{
	use strict;
	use Test::Mock::Apache2;
	use Test::MockObject;
	use Test::More tests => 1;
};

BEGIN { use_ok( 'Net::API::REST' ); }

# my $object = Net::API::REST->new ();
# isa_ok ($object, 'Net::API::REST');
