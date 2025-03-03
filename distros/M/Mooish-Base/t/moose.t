use Test2::V0;

################################################################################
# This tests whether Moose class is made immutable with Hook::AfterRuntime
################################################################################

BEGIN {
	$ENV{MOOISH_BASE_FLAVOUR} = 'Moose';
	my $imported_ok = eval { require Mooish::Base; 1 };

	skip_all 'This test requires Moose and Hook::AfterRuntime'
		unless $imported_ok && Mooish::Base->HAS_HOOK_AFTERRUNTIME;
}

{

	package MyTest;

	use Mooish::Base;
}

ok(MyTest->meta->is_immutable, 'class made immutable ok');

done_testing;

