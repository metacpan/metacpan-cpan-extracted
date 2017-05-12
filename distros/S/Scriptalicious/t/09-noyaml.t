# -*- perl -*-

use lib "t/missing";
use Test::More tests => 2;

use_ok( 'Scriptalicious', -progname => "noyaml" );

{
local(*STDERR);
open STDERR, ">/dev/null";
getconf_f
    ("t/eg.conf",
     ( "something|s" => \$foo,
     )
    );
}

is($foo, undef, 
   "didn't load config without YAML (and didn't die)");
