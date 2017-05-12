use strict;
use warnings;
use diagnostics;

use Test::More qw/no_plan/;

# load module
BEGIN { use_ok( 'SIOC::Item' ); }

# make tests easier
my $PACKAGE = 'SIOC::Item';

# load package
require_ok( $PACKAGE );

# check existance of documented methods
foreach my $subroutine qw( new created creator modified modifier view_count
    about container add_parent_post add_reply_post ip_address
    previous_by_date next_by_date previous_version next_version) {
        
    can_ok($PACKAGE, $subroutine);

}
