use strict;
use warnings;
use Test::Warn;

use RT::Extension::MandatoryOnTransition::Test tests => undef, config => <<CONFIG
Set( %MandatoryOnTransition,
     '*' => {
         '* -> resolved'  => ['Owner'],
         '* -> stalled'   => ['AdminCc'],
         '* -> deleted'   => ['CustomRole.vip'],
         'AdminCc'        => { transition => '* -> stalled', group => ['Admins'] },
        }
    );
CONFIG
  ;

use_ok('RT::Extension::MandatoryOnTransition');

my ($baseurl, $m) = RT::Test->started_ok();

ok($m->login('root', 'password'), 'logged in');
$m->get_ok($m->rt_base_url);

my $root = RT::User->new(RT->SystemUser);
$root->Load('root');
ok($root->id, 'Loaded root');

diag "Resolve ticket through Update with required Owner";
{
    my $t = RT::Test->create_ticket(
        Queue   => 'General',
        Subject => 'Test Mandatory Owner On Resolve',
        Content => 'Testing',
    );

    ok($t->id, 'Created test ticket: ' . $t->id);

    $m->goto_ticket($t->id);

    $m->follow_link_ok({ text => 'Resolve' }, 'Try to resolve ticket');
    $m->text_contains('Test Mandatory Owner On Resolve');
    $m->submit_form_ok(
        {   form_name => 'TicketUpdate',
            button    => 'SubmitTicket',
        },
        'Submit resolve with no Owner set'
    );
    $m->text_contains('Owner is required when changing Status to resolved');
    $m->submit_form_ok(
        {   form_name => 'TicketUpdate',
            button    => 'SubmitTicket',
            fields    => { Owner => $root->id }
        },
        'Submit resolve with Owner set'
    );
    $m->text_lacks('Owner is required when changing Status to resolved');
    $m->text_contains('Owner changed from Nobody to root');
    $m->text_contains("Status changed from 'new' to 'resolved'");
}

diag "Resolve ticket through Basics with required Owner";
{
    my $t = RT::Test->create_ticket(
        Queue   => 'General',
        Subject => 'Test Mandatory Owner On Resolve',
        Content => 'Testing',
    );
    ok($t->id, 'Created ticket to resolve through Modify.html: ' . $t->id);

    $m->goto_ticket($t->id);
    $m->follow_link_ok({ text => 'Basics' }, 'Get Modify.html of ticket');
    $m->submit_form_ok(
        {   form_name => 'TicketModify',
            fields    => { Status => 'resolved', },
            button    => 'SubmitTicket',
        },
        'Submit resolve with no Owner set'
    );
    $m->text_contains('Owner is required when changing Status to resolved');

    $m->submit_form_ok(
        {   form_name => 'TicketModify',
            fields    => { Status => 'resolved', Owner => $root->id, },
            button    => 'SubmitTicket',
        },
        'Submit resolve with no Owner set'
    );
    $m->text_lacks('Owner is required when changing Status to resolved');
    $m->text_contains('Owner changed from Nobody to root');
    $m->text_contains("Status changed from 'new' to 'resolved'");
}

diag "Resolve ticket through Jumbo with required Owner";
{
    my $t = RT::Test->create_ticket(
        Queue   => 'General',
        Subject => 'Test Mandatory Owner On Resolve',
        Content => 'Testing',
    );
    ok($t->id, 'Created ticket to resolve through ModifyAll.html: ' . $t->id);

    $m->goto_ticket($t->id);
    $m->follow_link_ok({ text => 'Jumbo' }, 'Get ModifyAll.html of ticket');
    $m->submit_form_ok(
        {   form_name => 'TicketModifyAll',
            fields    => { Status => 'resolved', },
            button    => 'SubmitTicket',
        },
        'Submit resolve with no Owner set'
    );
    $m->text_contains('Owner is required when changing Status to resolved');

    $m->submit_form_ok(
        {   form_name => 'TicketModifyAll',
            fields    => { Status => 'resolved', Owner => $root->id, },
            button    => 'SubmitTicket',
        },
        'Submit resolve with no Owner set'
    );
    $m->text_lacks('Owner is required when changing Status to resolved');
    $m->text_contains('Owner changed from Nobody to root');
    $m->text_contains("Status changed from 'new' to 'resolved'");
}

