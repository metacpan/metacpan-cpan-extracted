use strict;
use warnings;

use RT::Extension::MandatoryOnTransition::Test tests => undef, config => <<CONFIG
Set( %MandatoryOnTransition,
     '*' => {
         '* -> resolved' => ['Owner',],
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

undef $m;
done_testing;
