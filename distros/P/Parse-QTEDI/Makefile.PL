use 5.005;

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name            'Parse-QTEDI';
author          'Dongxu Ma <dongxu.ma@gmail.com>';
license         'artistic';
perl_version    '5.005';
abstract_from   'lib/Parse/QTEDI.pod';
version_from    'lib/Parse/QTEDI.pm';
#all_from        'lib/Parse/QTEDI.pm';

# Specific dependencies
requires        'Carp'              => 0;
requires        'Exporter'          => 0;
requires        'Fcntl'             => 0;
requires        'Parse::RecDescent' => '1.94';
requires        'YAML::Syck'        => '0.94';
build_requires  'Test::More'        => '0.42';
#requires_external_bin ;
#recommends      'Your::OtherModule' => '0.01';

#no_index        'directory'         => 'examples';

install_script  'bin/parse_qtedi_header';
install_script  'bin/format_qtedi_production';

auto_install;
WriteAll;
