# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name 'Task-SDK-Perigrin';
all_from 'lib/Task/SDK/Perigrin.pm';

# Specific dependencies
requires 'Task::Kensho';
requires 'Module::Install::Repository';
requires 'Module::Install::AutoManifest';
requires 'Net::Hiveminder';
requires 'CPAN::Uploader';

auto_set_repository;
auto_manifest;
WriteAll;