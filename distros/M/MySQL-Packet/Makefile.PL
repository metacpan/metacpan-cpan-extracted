use inc::Module::Install;

name            'MySQL-Packet';
all_from        'lib/MySQL/Packet.pm';

#requires        'Carp'              => 0;
build_requires  'Test::More'        => '0.42';

#no_index        'directory'         => 'demos';

#install_script  'bin/myscript';

auto_install;
WriteAll;

