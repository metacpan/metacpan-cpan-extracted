# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name           'NetHack-FOV';
all_from       'lib/NetHack/FOV.pm';

requires       'Test::More';

auto_install;
WriteAll;

