# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name            'Sub-Curried';
all_from        'lib/Sub/Curried.pm';

license 'perl';
author 'osfameron';

# Specific dependencies
requires 'Devel::Declare'         => '0.002000';    # new version
requires 'Sub::Name'              => '0.00';
requires 'Sub::Current'           => '0.00';
requires 'B::Hooks::EndOfScope'   => '0.00';
requires 'Devel::BeginLift'       => '0.00';
requires 'Carp'                   => '0.00';
build_requires 'Test::More'       => '0.42';
build_requires 'Test::Exception'  => '0.00';
build_requires 'Test::NoWarnings' => '0.00';

auto_install;
WriteAll;
