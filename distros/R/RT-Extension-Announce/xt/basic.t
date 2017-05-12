use strict;
use warnings;

use RT::Extension::Announce::Test tests => 15;

use_ok('RT::Extension::Announce');

RT->Config->Set( Plugins => 'RT::Extension::Announce' );
RT->Config->Set( CustomFieldValuesSources => 'RT::CustomFieldValues::AnnounceGroups' );

my ( $baseurl, $m ) = RT::Test->started_ok();

ok( $m->login( 'root', 'password' ), 'logged in' );

diag "Create an announcement";
{
    my $t = RT::Test->create_ticket(
        Queue => 'RTAnnounce',
        Subject => 'Test Announcement',
        Content => 'This is a test announcement xcontentx',
        );

    ok( $t->id, 'Create announcement ticket: ' . $t->id);

    $m->get_ok($m->rt_base_url);
    $m->content_like(qr/Test Announcement/, 'Found the test announcement subject');
    $m->content_like(qr/xcontentx/, 'Found the test announcement content');
}
