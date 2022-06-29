#!/usr/bin/perl

# t/00.load.t - check module loading and create testing directory
BEGIN
{
	use strict;
	use lib './lib';
	use Test::Mock::Apache2;
	use Test::MockObject;
	use Test::More qw( no_plan );
};

BEGIN
{
    # generated with for m in `find ./lib -type f -name "*.pm" | sort`; do echo $m | perl -pe 's,./lib/,,' | perl -pe 's,\.pm$,,' | perl -pe 's/\//::/g' | perl -pe 's,^(.*?)$,use_ok\( "$1" \)\;,'; done
    use_ok( 'Net::API::REST' );
    use_ok( 'Net::API::REST::Cookies' );
    use_ok( "Net::API::REST::Cookie" );
    use_ok( 'Net::API::REST::DateTime' );
    use_ok( 'Net::API::REST::JWT' );
    use_ok( 'Net::API::REST::Query' );
    use_ok( 'Net::API::REST::Request' );
    use_ok( 'Net::API::REST::Response' );
    use_ok( 'Net::API::REST::Status' );
}

done_testing();

__END__

