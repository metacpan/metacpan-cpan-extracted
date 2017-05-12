# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name            'Net-Generatus';
all_from        'lib/Net/Generatus.pm';

# Specific dependencies
requires 	 'URI::Escape' => 0;
requires 	 'LWP::UserAgent' => 2;
#build_requires  'Test::More'        => '0.42';
#recommends      'Your::OtherModule' => '0.01';

#no_index        'directory'         => 'demos';

#install_script  'bin/myscript';

auto_install;
WriteAll;
