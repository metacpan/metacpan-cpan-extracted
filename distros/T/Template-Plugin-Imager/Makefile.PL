# Load the Module::Install bundled in ./inc/
use inc::Module::Install;
    
# Define metadata
name            'Template-Plugin-Imager';
all_from        'lib/Template/Plugin/Imager.pm';
    
# Specific dependencies
requires 'Template::Plugin'  => '2.14';
requires 'Imager'            => '0.57';
    
auto_install;
WriteAll;
