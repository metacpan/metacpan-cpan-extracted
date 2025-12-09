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

# Create queue and tickets
my $queue_foo = RT::Extension::Memo::Test->load_or_create_queue( Name => 'Foo' );
my $first_ticket = RT::Test->create_ticket( Queue => 'Foo', Subject => 'Test Ticket Memo', Requestor => 'root@localhost' );
my $first_ticket_id = $first_ticket->id;
my $second_ticket = RT::Test->create_ticket( Queue => 'Foo', Subject => 'Test Ticket Memo To Merge', Requestor => 'root@localhost' );
my $second_ticket_id = $second_ticket->id;
my $third_ticket = RT::Test->create_ticket( Queue => 'Foo', Subject => 'Test Ticket without Memo To Merge', Requestor => 'root@localhost' );
my $third_ticket_id = $third_ticket->id;
my $fourth_ticket = RT::Test->create_ticket( Queue => 'Foo', Subject => 'Test Ticket without Memo To Be Merged Into', Requestor => 'root@localhost' );
my $fourth_ticket_id = $fourth_ticket->id;


# Create memos
$first_ticket->SetAttribute(Name => 'Memo', Content => 'This is a <strong>memo</strong>');
$second_ticket->SetAttribute(Name => 'Memo', Content => 'This is a memo <strong>to merge</strong>');

# Create user
my $user = RT::Test->load_or_create_user(Name => 'user', Password => 'password');

# Login user
my ($url, $m) = RT::Extension::Memo::Test->started_ok;
$m->login('user', 'password');

# Add rights
ok(RT::Test->set_rights({Principal => $user, Right => [qw(ShowTicket SeeMemo ModifyMemo ModifySelf)]}), 'Set rights');

# Set Richtext preference
$user->SetPreferences($RT::System, {'MemoRichText' => 1});

diag "Testing first ticket memo";
{
    # Display ticket
    $m->goto_ticket($first_ticket_id);

    my $dom = $m->dom;

    # Check Memo content
    my $first_memo = $dom->at('#MemoContent');
    is($first_memo->content, 'This is a <strong>memo</strong>', 'First Memo');
}

diag "Testing second ticket Memo";
{
    # Display ticket
    $m->goto_ticket($second_ticket_id);

    my $dom = $m->dom;

    # Check Memo content
    my $second_memo = $dom->at('#MemoContent');
    is($second_memo->content, 'This is a memo <strong>to merge</strong>', 'Second Memo');
}

diag "Testing third ticket without Memo";
{
    # Display ticket
    $m->goto_ticket($third_ticket_id);

    my $dom = $m->dom;

    # Check no Memo content
    my $third_memo = $dom->at('#MemoContent');
    ok(!$third_memo->content, 'No Memo');
}

diag "Testing fourth ticket without Memo";
{
    # Display ticket
    $m->goto_ticket($fourth_ticket_id);

    my $dom = $m->dom;

    # Check no Memo content
    my $fourth_memo = $dom->at('#MemoContent');
    ok(!$fourth_memo->content, 'No Memo');
}

diag "Testing merging two tickets with Memo";
{
    my ($id, $msg) = $second_ticket->MergeInto($first_ticket->id);
    ok($id, $msg);

    # Display ticket
    $m->goto_ticket($first_ticket_id);

    my $dom = $m->dom;

    # Check Memo content
    my $merged_memo = $dom->at('#MemoContent');
    is($merged_memo->content, 'This is a <strong>memo</strong><br>This is a memo <strong>to merge</strong>', 'Merged Memo into Memo');
}

diag "Testing merging ticket with Memo into ticket without Memo";
{
    my ($id, $msg) = $first_ticket->MergeInto($third_ticket->id);
    ok($id, $msg);

    # Display ticket
    $m->goto_ticket($third_ticket_id);

    my $dom = $m->dom;

    # Check Memo content
    my $merged_memo = $dom->at('#MemoContent');
    is($merged_memo->content, 'This is a <strong>memo</strong><br>This is a memo <strong>to merge</strong>', 'Merged Memo into no Memo');
}

diag "Testing merging ticket without Memo into ticket with Memo";
{
    my ($id, $msg) = $fourth_ticket->MergeInto($first_ticket->id);
    ok($id, $msg);

    # Display ticket
    $m->goto_ticket($first_ticket_id);

    my $dom = $m->dom;

    # Check Memo content
    my $merged_memo = $dom->at('#MemoContent');
    is($merged_memo->content, 'This is a <strong>memo</strong><br>This is a memo <strong>to merge</strong>', 'Merged no Memo into Memo');
}

$m->logout;
}

done_testing;
