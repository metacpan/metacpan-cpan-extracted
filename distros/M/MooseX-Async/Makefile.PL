# Load the Module::Install bundled in ./inc/
use inc::Module::Install 0.75;

# Define metadata
name 'MooseX-Async';
all_from 'lib/MooseX/Async.pm';

# Specific dependencies
requires 'Moose'                    => '0.56';
requires 'MooseX::AttributeHelpers' => '0.13'; # tokuhirom++

build_requires 'Test::More' => '0.42';

no_index 'directory' => 'ex';

WriteAll;
