use strict;
use warnings;
use diagnostics;

use Test::More qw/no_plan/;

# load module
BEGIN { use_ok( 'SIOC::Post' ); }

# make tests easier
my $PACKAGE = 'SIOC::Post';

# load package
require_ok( $PACKAGE );

# check existance of documented methods
foreach my $subroutine qw( new content encoded_content set_attachment
    get_attachment add_related add_sibling note reply_count) {
        
    can_ok($PACKAGE, $subroutine);

}
