BEGIN {
   use strict;
   use warnings;
   use Test::More;
   use Test::Exception;
   use FindBin;
   use lib "$FindBin::Bin/lib";

   eval "use Sub::Exporter";
   plan $@
       ? ( skip_all => "Tests require Sub::Exporter" )
       : ( tests => 3 );
}

use SubExporterCompatibility qw(MyStr something);

ok MyStr->check('aaa'), "Correctly passed";
ok !MyStr->check([1]), "Correctly fails";
ok something(), "Found the something method";
