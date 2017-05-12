use inc::Module::Install;

name            'Perldoc';
all_from        'lib/Perldoc.pm';

requires        'perl' => '5.6.1';
requires        'Spiffy' => '0.29';
requires        'Test::Base' => '0.47';

install_script  'perl-doc';

WriteAll;
