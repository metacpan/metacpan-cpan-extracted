#!/usr/bin/perl -w

# Compile-testing for Number::WithError::LaTeX

use strict;
use Test::More tests => 10;

ok( $] > 5.008, 'Perl version is 5.008 or newer' );
use_ok( 'Number::WithError::LaTeX' );

# Exports?
ok( ! defined(&witherror),     'Number::WithError::LaTeX does not export &witherror by default.'       );
ok( ! defined(&witherror_big), 'Number::WithError::LaTeX does not export &witherror_big by default.'   );

Number::WithError::LaTeX->import('witherror');
ok( defined(&witherror),         'Number::WithError::LaTeX exports &witherror on demand.'              );

Number::WithError::LaTeX->import('witherror_big');
ok( defined(&witherror_big),     'Number::WithError::LaTeX exports &witherror_big on demand.'          );


package MyTestPackage;
main::ok( ! defined(&witherror),     'Switched to clean package. no witherror()'                            );
main::ok( ! defined(&witherror_big), 'Switched to clean package. no witherror_big()'                        );

Number::WithError::LaTeX->import(':all');
main::ok( defined(&witherror),         'Number::WithError::LaTeX exports &witherror on demand via :all.'     );
main::ok( defined(&witherror_big),     'Number::WithError::LaTeX exports &witherror_big on demand via :all.' );



