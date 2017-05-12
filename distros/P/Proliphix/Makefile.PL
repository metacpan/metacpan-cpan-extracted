# Load the Module::Install bundled in ./inc/
use strict;
use inc::Module::Install;

# Define metadata
name            'Proliphix';
all_from        'lib/Proliphix.pm';

# Specific dependencies
requires        'Moose';
requires        'LWP::UserAgent';
build_requires  'Test::More'        => '0.42';

WriteAll;
