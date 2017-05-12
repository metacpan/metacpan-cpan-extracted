use inc::Module::Install;

# Define metadata
name           'Opsview-StatusAPI';
version_from   'lib/Opsview/StatusAPI.pm';
author         'Jose Luis Martinez (jlmartinez@capside.com)';
abstract       'Module to help you query the Opsview Status API';

requires       'Carp' => 0;
requires       'HTTP::Request' => 0;
requires       'LWP::UserAgent' => 0;
requires       'JSON::Any' => 0;


test_requires  'Test::Simple'  => 0;
test_requires  'Test::Pod' => 0;
test_requires  'Test::Exception' => 0;

license 'perl';

WriteAll;
