$^W = 1; # Can't use "use warnings", see perl_version below.
use inc::Module::Build::Functions( build_class => 'Module::Build::SubClass' );

custom_flag 'flag_set';

custom_array    1;
custom_array    1;
custom_array    2;
custom_array    3;

custom_hash     key1 => 'value1';
custom_hash     key2 => 'value2';

module_name         'MBF::Test';
dist_version_from   'lib/MBF/Test.pm';

create_build_script;