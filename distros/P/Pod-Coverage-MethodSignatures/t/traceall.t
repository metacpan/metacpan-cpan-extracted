
use FindBin qw/$Bin/;
use lib $Bin;
use Test::More tests => 1;
use Test::Output;

sub Pod::Coverage::MethodSignatures::TRACE_ALL () { 1 }
use Pod::Coverage::MethodSignatures;

my $pc;
sub check_coverage {
	$pc = Pod::Coverage::MethodSignatures->new(package => 'FooTestFullPod');
	$pc->coverage;
}

my $expected_output = <<END_EXPECTED;
requiring 'FooTestFullPod'
walking symbols
checking origin package for 'FooTestFullPod::bar':
	FooTestFullPod
checking origin package for 'FooTestFullPod::baz':
	FooTestFullPod
checking origin package for 'FooTestFullPod::foo':
	FooTestFullPod
checking origin package for 'FooTestFullPod::new':
	FooTestFullPod
checking origin package for 'FooTestFullPod::func':
	Devel::Declare::MethodInstaller::Simple
checking origin package for 'FooTestFullPod::method':
	Devel::Declare::MethodInstaller::Simple
END_EXPECTED

stdout_is( \&check_coverage, $expected_output, "Test TRACE_ALL" );
diag( $pc->why_unrated );
