use strict;
use warnings;
use diagnostics;

use Test::More qw/no_plan/;

# load module
BEGIN { use_ok( 'SIOC::User' ); }

# make tests easier
my $PACKAGE = 'SIOC::User';

# load package
require_ok( $PACKAGE );

# check existance of documented methods
foreach my $subroutine qw( new ) {
        
    can_ok($PACKAGE, $subroutine);

}

# initialization
{
    my $s = SIOC::User->new({
        id => '1',
        name => 'John Doe',
        url => 'http://www.example.com/sioc/community/1',
        foaf_uri => 'foaf',
        email => 'user@example.com',
    });
    is( ref $s, $PACKAGE );
    is( $s->id, 1 );
    is( $s->name, 'John Doe' );
}
