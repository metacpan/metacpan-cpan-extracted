#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

my $extra_tests=0;

BEGIN {
    use_ok( 'Net::Connection::lsof' ) || print "Bail out!\n";
}


my $output_raw=`lsof -i UDP -i TCP -n -l -P`;
if (
	( $? eq 0 ) ||
	(
	 ( $^O =~ /linux/ ) &&
	 ( $? eq 256 )
	 )
	){
	$extra_tests++;
	my $worked=0;
	eval{
		my @nc_objects=&lsof_to_nc_objects;
		$worked=1;
	};

	ok( $worked eq '1', 'lsof_to_nc_objects') or diag("lsof_to_nc_objects died with ".$@);
}

my $tests_ran=1+$extra_tests;
done_testing($tests_ran);
