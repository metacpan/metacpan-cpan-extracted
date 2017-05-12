# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name            'Net-DigitalNZ';
all_from        'lib/Net/DigitalNZ.pm';

# Specific dependencies
requires        'JSON::Any'      => 1.19;
requires 	 'URI::Escape' => 0;
requires 	'LWP::UserAgent' => 0;
requires 	'Carp' => 0;

#build_requires  'Test::More'        => '0.42';
#recommends      'Your::OtherModule' => '0.01';

#no_index        'directory'         => 'demos';

#install_script  'bin/myscript';

auto_install;
WriteAll;
