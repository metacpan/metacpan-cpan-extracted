use Test2::V0;

################################################################################
# This tests MooseX::XSConstructor extra module loading
################################################################################

my $module;

BEGIN {
	$module = 'MooseX::XSConstructor';
	$ENV{MOOISH_BASE_FLAVOUR} = 'Moose';
	$ENV{MOOISH_BASE_EXTRA_MODULES} = $module;
	my $imported_ok = eval { require Mooish::Base; 1 };
	skip_all "This test needs Moose and $module"
		unless $imported_ok && Mooish::Base->EXTRA_MODULES_AVAILABLE->{$module};
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

