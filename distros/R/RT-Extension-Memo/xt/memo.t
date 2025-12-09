use strict;
use warnings;
use Test::Deep;

use RT::Extension::Memo::Test tests => undef, selenium => 1;

SKIP: {
if (RT::Handle::cmp_version($RT::VERSION, '6.0.0') < 0) {
    skip 'Selenium test are only avalaible with RT 6';
    fail('Selenium test are only avalaible with RT 6');
}

# Add Memo in Ticket Display page layout
my $mapping = RT->Config->Get('PageLayoutMapping') || {};
my $ticket_display_mapping = $mapping->{'RT::Ticket'}{Display};
my $layout_name;
for (my $i=0; $i < scalar(@$ticket_display_mapping); $i++) {
    my $elt = $ticket_display_mapping->[$i];
    if ($elt->{Type} eq 'Default') {
        $layout_name = $elt->{Layout};
        $elt->{Layout} = 'MemoLayout';
        last;
    }
}

my $page_layouts = RT->Config->Get('PageLayouts') || {};
my $ticket_display_layout = $page_layouts->{'RT::Ticket'}{Display}{$layout_name};
my @clone_layout = @$ticket_display_layout;

for (my $i=0; $i < scalar(@clone_layout); $i++) {
    my $elts = $clone_layout[$i]->{Elements};
    for (my $j=0; $j < scalar(@$elts); $j++) {
        if ($elts->[$j] eq 'History') {
            splice @{$clone_layout[$i]->{Elements}}, $j, 0, 'Memo';
            last;
        }
    }
}
$page_layouts->{'RT::Ticket'}{Display}{MemoLayout} = \@clone_layout;

# Create queue and ticket
my $queue_foo = RT::Extension::Memo::Test->load_or_create_queue(Name => 'Foo');
my $ticket = RT::Test->create_ticket(Queue => 'Foo', Subject => 'Test Ticket Memo', Requestor => 'root@localhost');
my $ticket_id = $ticket->id;

my ($url, $s) = RT::Extension::Memo::Test->started_ok;
$s->login();

# Unset Richtext preference
my $user = RT::Test->load_or_create_user(Name => 'root');
$user->SetPreferences($RT::System, {'MemoRichText' => 0});

# Display ticket
$s->goto_ticket($ticket_id);
$s->wait_for_htmx;

diag "Testing Memo area closed with no Memo";
{
    my $dom = $s->dom;

    $ticket->ClearAttributes;
    my $attr = $ticket->FirstAttribute('Memo');
    is($attr, undef, 'No attribute on new ticket');

    my $div = $dom->at('#MemoContent');
    like($div->attr('style'), qr(display: none), 'Memo hidden on new ticket');
    my $textarea = $dom->at('#MemoContentEdit');
    like($textarea->attr('style'), qr(display: none), 'Memo hidden on new ticket');

    my $action_button = $dom->at('#ActionMemo');
    is($action_button->attr('data-action'), 'Add', 'Action button is Add on new ticket');
    my $cancel_button = $dom->at('#CancelMemo');
    like($cancel_button->attr('style'), qr(display: none), 'Cancel button hidden on new ticket');
}

diag "Testing Memo area opened when adding a new Memo";
{
    $s->click('#ActionMemo');

    my $dom = $s->dom;

    $ticket->ClearAttributes;
    my $attr = $ticket->FirstAttribute('Memo');
    is($attr, undef, 'No attribute on editing new ticket');

    my $div = $dom->at('#MemoContent');
    like($div->attr('style'), qr(display: none), 'Memo hidden on editing new ticket');
    my $textarea = $dom->at('#MemoContentEdit');
    is($textarea->val, '', 'Memo edition empty on editing new ticket');

    my $action_button = $dom->at('#ActionMemo');
    is($action_button->attr('data-action'), 'Save', 'Action button is Save on editing new ticket');
    my $cancel_button = $dom->at('#CancelMemo');
    unlike($cancel_button->attr('style'), qr(display: none), 'Cancel button displayed on editing new ticket');
}

diag "Testing Memo area closed when canceling Memo";
{
    $s->click('#CancelMemo');

    my $dom = $s->dom;

    $ticket->ClearAttributes;
    my $attr = $ticket->FirstAttribute('Memo');
    is($attr, undef, 'No attribute on canceled Memo');

    my $div = $dom->at('#MemoContent');
    like($div->attr('style'), qr(display: none), 'Memo hidden on canceled Memo');
    my $textarea = $dom->at('#MemoContentEdit');
    like($textarea->attr('style'), qr(display: none), 'Memo edition hidden on canceled Memo');

    my $action_button = $dom->at('#ActionMemo');
    is($action_button->attr('data-action'), 'Add', 'Action button is Add on canceled Memo');
    my $cancel_button = $dom->at('#CancelMemo');
    like($cancel_button->attr('style'), qr(display: none), 'Cancel button hidden on canceled Memo');
}

diag "Testing adding Memo";
{
    $s->click('#ActionMemo');
    my $textarea_s = $s->find_element_by_id('MemoContentEdit');
    $textarea_s->send_keys('This is a memo');
    $s->click('#ActionMemo');

    my $dom = $s->dom;

    $ticket->ClearAttributes;
    my $attr = $ticket->FirstAttribute('Memo');
    is($attr->Content, 'This is a memo', 'Attribute set on saved Memo');

    my $div = $dom->at('#MemoContent');
    is($div->text, 'This is a memo', 'Memo set on saved Memo');
    my $textarea = $dom->at('#MemoContentEdit');
    like($textarea->attr('style'), qr(display: none), 'Memo edition hidden on saved Memo');

    my $action_button = $dom->at('#ActionMemo');
    is($action_button->attr('data-action'), 'Edit', 'Action button is Edit on saved Memo');
    my $cancel_button = $dom->at('#CancelMemo');
    like($cancel_button->attr('style'), qr(display: none), 'Cancel button hidden on saved Memo');
}

diag "Testing modifying attribute";
{
    $ticket->SetAttribute(Name => 'Memo', Content => "This is a modified memo");

    my $dom = $s->dom;

    $ticket->ClearAttributes;
    my $attr = $ticket->FirstAttribute('Memo');
    is($attr->Content, 'This is a modified memo', 'Attribute set on modified attribute');

    my $div = $dom->at('#MemoContent');
    is($div->text, 'This is a memo', 'Memo set on modified attribute');
    my $textarea = $dom->at('#MemoContentEdit');
    like($textarea->attr('style'), qr(display: none), 'Memo edition hidden on modified attribute');

    my $action_button = $dom->at('#ActionMemo');
    is($action_button->attr('data-action'), 'Edit', 'Action button is Edit on modified attribute');
    my $cancel_button = $dom->at('#CancelMemo');
    like($cancel_button->attr('style'), qr(display: none), 'Cancel button hidden on modified attribute');
}

diag "Testing editing modified Memo";
{
    $s->click('#ActionMemo');

    my $dom = $s->dom;

    $ticket->ClearAttributes;
    my $attr = $ticket->FirstAttribute('Memo');
    is($attr->Content, 'This is a modified memo', 'Attribute set on editing modified Memo');

    my $div = $dom->at('#MemoContent');
    like($div->attr('style'), qr(display: none), 'Memo hidden on editing modified Memo');
    my $textarea_s = $s->find_element_by_id('MemoContentEdit');
    is($textarea_s->get_attribute('value'), 'This is a modified memo', 'Memo edition set on editing modified Memo');

    my $action_button = $dom->at('#ActionMemo');
    is($action_button->attr('data-action'), 'Save', 'Action button is Save on editing modified Memo');
    my $cancel_button = $dom->at('#CancelMemo');
    unlike($cancel_button->attr('style'), qr(display: none), 'Cancel button displayed on editing modified Memo');
}

diag "Testing reloading ticket with modified Memo";
{
    $s->goto_ticket($ticket_id);
    $s->wait_for_htmx;

    my $dom = $s->dom;

    $ticket->ClearAttributes;
    my $attr = $ticket->FirstAttribute('Memo');
    is($attr->Content, 'This is a modified memo', 'Attribute set on reloading modified Memo');

    my $div = $dom->at('#MemoContent');
    is($div->text, 'This is a modified memo', 'Memo hidden on reloading modified Memo');
    my $textarea = $dom->at('#MemoContentEdit');
    like($textarea->attr('style'), qr(display: none), 'Memo edition hidden on reloading modified Memo');

    my $action_button = $dom->at('#ActionMemo');
    is($action_button->attr('data-action'), 'Edit', 'Action button is Edit on reloading modified Memo');
    my $cancel_button = $dom->at('#CancelMemo');
    like($cancel_button->attr('style'), qr(display: none), 'Cancel button hidden on reloading modified Memo');
}

diag "Testing modifying to empty Memo";
{
    $s->click('#ActionMemo');
    my $textarea_s = $s->find_element_by_id('MemoContentEdit');
    use Selenium::Remote::WDKeys;
    my @keys = (KEYS->{'end'});
    my $len = length('This is a modified memo');
    for (my $i = 0; $i < $len; $i++) {
        push @keys, KEYS->{'backspace'};
    }
    $textarea_s->send_keys(@keys);
    $s->click('#ActionMemo');

    my $dom = $s->dom;

    $ticket->ClearAttributes;
    my $attr = $ticket->FirstAttribute('Memo');
    is($attr->Content, '', 'Attribute set on empty Memo');

    my $div = $dom->at('#MemoContent');
    like($div->attr('style'), qr(display: none), 'Memo content hidden on empty Memo');
    my $textarea = $dom->at('#MemoContentEdit');
    like($textarea->attr('style'), qr(display: none), 'Memo edition hidden on empty Memo');

    my $action_button = $dom->at('#ActionMemo');
    is($action_button->attr('data-action'), 'Add', 'Action button is Add on empty Memo');
    my $cancel_button = $dom->at('#CancelMemo');
    like($cancel_button->attr('style'), qr(display: none), 'Cancel button hidden on empty Memo');
}

$s->logout;
}

done_testing;
