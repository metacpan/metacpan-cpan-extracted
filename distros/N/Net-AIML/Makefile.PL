# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name 'Net-AIML';
all_from 'lib/Net/AIML.pm';

# Specific dependencies
requires 'HTTP::Request::Common' => '1.26';
requires 'LWP::Simple'           => '1.41';
requires 'LWP::UserAgent'        => '2.033';
requires 'XML::Smart'            => '1.006009';

build_requires 'Test::More' => '0.42';

no_index 'directory' => 'examples';

if ( -e 'inc/.author' ) {
    use_test_base;
    use_standard_tests;
}

auto_install;
WriteAll;
