use Test2::V0;

################################################################################
# This tests behavior of MOOISH_BASE_EXTRA_MODULES flag to disable modules
################################################################################

my $module;

BEGIN {
	$ENV{MOOISH_BASE_EXTRA_MODULES} = '';
	require Mooish::Base;
	skip_all "This test needs MooX::TypeTiny or MooX::XSConstructor"
		unless Mooish::Base->EXTRA_MODULES_AVAILABLE->{'MooX::TypeTiny'}
		|| Mooish::Base->EXTRA_MODULES_AVAILABLE->{'MooX::XSConstructor'};
}

# set up debugging
BEGIN {
	$Mooish::Base::DEBUG = {};
}

{

	package MyTest;
	use v5.10;
	use strict;
	use warnings;
	use Mooish::Base;
}

is $Mooish::Base::DEBUG->{MyTest}{extra_modules}{'MooX::TypeTiny'},
	F(), "MooX::TypeTiny not loaded";

is $Mooish::Base::DEBUG->{MyTest}{extra_modules}{'MooX::XSConstructor'},
	F(), "MooX::XSConstructor not loaded";

done_testing;

