use warnings;
use strict;
use Test::More tests => 11;

BEGIN { use_ok('Siebel::COM::Constants') }

is( FORWARD_BACKWARD, 256, 'FORWARD_BACKWARD returns the correct value' );
is( FORWARD_ONLY,     257, 'FORWARD_ONLY returns the correct value' );
is( SALES_REP_VIEW,   0,   'SALES_REP_VIEW returns the correct value' );
is( MANAGER_VIEW,     1,   'MANAGER_VIEW returns the correct value' );
is( PERSONAL_VIEW,    2,   'PERSONAL_VIEW returns the correct value' );
is( ALL_VIEW,         3,   'ALL_VIEW returns the correct value' );
is( ORG_VIEW,         5,   'ORG_VIEW returns the correct value' );
is( GROUP_VIEW,       7,   'GROUP_VIEW returns the correct value' );
is( CATALOG_VIEW,     8,   'CATALOG_VIEW returns the correct value' );
is( SUB_ORG_VIEW,     9,   'SUB_ORG_VIEW returns the correct value' );

