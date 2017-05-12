use strict;
use warnings;
use diagnostics;

use Test::More qw/no_plan/;

# load module
BEGIN { use_ok( 'SIOC::Forum' ); }

# make tests easier
my $PACKAGE = 'SIOC::Forum';

# load package
require_ok( $PACKAGE );

# check existance of documented methods
foreach my $subroutine qw( new host add_moderator add_scope ) {
        
    can_ok($PACKAGE, $subroutine);

}
