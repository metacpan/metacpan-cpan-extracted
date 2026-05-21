use strict;
use warnings;

# This test verifies how Date and DateTime CFs interact with CheckMandatoryFields
# when a ticket already has a value and the user submits the Update/Resolve form.
#
# Date and DateTime CFs render as a single <input type="text"> via SelectDate,
# pre-populated with the existing stored value. Two scenarios matter:
#
#   1. Submit unchanged: mechanize sends the pre-filled date string back. This
#      must be recognized as non-empty so the transition is allowed (regression
#      check: the cf_was_submitted logic must not break existing-value cases).
#
#   2. Clear the field: mechanize sends an empty string. CheckMandatoryFields must
#      detect this and block the transition (the bug the cf_was_submitted fix
#      addresses - previously the existing DB value caused a premature skip).

use RT::Extension::MandatoryOnTransition::Test tests => undef, config => <<'CONFIG';
Set( %MandatoryOnTransition,
    'DateTest' => {
        '* -> resolved' => ['CF.Date Field'],
    },
    'DateTimeTest' => {
        '* -> resolved' => ['CF.DateTime Field'],
    },
);
CONFIG

use_ok('RT::Extension::MandatoryOnTransition');

my ( $baseurl, $m ) = RT::Test->started_ok();
ok( $m->login( 'root', 'password' ), 'logged in' );

my $date_queue = RT::Test->load_or_create_queue( Name => 'DateTest' );
ok( $date_queue->id, 'Created DateTest queue' );

my $dt_queue = RT::Test->load_or_create_queue( Name => 'DateTimeTest' );
ok( $dt_queue->id, 'Created DateTimeTest queue' );

my $date_cf = RT::CustomField->new($RT::SystemUser);
my ( $date_cf_id, $msg );

diag "Create required Date custom field";
( $date_cf_id, $msg ) = $date_cf->Create(
    Name       => 'Date Field',
    Type       => 'Date',
    LookupType => 'RT::Queue-RT::Ticket',
    MaxValues  => '1',
    Queue      => 'DateTest',
);
ok( $date_cf_id, "Created Date CF: $msg" );

my $dt_cf = RT::CustomField->new($RT::SystemUser);
my $dt_cf_id;

diag "Create required DateTime custom field";
( $dt_cf_id, $msg ) = $dt_cf->Create(
    Name       => 'DateTime Field',
    Type       => 'DateTime',
    LookupType => 'RT::Queue-RT::Ticket',
    MaxValues  => '1',
    Queue      => 'DateTimeTest',
);
ok( $dt_cf_id, "Created DateTime CF: $msg" );

# ── Date CF ──────────────────────────────────────────────────────────────────

diag "Date CF: submitting unchanged existing value allows the transition";
{
    my $t = RT::Test->create_ticket(
        Queue   => 'DateTest',
        Subject => 'Test Date CF unchanged',
        Content => 'Testing',
    );
    ok( $t->id, 'Created ticket: ' . $t->id );

    my ( $ret, $set_msg ) = $t->AddCustomFieldValue( Field => $date_cf, Value => '2026-01-15' );
    ok( $ret, "Pre-set Date Field: $set_msg" );
    ok( $t->FirstCustomFieldValue('Date Field'), 'Date Field has a value' );

    ok( $t->SetStatus('open'), 'Set status to open' );
    $m->goto_ticket( $t->id );
    $m->follow_link_ok( { text => 'Resolve' }, 'Follow Resolve link' );

    my $magic_name = "Object-RT::Ticket-" . $t->id . "-CustomField-$date_cf_id-Values-Magic";
    $m->content_contains( $magic_name, 'Values-Magic hidden field present on resolve form' );

    # Submit without overriding any date fields - mechanize sends the pre-filled
    # date string from the text input, which should satisfy the required check.
    $m->submit_form_ok(
        {
            form_name => 'TicketUpdate',
            button    => 'SubmitTicket',
        },
        'Submit resolve with Date CF value unchanged',
    );

    $m->content_lacks(
        'Date Field is required when changing Status to resolved',
        'Transition not blocked when Date CF has existing value',
    );
    $m->content_contains(
        "Status changed from &#39;open&#39; to &#39;resolved&#39;",
        'Ticket resolved successfully with unchanged Date CF',
    );
}

