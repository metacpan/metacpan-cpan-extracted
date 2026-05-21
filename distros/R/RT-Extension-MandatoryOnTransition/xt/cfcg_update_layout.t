use strict;
use warnings;

# This test verifies that when CustomFieldCustomGroupings (CFCG) is present in the
# Update page layout, required CFs are not rendered twice (once by CFCG and once by
# the AfterWorked callback). Duplicate inputs produce an arrayref instead of a scalar,
# breaking CF updates.
use RT::Extension::MandatoryOnTransition::Test tests => undef, config => <<'CONFIG';
Set( %MandatoryOnTransition,
    'General' => {
        '* -> resolved' => ['CF.Test Field'],
    },
);
Set( %PageLayouts,
    'RT::Ticket' => {
        Update => {
            Default => [
                {
                    Layout   => 'col-md-7,col-md-5',
                    Elements => [
                        [ 'Recipients', 'Message', 'Submit', 'PreviewScrips' ],
                        [ 'Basics', 'Times', { Name => 'CustomFieldCustomGroupings' } ],
                    ],
                },
            ],
        },
    },
);
CONFIG

use_ok('RT::Extension::MandatoryOnTransition');

my $cf = RT::CustomField->new($RT::SystemUser);
my ( $cf_id, $msg );

diag "Create required select custom field";
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

my ( $baseurl, $m ) = RT::Test->started_ok();
ok( $m->login( 'root', 'password' ), 'logged in' );

diag "Required CF input appears exactly once when CFCG is in the Update layout";
{
    my $t = RT::Test->create_ticket(
        Queue   => 'General',
        Subject => 'Test CFCG no duplicate inputs',
        Content => 'Testing',
    );
    ok( $t->id, 'Created ticket: ' . $t->id );

    ok( $t->SetStatus('open'), 'Set status to open' );
    $m->goto_ticket( $t->id );
    $m->follow_link_ok( { text => 'Resolve' }, 'Follow Resolve link' );

    # Without the fix, AfterWorked and CFCG both render the CF, producing two
    # hidden Magic fields with the same name. Count occurrences to verify there
    # is exactly one.
    my $magic_name = "Object-RT::Ticket-" . $t->id . "-CustomField-$cf_id-Values-Magic";
    my $content    = $m->content;
    my @occurrences = ( $content =~ /\Q$magic_name\E/g );
    is( scalar @occurrences, 1, 'Magic field appears exactly once (no duplicate CF inputs)' );

    # Submitting a value via the CFCG-rendered input resolves correctly.
    $m->submit_form_ok(
        {
            form_name => 'TicketUpdate',
            fields    => {
                'Object-RT::Ticket-' . $t->id . "-CustomField-$cf_id-Values" => 'foo',
            },
            button => 'SubmitTicket',
        },
        'Submit resolve with required CF set via CFCG form input',
    );

    $m->content_lacks(
        'Test Field is required when changing Status to resolved',
        'No validation error when CF value is provided',
    );
    $m->content_contains(
        "Status changed from &#39;open&#39; to &#39;resolved&#39;",
        'Ticket resolved successfully',
    );

    $t->Load( $t->id );
    is( $t->FirstCustomFieldValue('Test Field'), 'foo', 'CF saved as scalar, not arrayref' );
}

diag "Required CF still appears on form when CFCG only shows specific non-Default groupings";
{
    # When CFCG is configured to show only a named grouping (not the Default/ungrouped
    # section), AfterWorked should still render the ungrouped required CF - CFCG won't.
    my $t = RT::Test->create_ticket(
        Queue   => 'General',
        Subject => 'Test CFCG specific grouping',
        Content => 'Testing',
    );
    ok( $t->id, 'Created ticket: ' . $t->id );

    ok( $t->SetStatus('open'), 'Set status to open' );

    # Override the Update layout for this test to use CFCG with a specific grouping only.
    my ( $ret, $update_msg ) = HTML::Mason::Commands::UpdateConfig(
        Name        => 'PageLayouts',
        CurrentUser => RT->SystemUser,
        Value       => {
            'RT::Ticket' => {
                Update => {
                    Default => [
                        {
                            Layout   => 'col-md-7,col-md-5',
                            Elements => [
                                [ 'Recipients', 'Message', 'Submit', 'PreviewScrips' ],
                                [ 'Basics', 'Times',
                                  { Name => 'CustomFieldCustomGroupings', Groupings => 'Specs' } ],
                            ],
                        },
                    ],
                },
            },
        },
    );
    ok( $ret, "Updated PageLayouts to use CFCG with Specs grouping only: $update_msg" );

    $m->goto_ticket( $t->id );
    $m->follow_link_ok( { text => 'Resolve' }, 'Follow Resolve link' );

    # The CF is ungrouped (not in 'Specs'), so CFCG won't render it. AfterWorked
    # should render it, so the Magic field must be present exactly once.
    my $magic_name  = "Object-RT::Ticket-" . $t->id . "-CustomField-$cf_id-Values-Magic";
    my $content     = $m->content;
    my @occurrences = ( $content =~ /\Q$magic_name\E/g );
    is( scalar @occurrences, 1,
        'Magic field appears exactly once when CFCG shows only non-Default groupings' );

    $m->submit_form_ok(
        {
            form_name => 'TicketUpdate',
            fields    => {
                'Object-RT::Ticket-' . $t->id . "-CustomField-$cf_id-Values" => 'bar',
            },
            button => 'SubmitTicket',
        },
        'Submit resolve with required CF set via AfterWorked input',
    );

    $m->content_lacks(
        'Test Field is required when changing Status to resolved',
        'No validation error when CF value is provided',
    );
    $m->content_contains(
        "Status changed from &#39;open&#39; to &#39;resolved&#39;",
        'Ticket resolved successfully',
    );
}

undef $m;
done_testing;
