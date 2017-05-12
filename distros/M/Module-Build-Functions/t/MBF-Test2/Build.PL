use strict;
$^W = 1; # Can't use "use warnings", see perl_version below.
use inc::Module::Build::Functions;

module_name         'MBF-Test2';
all_from            'lib/MBF/Test2.pm';
add_to_cleanup      'MBF-Test2-*';

create_build_script;