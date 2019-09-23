use warnings;
use strict;

use Test::More;
use PGObject::Util::DBAdmin;

plan tests => 3;


is_deeply( PGObject::Util::DBAdmin->verify_helpers,
           {
               map { $_ => 1 }
               keys %PGObject::Util::DBAdmin::helper_paths
           },
           'Without arguments, test all helpers');

is_deeply( PGObject::Util::DBAdmin->verify_helpers(
               operations => [ keys %PGObject::Util::DBAdmin::helpers ]
           ),
           {
               map { $_ => 1 }
               keys %PGObject::Util::DBAdmin::helper_paths
           },
           'With the "operations" argument, test the associated helpers');

is_deeply( PGObject::Util::DBAdmin->verify_helpers(
               helpers => [ keys %PGObject::Util::DBAdmin::helper_paths ]
           ),
           {
               map { $_ => 1 }
               keys %PGObject::Util::DBAdmin::helper_paths
           },
           'With the "helpers" argument, test the associated helpers');