diag "Test core role fields";
{
    my $role = qw/AdminCc/;
    my $t = RT::Test->create_ticket(
        Queue   => 'General',
        Subject => 'Test Mandatory AdminCc',
        Content => 'Testing',
    );
    ok($t->id, 'Created test ticket: ' . $t->id);
    my ($ret, $msg) = $t->SetStatus('open');
    ok $ret, $msg;

    $m->goto_ticket($t->id);
    $m->follow_link_ok({ text => 'Basics' }, 'Get Modify.html of ticket');
    $m->submit_form_ok(
        {   form_name => 'TicketModify',
            fields    => { Status => 'stalled', },
            button    => 'SubmitTicket',
        },
        "Submit stalled with no $role member"
    );
    $m->text_contains("A member of group Admins is required for role: $role");
    $m->warning_like(qr/Failed to load group: Admins : Couldn't find row/);

    my $role_group = $t->$role;
    ok $role_group->Id;

    my $root = RT::User->new(RT->SystemUser);
    $root->Load('root');
    ok($root->id, 'Loaded root');

    ($ret, $msg) = $role_group->AddMember($root->PrincipalId);
    ok $ret, $msg;

    $m->goto_ticket($t->id);
    $m->follow_link_ok({ text => 'Basics' }, 'Get Modify.html of ticket');
    $m->submit_form_ok(
        {   form_name => 'TicketModify',
            fields    => { Status => 'stalled', },
            button    => 'SubmitTicket',
        },
        "Try to stall ticket with no Admins group created"
    );
    $m->text_contains("A member of group Admins is required for role: $role");
    $m->warning_like(qr/Failed to load group: Admins : Couldn't find row/);

    my $group = RT::Group->new(RT->SystemUser);
    ($ret, $msg) = $group->CreateUserDefinedGroup(Name => 'Admins');
    ok $ret, "Failed to create Admins group: $msg";

    $m->goto_ticket($t->id);
    $m->follow_link_ok({ text => 'Basics' }, 'Get Modify.html of ticket');
    $m->submit_form_ok(
        {   form_name => 'TicketModify',
            fields    => { Status => 'stalled', },
            button    => 'SubmitTicket',
        },
        "Try to stall ticket with no $role but not a member of required group"
    );
    $m->text_contains("A member of group Admins is required for role: $role");

    ($ret, $msg) = $group->AddMember($root->PrincipalId);
    ok $ret, $msg;

    $m->goto_ticket($t->id);
    $m->follow_link_ok({ text => 'Basics' }, 'Get Modify.html of ticket');
    $m->submit_form_ok(
        {   form_name => 'TicketModify',
            fields    => { Status => 'stalled', },
            button    => 'SubmitTicket',
        },
        "Try to stall ticket with $role and group required"
    );
    $m->text_contains("Status changed from 'open' to 'stalled'");
}

diag "Test custom role mandatory fields";
{
    my $t = RT::Test->create_ticket(
        Queue   => 'General',
        Subject => 'Test Mandatory Custom Role',
        Content => 'Testing',
    );
    ok($t->id, 'Created test ticket: ' . $t->id);
    my ($ret, $msg) = $t->SetStatus('open');
    ok $ret, $msg;

    my $id = $t->id;

    my $customrole = RT::CustomRole->new(RT->SystemUser);
    ($ret, $msg) = $customrole->Create(Name => 'vip');
    ok $ret, $msg;

    ($ret, $msg) = $customrole->Load('vip');
    ok $ret, $msg;

    ($ret, $msg) = $customrole->AddToObject($t->Queue);
    ok $ret, $msg;

    $m->goto_ticket($t->id);
    $m->follow_link_ok({ text => 'Basics' }, 'Get Modify.html of ticket');
    $m->submit_form_ok(
        {   form_name => 'TicketModify',
            fields    => { Status => 'deleted', },
            button    => 'SubmitTicket',
        },
        "Submit deleted with no value for required custom role"
    );
    $m->text_contains("vip is required when changing Status to deleted");

    ($ret, $msg) = $t->AddWatcher(Type => $customrole->GroupType, Principal => $root->PrincipalObj);
    ok $ret, $msg;

    $m->goto_ticket($t->id);
    $m->follow_link_ok({ text => 'Basics' }, 'Get Modify.html of ticket');
    $m->submit_form_ok(
        {   form_name => 'TicketModify',
            fields    => { Status => 'deleted', },
            button    => 'SubmitTicket',
        },
        "Submit deleted with manatory custom role requirements met."
    );
    $m->text_contains("Ticket deleted");
}

undef $m;
done_testing;
