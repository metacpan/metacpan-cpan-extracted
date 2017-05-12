use inc::Module::Install;

# Define metadata
name     'String-REPartition';
all_from 'lib/String/REPartition.pm';

# Specific dependencies
build_requires('Test::Pod');
build_requires('Test::Pod::Coverage');

auto_install;
WriteAll;
