use strict;
use warnings;

use RT::Extension::Memo::Test tests => undef;

SKIP: {
if (RT::Handle::cmp_version($RT::VERSION, '6.0.0') < 0) {
    skip 'Selenium tests are only avalaible with RT 6';
    fail('Selenium tests are only avalaible with RT 6');
}

# Ignore warnings for deprecated BeforeShowHistory callback on page /Ticket/Display.html
# This callback is disabled in RT::Extension::Memo for RT 6 and
# BeforeWidget in /Ticket/Widgets/Display/History is actually used
no warnings 'redefine';
my $old_Deprecated = \&RT::Deprecated;
*RT::Deprecated = sub {
    my ($self, %args) = @_;
    unless ($args{Message} && $args{Message} eq 'The callback BeforeShowHistory on page /Ticket/Display.html is deprecated') {
        return $old_Deprecated->(@_);
    }
};

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
$ticket->SetAttribute(Name => 'Memo', Content => "This is a memo");

# Create user
my $user = RT::Test->load_or_create_user(Name => 'user', Password => 'password');

# Login user
my ($url, $m) = RT::Extension::Memo::Test->started_ok;
$m->login('user', 'password');

# Unset Richtext preference
$user->SetPreferences($RT::System, {'MemoRichText' => 0});

diag "Testing display ticket with ShowTicket right granted to user but not SeeMemo right";
{
    # Add ShowTicket right
    ok(RT::Test->set_rights({Principal => $user, Right => [qw(ShowTicket)]}), 'Set ShowTicket right');

    # Display ticket
    $m->goto_ticket($ticket_id);

    my $dom = $m->dom;

    my $div = $dom->at('#MemoContent');
    ok(!$div, 'Hide Memo with ShowTicket right but not SeeMemo right');

    my $textarea = $dom->at('#MemoContentEdit');
    ok(!$div, 'Hide edit Memo with ShowTicket right but not SeeMemo right');
}

diag "Testing display ticket with SeeMemo rights granted to user";
{
    # Add SeeMemo right
    ok(RT::Test->add_rights({Principal => $user, Right => [qw(SeeMemo)]}), 'Add SeeMemo right');

    # Display ticket
    $m->goto_ticket($ticket_id);

    my $dom = $m->dom;

    my $div = $dom->at('#MemoContent');
    ok($div.length, 'Show Memo with SeeMemo right');

    my $textarea = $dom->at('#MemoContentEdit');
    ok(!$textarea, 'Hide edit Memo with SeeMemo right but not ModifyMemo right');
}

diag "Testing display ticket with ModifyMemo rights granted to user";
{
    # Add ModifyMemo right
    ok(RT::Test->add_rights({Principal => $user, Right => [qw(ModifyMemo)]}), 'Add ModifyMemo right');

    # Display ticket
    $m->goto_ticket($ticket_id);

    my $dom = $m->dom;

    my $div = $dom->at('#MemoContent');
    ok($div.length, 'Show Memo with SeeMemo and ModifyMemo right');

    my $textarea = $dom->at('#MemoContentEdit');
    ok($div.length, 'Show edit Memo with ModifyMemo right');
}

$m->logout;
}

done_testing;
