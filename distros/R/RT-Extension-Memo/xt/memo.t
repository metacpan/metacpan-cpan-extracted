use strict;
use warnings;

use RT::Extension::Memo::Test tests => 46;
RT->Config->Set('DevelMode', 1);

use WWW::Mechanize::PhantomJS;

my $ticket = RT::Ticket->new(RT->SystemUser);
my ($ticket_id, $ticket_msg) = $ticket->Create(Queue => 'General', Subject => 'Test Ticket Memo');

my ($base, $m) = RT::Extension::Memo::Test->started_ok;
my $mjs = WWW::Mechanize::PhantomJS->new();
$mjs->get($m->rt_base_url . '?user=root;pass=password');

# Display ticket
$mjs->get($m->rt_base_url . 'Ticket/Display.html?id=' . $ticket->id);

$ticket->ClearAttributes;
my $attr = $ticket->FirstAttribute('Memo');
is($attr, undef, 'No attribute on new ticket');
my $div = $mjs->selector('#MemoContent', single => 1);
ok($div->is_hidden, 'Memo hidden on new ticket');
my $textarea = $mjs->selector('#MemoContentEdit', single => 1);
ok($textarea->is_hidden, 'Memo edition hidden on new ticket');
my $action_button = $mjs->selector('#ActionMemo', single => 1);
is($action_button->get_attribute('data-action'), 'Add', 'Action button is Add on new ticket');
my $cancel_button = $mjs->selector('#CancelMemo', single => 1);
ok($cancel_button->is_hidden('data-action'), 'Cancel button hidden on new ticket');

# Click Add
$mjs->click($action_button);

$ticket->ClearAttributes;
$attr = $ticket->FirstAttribute('Memo');
is($attr, undef, 'No attribute on edit new ticket');
$div = $mjs->selector('#MemoContent', single => 1);
ok($div->is_hidden, 'Memo hidden on edit new ticket');
$textarea = $mjs->selector('#MemoContentEdit', single => 1);
is($textarea->get_value, '', 'Memo edition empty on edit new ticket');
$action_button = $mjs->selector('#ActionMemo', single => 1);
is($action_button->get_attribute('data-action'), 'Save', 'Action button is Save on edit new ticket');
$cancel_button = $mjs->selector('#CancelMemo', single => 1);
ok($cancel_button->is_displayed, 'Cancel button displayed on edit new ticket');

# Fill textarea, click Cancel
$mjs->field($textarea, 'This is a memo');
$mjs->click($cancel_button);

$ticket->ClearAttributes;
$attr = $ticket->FirstAttribute('Memo');
is($attr, undef, 'No attribute on canceled memo');
$div = $mjs->selector('#MemoContent', single => 1);
ok($div->is_hidden, 'Memo hidden on canceled memo');
$textarea = $mjs->selector('#MemoContentEdit', single => 1);
ok($textarea->is_hidden, 'Memo edition hidden on canceled memo');
$action_button = $mjs->selector('#ActionMemo', single => 1);
is($action_button->get_attribute('data-action'), 'Add', 'Action button is Add on canceled memo');
$cancel_button = $mjs->selector('#CancelMemo', single => 1);
ok($cancel_button->is_hidden('data-action'), 'Cancel button hidden on canceled memo');

# Click Add, fill textarea, click Save
$mjs->click($action_button);
$mjs->field($textarea, 'This is a memo');
$mjs->click($action_button);

$ticket->ClearAttributes;
$attr = $ticket->FirstAttribute('Memo');
is($attr->Content, 'This is a memo', 'Attribute set on saved memo');
$div = $mjs->selector('#MemoContent', single => 1);
is($div->get_text, 'This is a memo', 'Memo set on saved memo');
$textarea = $mjs->selector('#MemoContentEdit', single => 1);
ok($textarea->is_hidden, 'Memo edition hidden on saved memo');
$action_button = $mjs->selector('#ActionMemo', single => 1);
is($action_button->get_attribute('data-action'), 'Edit', 'Action button is Edit on saved memo');
$cancel_button = $mjs->selector('#CancelMemo', single => 1);
ok($cancel_button->is_hidden('data-action'), 'Cancel button hidden on saved memo');

