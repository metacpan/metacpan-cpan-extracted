use strict;
use warnings;
use diagnostics;

use Test::More qw/no_plan/;

# load module
BEGIN { use_ok( 'SIOC::Community' ); }

# make tests easier
my $PACKAGE = 'SIOC::Community';

# load package
require_ok( $PACKAGE );

# check existance of documented methods
foreach my $subroutine qw( new ) {
        
    can_ok($PACKAGE, $subroutine);

}

# initialization
{
    my $s = SIOC::Community->new({
        id => '1',
        name => 'Test',
        url => 'http://www.example.com/sioc/community/1'
    });
    is( ref $s, $PACKAGE );
    is( $s->id, 1 );
    is( $s->name, 'Test' );
}
