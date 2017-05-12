use inc::Module::Install;

name     'Net-DBus-Skype';
all_from 'lib/Net/DBus/Skype.pm';
author   'Evan Carroll <me@evancarroll.com>';
requires 'Net::DBus';
requires 'Moose';
requires 'Env';


prompt_script 'script/skype-action-handler';
install_script 'script/skype-simple-dialer';

build_requires 'Test::More';

auto_install;

WriteAll;

