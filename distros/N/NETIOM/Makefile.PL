use strict;
use warnings;
use inc::Module::Install;

all_from        'lib/NETIOM.pm';

readme_from;

manifest_skip;

version_check;

requires 'YAML';
requires 'LWP::Simple';
requires 'Term::ReadKey';

install_script  'script/net-iom-mon';

WriteAll;
