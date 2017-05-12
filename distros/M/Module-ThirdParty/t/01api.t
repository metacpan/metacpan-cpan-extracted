use strict;
use Test::More;
use Module::ThirdParty;

plan tests => 2;

can_ok( 'Module::ThirdParty', 'is_3rd_party'       );
can_ok( 'Module::ThirdParty', 'module_information' );
