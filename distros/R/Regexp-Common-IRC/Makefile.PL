# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name 'Regexp-Common-IRC';
all_from 'lib/Regexp/Common/IRC.pm';

# Specific dependencies
build_requires 'Test::More' => 0;
requires 'Regexp::Common'   => 0;

no_index 'directory' => 'ex';

auto_install;
WriteAll;
