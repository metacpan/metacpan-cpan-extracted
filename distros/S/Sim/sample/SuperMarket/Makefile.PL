use strict;
use inc::Module::Install;

name            ('SM');
perl_version    ('5.004001');
all_from        ('lib/SM.pm');
license         ('perl');

requires ('Sim' => '0.01');

build_requires ('IPC::Run3');
build_requires ('Test::Base');

&WriteAll;

