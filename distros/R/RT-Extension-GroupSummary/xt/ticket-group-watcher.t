use strict;
use warnings;

use RT::Extension::GroupSummary::Test tests => 10;

use Test::WWW::Mechanize;

my $group = RT::Group->new(RT->SystemUser);
$group->CreateUserDefinedGroup(Name => 'Test Group', Description => 'This group is used for testing');

my $ticket = RT::Ticket->new(RT->SystemUser);
$ticket->Create(Queue => 'General', Subject => 'Test Ticket with group Watcher');
$ticket->AddWatcher(Type => 'Requestor', PrincipalId => $group->id);

my ($base, $m) = RT::Extension::GroupSummary::Test->started_ok;
ok($m->login, 'Logged in agent');
$m->get_ok($m->rt_base_url . 'Ticket/Display.html?id=' . $ticket->id, 'Ticket display page');

$m->text_like(qr{Requestors:\s*Test Group}, 'Requestor is group');

$m->links_ok('/Group/Summary.html?id=' . $group->id, 'Link to Group Summary page');

undef $m;
