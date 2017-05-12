use strict;
use warnings;

use Test::More tests => 1;

use Parse::FieldPath qw/extract_fields/;
can_ok( __PACKAGE__, 'extract_fields' );
