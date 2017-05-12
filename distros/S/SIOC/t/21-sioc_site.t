use strict;
use warnings;
use diagnostics;

use Test::More qw/no_plan/;

# load module
BEGIN { use_ok( 'SIOC::Site' ); }

# make tests easier
my $PACKAGE = 'SIOC::Site';

# load package
require_ok( $PACKAGE );

# check existance of documented methods
foreach my $subroutine qw( new add_administrator add_forum ) {
        
    can_ok($PACKAGE, $subroutine);

}

# initialization
{
    my $s = SIOC::Site->new({
        id => 'site1',
        name => 'Test',
        url => 'http://www.example.com/'
    });
    is( ref $s, $PACKAGE );
    is( $s->id, 'site1' );
    is( $s->name, 'Test' );
    ok(! eval { $s->add_forum(10) });
    ok(! eval { $s->add_forum({ test => 1}) });
    
    use SIOC::Forum;
    my $forum = SIOC::Forum->new({
        id => 'forum1',
        name => 'Test forum',
        url => 'http://www.example.com/forum/test'
    });
    ok(eval { $s->add_forum($forum) });
}
