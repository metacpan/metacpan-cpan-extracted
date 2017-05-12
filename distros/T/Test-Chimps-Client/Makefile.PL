use inc::Module::Install;

# Define metadata
name            'Test-Chimps-Client';
all_from        'lib/Test/Chimps/Client.pm';

# Specific dependencies
requires('Class::Accessor');
requires('LWP::UserAgent');
requires('Params::Validate');
requires('Test::TAP::Model::Visual');
requires('YAML::Syck');

build_requires('Test::Dependencies');

auto_install;
WriteAll;