diag "Date CF: clearing existing value blocks the transition";
{
    my $t = RT::Test->create_ticket(
        Queue   => 'DateTest',
        Subject => 'Test Date CF cleared',
        Content => 'Testing',
    );
    ok( $t->id, 'Created ticket: ' . $t->id );

    my ( $ret, $set_msg ) = $t->AddCustomFieldValue( Field => $date_cf, Value => '2026-01-15' );
    ok( $ret, "Pre-set Date Field: $set_msg" );
    ok( $t->FirstCustomFieldValue('Date Field'), 'Date Field has a value before update' );

    ok( $t->SetStatus('open'), 'Set status to open' );
    $m->goto_ticket( $t->id );
    $m->follow_link_ok( { text => 'Resolve' }, 'Follow Resolve link' );

    my $magic_name = "Object-RT::Ticket-" . $t->id . "-CustomField-$date_cf_id-Values-Magic";
    $m->content_contains( $magic_name, 'Values-Magic hidden field present on resolve form' );

    # Submit with the Date CF text input cleared to empty string.
    $m->submit_form_ok(
        {
            form_name => 'TicketUpdate',
            fields    => {
                'Object-RT::Ticket-' . $t->id . "-CustomField-$date_cf_id-Values" => '',
            },
            button => 'SubmitTicket',
        },
        'Submit resolve with Date CF cleared',
    );

    $m->content_contains(
        'Date Field is required when changing Status to resolved',
        'Transition blocked when required Date CF is cleared',
    );

    $t->Load( $t->id );
    isnt( $t->Status, 'resolved', 'Ticket status not changed after blocked transition' );
    ok( $t->FirstCustomFieldValue('Date Field'), 'Date Field value unchanged after blocked transition' );
}

# ── DateTime CF ──────────────────────────────────────────────────────────────

diag "DateTime CF: submitting unchanged existing value allows the transition";
{
    my $t = RT::Test->create_ticket(
        Queue   => 'DateTimeTest',
        Subject => 'Test DateTime CF unchanged',
        Content => 'Testing',
    );
    ok( $t->id, 'Created ticket: ' . $t->id );

    my ( $ret, $set_msg ) = $t->AddCustomFieldValue( Field => $dt_cf, Value => '2026-01-15 10:00:00' );
    ok( $ret, "Pre-set DateTime Field: $set_msg" );
    ok( $t->FirstCustomFieldValue('DateTime Field'), 'DateTime Field has a value' );

    ok( $t->SetStatus('open'), 'Set status to open' );
    $m->goto_ticket( $t->id );
    $m->follow_link_ok( { text => 'Resolve' }, 'Follow Resolve link' );

    my $magic_name = "Object-RT::Ticket-" . $t->id . "-CustomField-$dt_cf_id-Values-Magic";
    $m->content_contains( $magic_name, 'Values-Magic hidden field present on resolve form' );

    # Submit without overriding fields - mechanize sends the pre-filled datetime string.
    $m->submit_form_ok(
        {
            form_name => 'TicketUpdate',
            button    => 'SubmitTicket',
        },
        'Submit resolve with DateTime CF value unchanged',
    );

    $m->content_lacks(
        'DateTime Field is required when changing Status to resolved',
        'Transition not blocked when DateTime CF has existing value',
    );
    $m->content_contains(
        "Status changed from &#39;open&#39; to &#39;resolved&#39;",
        'Ticket resolved successfully with unchanged DateTime CF',
    );
}

diag "DateTime CF: clearing existing value blocks the transition";
{
    my $t = RT::Test->create_ticket(
        Queue   => 'DateTimeTest',
        Subject => 'Test DateTime CF cleared',
        Content => 'Testing',
    );
    ok( $t->id, 'Created ticket: ' . $t->id );

    my ( $ret, $set_msg ) = $t->AddCustomFieldValue( Field => $dt_cf, Value => '2026-01-15 10:00:00' );
    ok( $ret, "Pre-set DateTime Field: $set_msg" );
    ok( $t->FirstCustomFieldValue('DateTime Field'), 'DateTime Field has a value before update' );

    ok( $t->SetStatus('open'), 'Set status to open' );
    $m->goto_ticket( $t->id );
    $m->follow_link_ok( { text => 'Resolve' }, 'Follow Resolve link' );

    my $magic_name = "Object-RT::Ticket-" . $t->id . "-CustomField-$dt_cf_id-Values-Magic";
    $m->content_contains( $magic_name, 'Values-Magic hidden field present on resolve form' );

    # Submit with the DateTime CF text input cleared to empty string.
    $m->submit_form_ok(
        {
            form_name => 'TicketUpdate',
            fields    => {
                'Object-RT::Ticket-' . $t->id . "-CustomField-$dt_cf_id-Values" => '',
            },
            button => 'SubmitTicket',
        },
        'Submit resolve with DateTime CF cleared',
    );

    $m->content_contains(
        'DateTime Field is required when changing Status to resolved',
        'Transition blocked when required DateTime CF is cleared',
    );

    $t->Load( $t->id );
    isnt( $t->Status, 'resolved', 'Ticket status not changed after blocked transition' );
    ok( $t->FirstCustomFieldValue('DateTime Field'), 'DateTime Field value unchanged after blocked transition' );
}

undef $m;
done_testing;
