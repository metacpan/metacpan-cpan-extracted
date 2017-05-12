use inc::Module::Install;

use Module::Install::AuthorRequires 0.02;

name     'Nagios-Plugin-OverHTTP';
author   'Douglas Christopher Wilson <doug@somethingdoug.com>';
license  'perl';
all_from 'lib/Nagios/Plugin/OverHTTP.pm';

# Resources
resources homepage   => 'http://github.com/dougwilson/perl5-nagios-plugin-overhttp/';
resources repository => 'git://github.com/dougwilson/perl5-nagios-plugin-overhttp.git';

# Modules that are required
requires
	'Data::Validate::Domain'    => '0.02',
	'Data::Validate::URI'       => '0.05',
	'Carp'                      => 0,
	'Const::Fast'               => 0,
	'English'                   => 0,
	'Env::Path'                 => '0.04',
	'Getopt::Long::Descriptive' => 0,
	'HTML::Strip'               => '1.04',
	'HTTP::Request'             => '5.827',
	'HTTP::Status'              => '5.817',
	'IPC::System::Simple'       => '0.13',
	'LWP::UserAgent'            => 0,
	'Moose'                     => '0.74',
	'Moose::Role'               => '0.74',
	'MooseX::Clone'             => '0.05',
	'MooseX::Getopt'            => '0.43',
	'MooseX::StrictConstructor' => '0.08',
	'MooseX::Types'             => '0.08',
	'MooseX::Types::Moose'      => 0,
	'Regexp::Common'            => '2.119',
	'Scalar::Util'              => '1.19',
	'Try::Tiny'                 => '0.04',
	'URI'                       => 0,
	'namespace::clean'          => '0.04';

# Modules that are required for tests in t/
test_requires
	'HTTP::Response'   => 0,
	'HTTP::Status'     => '5.817',
	'Test::Exception'  => 0,
	'Test::MockObject' => 0,
	'Test::More'       => '0.94',
	'Test::Trap'       => 0;

# Modules that are required for tests in xt/
author_requires
	'Test::More'     => 0,
	'Test::Requires' => '0.02';

# Enable tests to be in multi-level directories
tests_recursive;

# Write the provided classes in the META
auto_provides;

if (eval "require Getopt::Long::Descriptive 0.082; 1;") {
	# Getopt::Long::Descriptive is install, make sure it's not a broken version
	if (Getopt::Long::Descriptive->VERSION ge '0.082'
	    && Getopt::Long::Descriptive->VERSION lt '0.084') {
		# Two versions of Getopt::Long::Descriptive have a bug that affects this
		# package, and so if you have that version, we require the version where
		# it was fixed.
		requires 'Getopt::Long::Descriptive' => '0.084';
	}
}

WriteAll;
