use strict;
use warnings;

use RT::Extension::Memo::Test tests => 11;
RT->Config->Set('DevelMode', 1);

use WWW::Mechanize::PhantomJS;

# Create ticket
my $ticket = RT::Ticket->new(RT->SystemUser);
my ($ticket_id, $ticket_msg) = $ticket->Create(Queue => 'General', Subject => 'Test Ticket Memo');

# Create memo
$ticket->SetAttribute(Name => 'Memo', Content => 'This is a <strong>memo</strong>');

# Create user
my $user = RT::Test->load_or_create_user(Name => 'user', Password => 'password');
ok(RT::Test->set_rights({Principal => $user, Right => [qw(ShowTicket SeeMemo ModifyMemo ModifySelf)]}), 'Set rights');

# Login user
my ($base, $m) = RT::Extension::Memo::Test->started_ok;
my $mjs = WWW::Mechanize::PhantomJS->new();
$mjs->get($m->rt_base_url . '?user=user;pass=password');

# Unset Richtext preference
$user->SetPreferences($RT::System, {'MemoRichText' => 0});

# Edit plaintext memo
$mjs->get($m->rt_base_url . 'Ticket/Display.html?id=' . $ticket->id);
my $action_button = $mjs->selector('#ActionMemo', single => 1);
$mjs->click($action_button);
my $textarea = $mjs->selector('#MemoContentEdit', single => 1);
is($textarea->get_value, 'This is a <strong>memo</strong>', 'Edit memo in textarea');
my ($no_cke, $no_type) = $mjs->eval('Object.keys(CKEDITOR.instances).length');
is($no_cke, 0, 'No richtext instance created for editing memo');

# Set Richtext preference
$user->SetPreferences($RT::System, {'MemoRichText' => 1});

$mjs->get($m->rt_base_url . 'Ticket/Display.html?id=' . $ticket->id);
$action_button = $mjs->selector('#ActionMemo', single => 1);
$mjs->click($action_button);
$textarea = $mjs->selector('#MemoContentEdit', single => 1);
ok($textarea->is_hidden, 'No textarea');
my ($cke_id, $type) = $mjs->eval('CKEDITOR.instances.MemoContentEdit.id');
is($cke_id, 'cke_1', 'Richtext instance created for editing memo');
