use Test2::V0;

################################################################################
# This attempts to get extra information from the class using debugging
################################################################################

BEGIN {
	require Mooish::Base;
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
		class_type => 'Moo',
		role_type => 'Moo::Role',
		role => T(),
		standard => F(),
		extra_modules => {
			'MooX::TypeTiny' => F(),
			'MooX::XSConstructor' => F(),
			'MooseX::XSConstructor' => F(),
			'MooseX::XSAccessor' => F(),
			'Hook::AfterRuntime' => F(),
		}
	},
	MyTest => {
		class_type => 'Moo',
		role_type => 'Moo::Role',
		role => F(),
		standard => F(),
		extra_modules => {
			'MooX::TypeTiny' => bool(Mooish::Base->EXTRA_MODULES_AVAILABLE->{'MooX::TypeTiny'}),
			'MooX::XSConstructor' => bool(Mooish::Base->EXTRA_MODULES_AVAILABLE->{'MooX::XSConstructor'}),
			'MooseX::XSConstructor' => F(),
			'MooseX::XSAccessor' => F(),
			'Hook::AfterRuntime' => F(),
		}
	},
	},
	'info ok';

done_testing;

