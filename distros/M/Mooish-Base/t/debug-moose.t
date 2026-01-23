use Test2::V0;

################################################################################
# This attempts to get extra information from Moose class using debugging
################################################################################

BEGIN {
	$ENV{MOOISH_BASE_FLAVOUR} = 'Moose';
	my $imported_ok = eval { require Mooish::Base; 1 };

	skip_all 'This test requires Moose and Hook::AfterRuntime'
		unless $imported_ok;

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

is $Mooish::Base::DEBUG, {
	MyTestRole => {
		class_type => 'Moose',
		role_type => 'Moose::Role',
		role => T(),
		standard => F(),
		extra_modules => {
			'MooX::TypeTiny' => F(),
			'MooX::XSConstructor' => F(),
			'MooseX::XSConstructor' => F(),
			'MooseX::XSAccessor' => bool(Mooish::Base->EXTRA_MODULES_AVAILABLE->{'MooseX::XSAccessor'}),
			'Hook::AfterRuntime' => F(),
		}
	},
	MyTest => {
		class_type => 'Moose',
		role_type => 'Moose::Role',
		role => F(),
		standard => F(),
		extra_modules => {
			'MooX::TypeTiny' => F(),
			'MooX::XSConstructor' => F(),
			'MooseX::XSConstructor' => bool(Mooish::Base->EXTRA_MODULES_AVAILABLE->{'MooseX::XSConstructor'}),
			'MooseX::XSAccessor' => bool(Mooish::Base->EXTRA_MODULES_AVAILABLE->{'MooseX::XSAccessor'}),
			'Hook::AfterRuntime' => bool(Mooish::Base->EXTRA_MODULES_AVAILABLE->{'Hook::AfterRuntime'}),
		}
	},
	},
	'info ok';

done_testing;

