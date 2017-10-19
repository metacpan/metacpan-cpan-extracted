use strict;
use warnings;

use RT::Extension::Memo::Test tests => 19;

use Test::WWW::Mechanize;

# Create ticket
my $ticket = RT::Ticket->new(RT->SystemUser);
my ($ticket_id, $ticket_msg) = $ticket->Create(Queue => 'General', Subject => 'Test Ticket Memo');

# Create memo
$ticket->SetAttribute(Name => 'Memo', Content => "This is a memo");

# Create user
my $user = RT::Test->load_or_create_user(Name => 'user', Password => 'password');
ok(RT::Test->set_rights({Principal => $user, Right => [qw(ShowTicket)]}), 'Set ShowTicket right');

# Login user
my ($base, $m) = RT::Extension::Memo::Test->started_ok;
ok($m->login('user', 'password'), 'Logged in agent');

# Display ticket with ShowTicket rights granted to user
$m->get_ok($m->rt_base_url . 'Ticket/Display.html?id=' . $ticket->id, 'Ticket display page with ShowTicket right');
$m->content_lacks('<div class="memo-content" style="width: calc&#40;100% - 40px&#41;; height: 205px;" name="MemoContent" id="MemoContent" data-objectclass="RT::Ticket" data-objectid="1">This is a memo</div>', 'Hide memo with ShowTicket right');
$m->content_lacks('<div class="submit" id ="MemoSubmit">', 'Hide edit memo buttons with ShowTicket right');

# Display ticket with SeeMemo rights granted to user
ok(RT::Test->add_rights({Principal => $user, Right => [qw(SeeMemo)]}), 'Add SeeMemo right');
$m->get_ok($m->rt_base_url . 'Ticket/Display.html?id=' . $ticket->id, 'Ticket display page with SeeMemo right');
$m->content_contains('<div class="memo-content" style="width: calc&#40;100% - 40px&#41;; height: 205px;" name="MemoContent" id="MemoContent" data-objectclass="RT::Ticket" data-objectid="1">This is a memo</div>', 'Display memo with SeeMemo right');
$m->content_lacks('<div class="submit" id ="MemoSubmit">', 'Hide edit memo buttons with SeeMemo right');

# Display ticket with ModifyMemo rights granted to user
ok(RT::Test->add_rights({Principal => $user, Right => [qw(ModifyMemo)]}), 'Add ModifyMemo right');
$m->get_ok($m->rt_base_url . 'Ticket/Display.html?id=' . $ticket->id, 'Ticket display page with ModifyMemo right');
$m->content_contains('<div class="memo-content" style="width: calc&#40;100% - 40px&#41;; height: 205px;" name="MemoContent" id="MemoContent" data-objectclass="RT::Ticket" data-objectid="1">This is a memo</div>', 'Display memo with SeeMemo right');
$m->content_contains('<div class="submit" id ="MemoSubmit">', 'Display edit memo buttons with ModifyMemo right');
