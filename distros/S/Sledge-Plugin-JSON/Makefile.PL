use strict;
use warnings;
use inc::Module::Install;

name     'Sledge-Plugin-JSON';
all_from 'lib/Sledge/Plugin/JSON.pm';

requires 'JSON::Syck';

use_test_base;
auto_install;
WriteAll;

