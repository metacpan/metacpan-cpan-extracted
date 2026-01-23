use Test2::V0;

################################################################################
# This tests MooX::TypeTiny extra module loading
################################################################################

my $module;

BEGIN {
	$module = 'MooX::TypeTiny';
	$ENV{MOOISH_BASE_EXTRA_MODULES} = $module;
	require Mooish::Base;
	skip_all "This test needs $module"
		unless Mooish::Base->EXTRA_MODULES_AVAILABLE->{$module};
}

# set up debugging
BEGIN {
	$Mooish::Base::DEBUG = {};
}

{

	package MyTestRole;
	use v5.10;
	use strict;
	use warnings;
	use Mooish::Base -role;
}

{

	package MyTest;
	use v5.10;
	use strict;
	use warnings;
	use Mooish::Base;
}

is $Mooish::Base::DEBUG->{MyTestRole}{extra_modules}{$module},
	F(), "$module not loaded for roles";

is $Mooish::Base::DEBUG->{MyTest}{extra_modules}{$module},
	T(), "$module loaded for classes";

done_testing;

