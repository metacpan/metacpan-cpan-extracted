use strict;
use warnings;

use RT::Extension::Memo::Test tests => 11;
RT->Config->Set('DevelMode', 1);

use WWW::Mechanize::PhantomJS;

# Create tickets
my $first_ticket = RT::Ticket->new(RT->SystemUser);
my ($first_ticket_id, $first_ticket_msg) = $first_ticket->Create(Queue => 'General', Subject => 'Test Ticket Memo');
my $second_ticket = RT::Ticket->new(RT->SystemUser);
my ($second_ticket_id, $second_ticket_msg) = $second_ticket->Create(Queue => 'General', Subject => 'Test Ticket Memo To Merge');

# Create memos
$first_ticket->SetAttribute(Name => 'Memo', Content => 'This is a <strong>memo</strong>');
$second_ticket->SetAttribute(Name => 'Memo', Content => 'This is a memo <strong>to merge</strong>');

# Create user
my $user = RT::Test->load_or_create_user(Name => 'user', Password => 'password');
ok(RT::Test->set_rights({Principal => $user, Right => [qw(ShowTicket SeeMemo ModifyMemo ModifySelf)]}), 'Set rights');

# Login user
my ($base, $m) = RT::Extension::Memo::Test->started_ok;
my $mjs = WWW::Mechanize::PhantomJS->new();
$mjs->get($m->rt_base_url . '?user=user;pass=password');

# Set Richtext preference
$user->SetPreferences($RT::System, {'MemoRichText' => 1});

# Check first ticket memo
$mjs->get($m->rt_base_url . 'Ticket/Display.html?id=' . $first_ticket->id);
my $first_memo = $mjs->selector('#MemoContent', single => 1);
is($first_memo->get_attribute('innerHTML'), 'This is a <strong>memo</strong>', 'First memo');

# Check second ticket memo
$mjs->get($m->rt_base_url . 'Ticket/Display.html?id=' . $second_ticket->id);
my $second_memo = $mjs->selector('#MemoContent', single => 1);
is($second_memo->get_attribute('innerHTML'), 'This is a memo <strong>to merge</strong>', 'Second memo');

# Merge second ticket into first ticket
my ($id, $msg) = $second_ticket->MergeInto($first_ticket->id);
ok($id, $msg);

# Check merged memo
$mjs->get($m->rt_base_url . 'Ticket/Display.html?id=' . $first_ticket->id);
my $merged_memo = $mjs->selector('#MemoContent', single => 1);
is($merged_memo->get_attribute('innerHTML'), 'This is a <strong>memo</strong><br>This is a memo <strong>to merge</strong>', 'Merged memo');
