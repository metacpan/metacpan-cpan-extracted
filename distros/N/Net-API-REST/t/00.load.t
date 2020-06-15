#!/usr/bin/perl

# t/00.load.t - check module loading and create testing directory
BEGIN
{
	use strict;
	use Test::Mock::Apache2;
	use Test::MockObject;
	use Test::More qw( no_plan );
};

BEGIN
{
    use_ok( 'Net::API::REST' );
    use_ok( 'Net::API::REST::Cookies' );
    use_ok( 'Net::API::REST::DateTime' );
    use_ok( 'Net::API::REST::JWT' );
    use_ok( 'Net::API::REST::Query' );
    use_ok( 'Net::API::REST::Request' );
    use_ok( 'Net::API::REST::Response' );
    use_ok( 'Net::API::REST::Status' );
}

# my $object = Net::API::REST->new ();
# isa_ok ($object, 'Net::API::REST');
