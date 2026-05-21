use strict;
use warnings;

use RT::Extension::MandatoryOnTransition::Test tests => undef, config => <<'CONFIG';
Set( %MandatoryOnTransition,
    'General' => {
        '* -> resolved' => ['CF.Test Field'],
    },
    'MultiTest' => {
        '* -> resolved' => ['CF.Multi Field'],
    },
);
CONFIG

use_ok('RT::Extension::MandatoryOnTransition');

my ( $baseurl, $m ) = RT::Test->started_ok();
ok( $m->login( 'root', 'password' ), 'logged in' );

my $multi_queue = RT::Test->load_or_create_queue( Name => 'MultiTest' );
ok( $multi_queue->id, 'Created MultiTest queue' );

my $cf = RT::CustomField->new($RT::SystemUser);
my ( $cf_id, $msg );

diag "Create required single-value select custom field";
( $cf_id, $msg ) = $cf->Create(
    Name       => 'Test Field',
    Type       => 'Select',
    LookupType => 'RT::Queue-RT::Ticket',
    MaxValues  => '1',
    Queue      => 'General',
);
ok( $cf_id, "Created CF: $msg" );
$cf->AddValue( Name => 'foo' );
$cf->AddValue( Name => 'bar' );

my $multi_cf = RT::CustomField->new($RT::SystemUser);
my $multi_cf_id;

# Use a Freeform (text) CF for the multi-value test rather than Select.
# For a <select multiple>, HTML::Form's value('') appends the empty option
# to the existing selections instead of replacing them, so 'alpha' and
# 'beta' stay in the submitted POST alongside the empty string.  A Freeform
# CF renders existing values as a single newline-joined text input, so
# mechanize's value('') properly clears it to an empty string.
diag "Create required multi-value freeform custom field";
( $multi_cf_id, $msg ) = $multi_cf->Create(
    Name       => 'Multi Field',
    Type       => 'Freeform',
    LookupType => 'RT::Queue-RT::Ticket',
    MaxValues  => '0',
    Queue      => 'MultiTest',
);
ok( $multi_cf_id, "Created multi-value CF: $msg" );

diag "Clearing a required CF on update blocks the transition";
{
    my $t = RT::Test->create_ticket(
        Queue   => 'General',
        Subject => 'Test clearing required CF',
        Content => 'Testing',
    );
    ok( $t->id, 'Created ticket: ' . $t->id );

    my ( $ret, $set_msg ) = $t->AddCustomFieldValue( Field => $cf, Value => 'foo' );
    ok( $ret, "Pre-set Test Field to 'foo': $set_msg" );
    is( $t->FirstCustomFieldValue('Test Field'), 'foo', 'CF has value foo before update' );

    ok( $t->SetStatus('open'), 'Set status to open' );
    $m->goto_ticket( $t->id );
    $m->follow_link_ok( { text => 'Resolve' }, 'Follow Resolve link' );

    # Confirm the Magic hidden field is present - it signals that the CF widget
    # was rendered and the user had the opportunity to edit the field.
    my $magic_name = "Object-RT::Ticket-" . $t->id . "-CustomField-$cf_id-Values-Magic";
    $m->content_contains( $magic_name, 'Values-Magic hidden field present on resolve form' );

    # Submit with the CF value cleared. Mechanize submits the hidden Magic field
    # automatically, telling CheckMandatoryFields the widget was present.
    $m->submit_form_ok(
        {
            form_name => 'TicketUpdate',
            fields    => {
                'Object-RT::Ticket-' . $t->id . "-CustomField-$cf_id-Values" => '',
            },
            button => 'SubmitTicket',
        },
        'Submit resolve with required CF cleared',
    );

    $m->content_contains(
        'Test Field is required when changing Status to resolved',
        'Transition blocked when required CF is cleared',
    );

    $t->Load( $t->id );
    isnt( $t->Status, 'resolved', 'Ticket status not changed after blocked transition' );
    is( $t->FirstCustomFieldValue('Test Field'), 'foo', 'CF value unchanged after blocked transition' );
}

