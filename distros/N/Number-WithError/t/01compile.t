#!/usr/bin/perl -w

# Compile-testing for Number::WithError

use strict;
use Test::More tests => 10;

ok( $] > 5.005, 'Perl version is 5.005 or newer' );
use_ok( 'Number::WithError' );

# Exports?
ok( ! defined(&witherror),     'Number::WithError does not export &witherror by default.'       );
ok( ! defined(&witherror_big), 'Number::WithError does not export &witherror_big by default.'   );

Number::WithError->import('witherror');
ok( defined(&witherror),         'Number::WithError exports &witherror on demand.'              );

Number::WithError->import('witherror_big');
ok( defined(&witherror_big),     'Number::WithError exports &witherror_big on demand.'          );


package MyTestPackage;
main::ok( ! defined(&witherror),     'Switched to clean package. no witherror()'                            );
main::ok( ! defined(&witherror_big), 'Switched to clean package. no witherror_big()'                        );

Number::WithError->import(':all');
main::ok( defined(&witherror),         'Number::WithError exports &witherror on demand via :all.'     );
main::ok( defined(&witherror_big),     'Number::WithError exports &witherror_big on demand via :all.' );



