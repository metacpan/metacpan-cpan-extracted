use strict;
use warnings;

# Tests for must_be and must_not_be constraints when a CF is cleared on the
# update/resolve form. The bug: CheckMandatoryFields fell back to the existing
# DB value when the widget was submitted but empty, silently satisfying a
# must_be constraint even though the user had cleared the field.

use RT::Extension::MandatoryOnTransition::Test tests => undef, config => <<'CONFIG';
Set( %MandatoryOnTransition,
    'General' => {
        '* -> resolved' => ['CF.Must Be Field', 'CF.Must Not Be Field'],
        'CF.Must Be Field'     => { transition => '* -> resolved', must_be     => ['normal', 'restored'] },
        'CF.Must Not Be Field' => { transition => '* -> resolved', must_not_be => ['down',   'reduced']  },
    },
);
CONFIG

use_ok('RT::Extension::MandatoryOnTransition');

my ( $baseurl, $m ) = RT::Test->started_ok();
ok( $m->login( 'root', 'password' ), 'logged in' );

my $must_be_cf = RT::CustomField->new($RT::SystemUser);
my ( $must_be_cf_id, $msg );

diag "Create must_be select custom field";
( $must_be_cf_id, $msg ) = $must_be_cf->Create(
    Name       => 'Must Be Field',
    Type       => 'Select',
    LookupType => 'RT::Queue-RT::Ticket',
    MaxValues  => '1',
    Queue      => 'General',
);
ok( $must_be_cf_id, "Created CF: $msg" );
$must_be_cf->AddValue( Name => 'normal' );
$must_be_cf->AddValue( Name => 'restored' );
$must_be_cf->AddValue( Name => 'other' );

my $must_not_be_cf = RT::CustomField->new($RT::SystemUser);
my $must_not_be_cf_id;

diag "Create must_not_be select custom field";
( $must_not_be_cf_id, $msg ) = $must_not_be_cf->Create(
    Name       => 'Must Not Be Field',
    Type       => 'Select',
    LookupType => 'RT::Queue-RT::Ticket',
    MaxValues  => '1',
    Queue      => 'General',
);
ok( $must_not_be_cf_id, "Created CF: $msg" );
$must_not_be_cf->AddValue( Name => 'normal' );
$must_not_be_cf->AddValue( Name => 'down' );
$must_not_be_cf->AddValue( Name => 'reduced' );

# ── must_be ───────────────────────────────────────────────────────────────────

diag "must_be: clearing an existing allowed value blocks the transition";
{
    my $t = RT::Test->create_ticket(
        Queue   => 'General',
        Subject => 'Test must_be CF cleared',
        Content => 'Testing',
    );
    ok( $t->id, 'Created ticket: ' . $t->id );

    my ( $ret, $set_msg ) = $t->AddCustomFieldValue( Field => $must_be_cf, Value => 'normal' );
    ok( $ret, "Pre-set Must Be Field to 'normal': $set_msg" );
    is( $t->FirstCustomFieldValue('Must Be Field'), 'normal', 'CF has value normal before update' );

    ok( $t->SetStatus('open'), 'Set status to open' );
    $m->goto_ticket( $t->id );
    $m->follow_link_ok( { text => 'Resolve' }, 'Follow Resolve link' );

    my $magic_name = "Object-RT::Ticket-" . $t->id . "-CustomField-$must_be_cf_id-Values-Magic";
    $m->content_contains( $magic_name, 'Values-Magic hidden field present on resolve form' );

    $m->submit_form_ok(
        {
            form_name => 'TicketUpdate',
            fields    => {
                'Object-RT::Ticket-' . $t->id . "-CustomField-$must_be_cf_id-Values"     => '',
                'Object-RT::Ticket-' . $t->id . "-CustomField-$must_not_be_cf_id-Values" => 'normal',
            },
            button => 'SubmitTicket',
        },
        'Submit resolve with Must Be Field cleared',
    );

    $m->content_contains(
        'Must Be Field must be one of: normal, restored when changing Status to resolved',
        'Transition blocked when must_be CF is cleared',
    );

    $t->Load( $t->id );
    isnt( $t->Status, 'resolved', 'Ticket status not changed after blocked transition' );
    is( $t->FirstCustomFieldValue('Must Be Field'), 'normal', 'CF value unchanged after blocked transition' );
}

diag "must_be: keeping an allowed value permits the transition";
{
    my $t = RT::Test->create_ticket(
        Queue   => 'General',
        Subject => 'Test must_be CF kept',
        Content => 'Testing',
    );
    ok( $t->id, 'Created ticket: ' . $t->id );

    my ( $ret, $set_msg ) = $t->AddCustomFieldValue( Field => $must_be_cf, Value => 'normal' );
    ok( $ret, "Pre-set Must Be Field to 'normal': $set_msg" );

    ok( $t->SetStatus('open'), 'Set status to open' );
    $m->goto_ticket( $t->id );
    $m->follow_link_ok( { text => 'Resolve' }, 'Follow Resolve link' );

    $m->submit_form_ok(
        {
            form_name => 'TicketUpdate',
            fields    => {
                'Object-RT::Ticket-' . $t->id . "-CustomField-$must_be_cf_id-Values"     => 'normal',
                'Object-RT::Ticket-' . $t->id . "-CustomField-$must_not_be_cf_id-Values" => 'normal',
            },
            button => 'SubmitTicket',
        },
        'Submit resolve with Must Be Field set to allowed value',
    );

    $m->content_lacks(
        'Must Be Field must be',
        'No must_be error when allowed value submitted',
    );
    $m->content_contains(
        "Status changed from &#39;open&#39; to &#39;resolved&#39;",
        'Ticket resolved successfully',
    );
}