diag "Providing a new value for a required CF allows the transition";
{
    my $t = RT::Test->create_ticket(
        Queue   => 'General',
        Subject => 'Test providing required CF on resolve',
        Content => 'Testing',
    );
    ok( $t->id, 'Created ticket: ' . $t->id );

    my ( $ret, $set_msg ) = $t->AddCustomFieldValue( Field => $cf, Value => 'foo' );
    ok( $ret, "Pre-set Test Field to 'foo': $set_msg" );

    ok( $t->SetStatus('open'), 'Set status to open' );
    $m->goto_ticket( $t->id );
    $m->follow_link_ok( { text => 'Resolve' }, 'Follow Resolve link' );

    $m->submit_form_ok(
        {
            form_name => 'TicketUpdate',
            fields    => {
                'Object-RT::Ticket-' . $t->id . "-CustomField-$cf_id-Values" => 'bar',
            },
            button => 'SubmitTicket',
        },
        'Submit resolve with required CF set to a new value',
    );

    $m->content_lacks(
        'Test Field is required when changing Status to resolved',
        'Transition not blocked when CF has a value',
    );
    $m->content_contains(
        "Status changed from &#39;open&#39; to &#39;resolved&#39;",
        'Ticket resolved successfully',
    );

    $t->Load( $t->id );
    is( $t->FirstCustomFieldValue('Test Field'), 'bar', 'CF saved with the new value' );
}

diag "Clearing all values of a required multi-value CF blocks the transition";
{
    my $t = RT::Test->create_ticket(
        Queue   => 'MultiTest',
        Subject => 'Test clearing required multi-value CF',
        Content => 'Testing',
    );
    ok( $t->id, 'Created ticket: ' . $t->id );

    my ( $ret1, $msg1 ) = $t->AddCustomFieldValue( Field => $multi_cf, Value => 'alpha' );
    ok( $ret1, "Pre-set Multi Field to 'alpha': $msg1" );
    my ( $ret2, $msg2 ) = $t->AddCustomFieldValue( Field => $multi_cf, Value => 'beta' );
    ok( $ret2, "Pre-set Multi Field to 'beta': $msg2" );
    is( $t->CustomFieldValues('Multi Field')->Count, 2, 'Multi Field has two values before update' );
    # Freeform multi-value renders existing values in a single text input joined
    # by newlines; mechanize can clear it cleanly with an empty string.

    ok( $t->SetStatus('open'), 'Set status to open' );
    $m->goto_ticket( $t->id );
    $m->follow_link_ok( { text => 'Resolve' }, 'Follow Resolve link' );

    my $magic_name = "Object-RT::Ticket-" . $t->id . "-CustomField-$multi_cf_id-Values-Magic";
    $m->content_contains( $magic_name, 'Values-Magic hidden field present on resolve form' );

    # Submit with the multi-value CF cleared (empty selection). The hidden Magic
    # field is still submitted by mechanize, signalling the widget was present.
    $m->submit_form_ok(
        {
            form_name => 'TicketUpdate',
            fields    => {
                'Object-RT::Ticket-' . $t->id . "-CustomField-$multi_cf_id-Values" => '',
            },
            button => 'SubmitTicket',
        },
        'Submit resolve with all multi-value CF values cleared',
    );

    $m->content_contains(
        'Multi Field is required when changing Status to resolved',
        'Transition blocked when all multi-value CF values are cleared',
    );

    $t->Load( $t->id );
    isnt( $t->Status, 'resolved', 'Ticket status not changed after blocked transition' );
    is( $t->CustomFieldValues('Multi Field')->Count, 2, 'Multi Field values unchanged after blocked transition' );
}

diag "Providing at least one value for a required multi-value CF allows the transition";
{
    my $t = RT::Test->create_ticket(
        Queue   => 'MultiTest',
        Subject => 'Test providing required multi-value CF on resolve',
        Content => 'Testing',
    );
    ok( $t->id, 'Created ticket: ' . $t->id );

    my ( $ret, $set_msg ) = $t->AddCustomFieldValue( Field => $multi_cf, Value => 'alpha' );
    ok( $ret, "Pre-set Multi Field to 'alpha': $set_msg" );

    ok( $t->SetStatus('open'), 'Set status to open' );
    $m->goto_ticket( $t->id );
    $m->follow_link_ok( { text => 'Resolve' }, 'Follow Resolve link' );

    $m->submit_form_ok(
        {
            form_name => 'TicketUpdate',
            fields    => {
                'Object-RT::Ticket-' . $t->id . "-CustomField-$multi_cf_id-Values" => 'new value',
            },
            button => 'SubmitTicket',
        },
        'Submit resolve with a value for multi-value CF',
    );

    $m->content_lacks(
        'Multi Field is required when changing Status to resolved',
        'Transition not blocked when multi-value CF has a value',
    );
    $m->content_contains(
        "Status changed from &#39;open&#39; to &#39;resolved&#39;",
        'Ticket resolved successfully',
    );
}

undef $m;
done_testing;
