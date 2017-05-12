use strict;
use warnings;
use diagnostics;

use Test::More qw/no_plan/;

# load module
BEGIN { use_ok( 'SIOC' ); }

# make tests easier
my $PACKAGE = 'SIOC';

# load package
require_ok( $PACKAGE );

# check existance of documented methods
foreach my $subroutine qw( new id name url description comment
    add_topic add_feed add_link type export_rdf 
    fill_template set_template_vars ) {
        
    can_ok($PACKAGE, $subroutine);

}

# initialization
{
    my $s = SIOC->new({
        id => '1',
        name => 'Test',
        url => 'http://www.example.com/sioc/',
    });
    is( ref $s, $PACKAGE );
    is( $s->id, 1 );
    is( $s->name, 'Test' );
}