diag "must_be: submitting a disallowed value blocks the transition";
{
    my $t = RT::Test->create_ticket(
        Queue   => 'General',
        Subject => 'Test must_be CF wrong value',
        Content => 'Testing',
    );
    ok( $t->id, 'Created ticket: ' . $t->id );

    ok( $t->SetStatus('open'), 'Set status to open' );
    $m->goto_ticket( $t->id );
    $m->follow_link_ok( { text => 'Resolve' }, 'Follow Resolve link' );

    $m->submit_form_ok(
        {
            form_name => 'TicketUpdate',
            fields    => {
                'Object-RT::Ticket-' . $t->id . "-CustomField-$must_be_cf_id-Values"     => 'other',
                'Object-RT::Ticket-' . $t->id . "-CustomField-$must_not_be_cf_id-Values" => 'normal',
            },
            button => 'SubmitTicket',
        },
        'Submit resolve with Must Be Field set to disallowed value',
    );

    $m->content_contains(
        'Must Be Field must be one of: normal, restored when changing Status to resolved',
        'Transition blocked when must_be CF has disallowed value',
    );

    $t->Load( $t->id );
    isnt( $t->Status, 'resolved', 'Ticket status not changed after blocked transition' );
}

# ── must_not_be ───────────────────────────────────────────────────────────────

diag "must_not_be: submitting a forbidden value blocks the transition";
{
    my $t = RT::Test->create_ticket(
        Queue   => 'General',
        Subject => 'Test must_not_be CF forbidden value',
        Content => 'Testing',
    );
    ok( $t->id, 'Created ticket: ' . $t->id );

    ok( $t->SetStatus('open'), 'Set status to open' );
    $m->goto_ticket( $t->id );
    $m->follow_link_ok( { text => 'Resolve' }, 'Follow Resolve link' );

    $m->submit_form_ok(
        {
            form_name => 'TicketUpdate',
            fields    => {
                'Object-RT::Ticket-' . $t->id . "-CustomField-$must_be_cf_id-Values"     => 'normal',
                'Object-RT::Ticket-' . $t->id . "-CustomField-$must_not_be_cf_id-Values" => 'down',
            },
            button => 'SubmitTicket',
        },
        'Submit resolve with Must Not Be Field set to forbidden value',
    );

    $m->content_contains(
        'Must Not Be Field must not be one of: down, reduced when changing Status to resolved',
        'Transition blocked when must_not_be CF has forbidden value',
    );

    $t->Load( $t->id );
    isnt( $t->Status, 'resolved', 'Ticket status not changed after blocked transition' );
}

diag "must_not_be: submitting an allowed value permits the transition";
{
    my $t = RT::Test->create_ticket(
        Queue   => 'General',
        Subject => 'Test must_not_be CF allowed value',
        Content => 'Testing',
    );
    ok( $t->id, 'Created ticket: ' . $t->id );

    ok( $t->SetStatus('open'), 'Set status to open' );
    $m->goto_ticket( $t->id );
    $m->follow_link_ok( { text => 'Resolve' }, 'Follow Resolve link' );

    $m->submit_form_ok(
        {
            form_name => 'TicketUpdate',
            fields    => {
                'Object-RT::Ticket-' . $t->id . "-CustomField-$must_be_cf_id-Values"     => 'normal',
                'Object-RT::Ticket-' . $t->id . "-CustomField-$must_not_be_cf_id-Values" => 'normal',
            },
            button => 'SubmitTicket',
        },
        'Submit resolve with Must Not Be Field set to allowed value',
    );

    $m->content_lacks(
        'Must Not Be Field must not be',
        'No must_not_be error when allowed value submitted',
    );
    $m->content_contains(
        "Status changed from &#39;open&#39; to &#39;resolved&#39;",
        'Ticket resolved successfully',
    );
}

diag "must_not_be: clearing an existing forbidden value blocks the transition";
{
    # The resulting empty value does not technically violate must_not_be, but
    # the current implementation blocks because $cf_value is undef and the
    # must_not_be pass condition requires a defined value. Documented here as
    # the current behavior.
    my $t = RT::Test->create_ticket(
        Queue   => 'General',
        Subject => 'Test must_not_be CF cleared',
        Content => 'Testing',
    );
    ok( $t->id, 'Created ticket: ' . $t->id );

    my ( $ret, $set_msg ) = $t->AddCustomFieldValue( Field => $must_not_be_cf, Value => 'down' );
    ok( $ret, "Pre-set Must Not Be Field to 'down': $set_msg" );
    is( $t->FirstCustomFieldValue('Must Not Be Field'), 'down', 'CF has value down before update' );

    ok( $t->SetStatus('open'), 'Set status to open' );
    $m->goto_ticket( $t->id );
    $m->follow_link_ok( { text => 'Resolve' }, 'Follow Resolve link' );

    $m->submit_form_ok(
        {
            form_name => 'TicketUpdate',
            fields    => {
                'Object-RT::Ticket-' . $t->id . "-CustomField-$must_be_cf_id-Values"     => 'normal',
                'Object-RT::Ticket-' . $t->id . "-CustomField-$must_not_be_cf_id-Values" => '',
            },
            button => 'SubmitTicket',
        },
        'Submit resolve with Must Not Be Field cleared',
    );

    $m->content_contains(
        'Must Not Be Field must not be one of: down, reduced when changing Status to resolved',
        'Transition blocked when must_not_be CF is cleared',
    );

    $t->Load( $t->id );
    isnt( $t->Status, 'resolved', 'Ticket status not changed after blocked transition' );
}

undef $m;
done_testing;
