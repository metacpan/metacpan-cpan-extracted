require 5.008001;

use Config;

# shouldn't this die or something?
warn <<WHOA unless $Config{useperlio};
    *** WHOA THERE!!! ***
    This is not a perlio-enabled perl !

    This module will not function with this perl !
WHOA


use inc::Module::Install;

name 'PerlIO-via-json';
all_from 'lib/PerlIO/via/json.pm';

requires          'XML::XML2JSON'      => '0.05';
recommends        'JSON::XS'           => '2.231';

WriteAll;