# Modify attribute
$ticket->SetAttribute(Name => 'Memo', Content => "This is a memo\nin two lines");

$ticket->ClearAttributes;
$attr = $ticket->FirstAttribute('Memo');
is($attr->Content, "This is a memo\nin two lines", 'Attribute set on modified attribute');
$div = $mjs->selector('#MemoContent', single => 1);
is($div->get_text, 'This is a memo', 'Memo set on modified attribute');
$textarea = $mjs->selector('#MemoContentEdit', single => 1);
ok($textarea->is_hidden, 'Memo edition hidden on modified attribute');
$action_button = $mjs->selector('#ActionMemo', single => 1);
is($action_button->get_attribute('data-action'), 'Edit', 'Action button is Edit on modified attribute');
$cancel_button = $mjs->selector('#CancelMemo', single => 1);
ok($cancel_button->is_hidden('data-action'), 'Cancel button hidden on modified attribute');

# Click Edit
$mjs->click($action_button);

$ticket->ClearAttributes;
$attr = $ticket->FirstAttribute('Memo');
is($attr->Content, "This is a memo\nin two lines", 'Attribute set on edit modified memo');
$div = $mjs->selector('#MemoContent', single => 1);
ok($div->is_hidden, 'Memo hidden on edit modified memo');
$textarea = $mjs->selector('#MemoContentEdit', single => 1);
is($textarea->get_value, "This is a memo\nin two lines", 'Memo edition set on edit modified memo');
$action_button = $mjs->selector('#ActionMemo', single => 1);
is($action_button->get_attribute('data-action'), 'Save', 'Action button is Save on edit modified memo');
$cancel_button = $mjs->selector('#CancelMemo', single => 1);
ok($cancel_button->is_displayed, 'Cancel button displayed on edit memo attribute');

# Reload ticket display
$mjs->get($m->rt_base_url . 'Ticket/Display.html?id=' . $ticket->id);

$ticket->ClearAttributes;
$attr = $ticket->FirstAttribute('Memo');
is($attr->Content, "This is a memo\nin two lines", 'Attribute set on reload modified memo');
$div = $mjs->selector('#MemoContent', single => 1);
is($div->get_text, "This is a memo\nin two lines", 'Memo set on reload modified attribute');
$textarea = $mjs->selector('#MemoContentEdit', single => 1);
ok($textarea->is_hidden, 'Memo edition hidden on reload modified attribute');
$action_button = $mjs->selector('#ActionMemo', single => 1);
is($action_button->get_attribute('data-action'), 'Edit', 'Action button is Edit on reload modified memo');
$cancel_button = $mjs->selector('#CancelMemo', single => 1);
ok($cancel_button->is_hidden, 'Cancel button hidden on reload memo attribute');

# Click edit, empty textarea, click Save
$mjs->click($action_button);
$mjs->field($textarea, '');
$mjs->click($action_button);

$ticket->ClearAttributes;
$attr = $ticket->FirstAttribute('Memo');
is($attr->Content, '', 'Attribute empty on empty attribute');
$div = $mjs->selector('#MemoContent', single => 1);
ok($div->is_hidden, 'Memo hidden on empty attribute');
$textarea = $mjs->selector('#MemoContentEdit', single => 1);
ok($textarea->is_hidden, 'Memo edition hidden on empty attribute');
$action_button = $mjs->selector('#ActionMemo', single => 1);
is($action_button->get_attribute('data-action'), 'Add', 'Action button is Add on empty attribute');
$cancel_button = $mjs->selector('#CancelMemo', single => 1);
ok($cancel_button->is_hidden('data-action'), 'Cancel button hidden on empty attribute');
