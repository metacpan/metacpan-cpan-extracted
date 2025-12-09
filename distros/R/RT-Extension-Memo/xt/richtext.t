use strict;
use warnings;

use RT::Extension::Memo::Test tests => undef, selenium => 1;

SKIP: {
if (RT::Handle::cmp_version($RT::VERSION, '6.0.0') < 0) {
    skip 'Selenium tests are only avalaible with RT 6';
    fail('Selenium tests are only avalaible with RT 6');
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
my $queue_foo = RT::Extension::Memo::Test->load_or_create_queue( Name => 'Foo' );
my $ticket = RT::Test->create_ticket( Queue => 'Foo', Subject => 'Test Ticket Memo', Requestor => 'root@localhost' );
my $ticket_id = $ticket->id;

# Create memo
$ticket->SetAttribute(Name => 'Memo', Content => 'This is a <strong>memo</strong>');

# Create user
my $user = RT::Test->load_or_create_user(Name => 'user', Password => 'password');
ok(RT::Test->set_rights({Principal => $user, Right => [qw(ShowTicket SeeMemo ModifyMemo ModifySelf)]}), 'Set rights');

# Login user
my ($url, $s) = RT::Extension::Memo::Test->started_ok;
$s->login('user', 'password');

diag "Testing editing plaintext Memo";
{
    # Unset Richtext preference
    $user->SetPreferences($RT::System, {'MemoRichText' => 0});

    # Display ticket
    $s->goto_ticket($ticket_id);
    $s->wait_for_htmx;

    # Click Add Memo
    $s->click('#ActionMemo');

    my $dom = $s->dom;

    my $textarea = $dom->at('#MemoContentEdit');
    is($textarea->val, 'This is a <strong>memo</strong>', 'Edit Memo in textarea without MemoRichText');

    my $no_cke = $dom->at('#MemoContentEdit + div.ck-editor');
    is($no_cke, undef, 'No richtext instance created for editing Memo without MemoRichText');
}

diag "Testing editing richtext Memo";
{
    # Set Richtext preference
    $user->SetPreferences($RT::System, {'MemoRichText' => 1});

    # Display ticket
    $s->goto_ticket($ticket_id);
    $s->wait_for_htmx;

    # Click Add Memo
    $s->click('#ActionMemo');

    my $dom = $s->dom;

    my $textarea = $dom->at('#MemoContentEdit');
    like($textarea->attr('style'), qr(display: none), 'No textarea with MemoRichText');

    my $no_cke = $dom->at('#MemoContentEdit + div.ck-editor');
    ok($no_cke.length, 'Richtext instance created for editing Memo with MemoRichText');
}

$s->logout;
}

done_testing;
