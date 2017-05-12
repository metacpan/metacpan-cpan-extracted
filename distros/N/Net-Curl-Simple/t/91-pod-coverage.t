#!perl

use Test::More;
unless ( $ENV{'TEST_AUTHOR'} ) {
	my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
	plan skip_all => $msg;
}

eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

plan tests => 4;
foreach my $ext ( '', qw(::UserAgent ::Async ::Form) ) {
	pod_coverage_ok( 'Net::Curl::Simple'.$ext,
		"Net::Curl::Simple$ext has proper POD coverage" );
}
