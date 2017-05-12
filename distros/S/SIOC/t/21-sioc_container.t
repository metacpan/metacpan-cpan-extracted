use strict;
use warnings;
use diagnostics;

use Test::More qw/no_plan/;

# load module
BEGIN { use_ok( 'SIOC::Container' ); }

# make tests easier
my $PACKAGE = 'SIOC::Container';

# load package
require_ok( $PACKAGE );

# check existance of documented methods
foreach my $subroutine qw( new parent add_child add_item owner 
    add_subscriber ) {
        
    can_ok($PACKAGE, $subroutine);

}
