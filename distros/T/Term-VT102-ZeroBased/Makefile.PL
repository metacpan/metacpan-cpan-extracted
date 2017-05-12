# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name           'Term-VT102-ZeroBased';
all_from       'lib/Term/VT102/ZeroBased.pm';
githubmeta;

requires       'Term::VT102';

auto_install;
WriteAll;

