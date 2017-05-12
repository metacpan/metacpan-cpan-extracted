use strict;
use inc::Module::Install;

name            ('ModelSim-List');
perl_version    ('5.004');
all_from        ('lib/ModelSim/List.pm');
license         ('perl');

build_requires  ('Test::More');

auto_install;
&WriteAll;

