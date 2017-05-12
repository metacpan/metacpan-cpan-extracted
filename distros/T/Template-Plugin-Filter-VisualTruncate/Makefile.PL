use inc::Module::Install;

# Define metadata
name            'Template-Plugin-Filter-VisualTruncate';
all_from        'lib/Template/Plugin/Filter/VisualTruncate.pm';

# Specific dependencies
build_requires  'Test::More'         => '0.42';
build_requires  'Test::Base'         => 0;

requires        'Encode'             => '2.23';
requires        'Template'           => 0;
requires        'Text::CharWidth'    => '0.04';
requires        'Text::VisualWidth'  => '0.01';
requires        'UNIVERSAL::require' => 0;

recommends      'Your::OtherModule'  => '0.01';

no_index        'directory'         => 'examples';

auto_install;
WriteAll;
