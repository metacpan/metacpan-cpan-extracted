use strict;
use warnings;

use RT::Extension::MandatoryOnTransition::Test tests => undef;

use_ok('RT::Extension::MandatoryOnTransition');

my ( $baseurl, $m ) = RT::Test->started_ok();

ok( $m->login( 'root', 'password' ), 'logged in' );
$m->get_ok($m->rt_base_url);

my $cf = RT::CustomField->new($RT::SystemUser);
my ( $id, $ret, $msg );

diag "Create custom field";
( $id, $msg ) = $cf->Create(
    Name      => 'Test Field',
    Type      => 'Select',
    LookupType => 'RT::Queue-RT::Ticket',
    MaxValues => '1',
    Queue     => 'General',
);

ok( $id, $msg );
$cf->AddValue( Name => 'foo' );
$cf->AddValue( Name => 'bar' );

my $cf2 = RT::CustomField->new($RT::SystemUser);
my $id2;

diag "Create optional custom field";
( $id2, $msg ) = $cf2->Create(
    Name      => 'XXX Optional Field ZZZ',
    Type      => 'Select',
    LookupType => 'RT::Queue-RT::Ticket',
    MaxValues => '1',
    Queue     => 'General',
);

ok( $id2, $msg );
$cf2->AddValue( Name => 'blue' );
$cf2->AddValue( Name => 'green' );

my $cf3 = RT::CustomField->new($RT::SystemUser);
my $id3;
diag "Create custom field for must have values";
( $id3, $msg ) = $cf3->Create(
    Name      => 'Test Field3',
    Type      => 'Select',
    LookupType => 'RT::Queue-RT::Ticket',
    MaxValues => '1',
    Queue     => 'General',
);

ok( $id3, $msg );
$cf3->AddValue( Name => 'normal' );
$cf3->AddValue( Name => 'restored' );
$cf3->AddValue( Name => 'other' );

my $cf4 = RT::CustomField->new($RT::SystemUser);
my $id4;
diag "Create custom field for must not have values";
( $id4, $msg ) = $cf4->Create(
    Name      => 'Test Field4',
    Type      => 'Select',
    LookupType => 'RT::Queue-RT::Ticket',
    MaxValues => '1',
    Queue     => 'General',
);

ok( $id4, $msg );
$cf4->AddValue( Name => 'normal' );
$cf4->AddValue( Name => 'down' );
$cf4->AddValue( Name => 'reduced' );

diag "Try a resolve without TimeWorked";
{
    my $t = RT::Test->create_ticket(
         Queue => 'General',
         Subject => 'Test Mandatory On Resolve',
         Content => 'Testing',
         );

    ok( $t->id, 'Created test ticket: ' . $t->id);
    ok( $t->SetStatus('open'), 'Set status to open');
    $m->goto_ticket($t->id);

    $m->follow_link_ok( { text => 'Resolve' }, 'Try to resolve ticket');
    $m->content_contains('Test Field');
    $m->content_lacks('XXX Optional Field ZZZ');
    $m->submit_form_ok( { form_name => 'TicketUpdate',
                          button => 'SubmitTicket',},
                          'Submit resolve with no Time Worked');
    $m->content_contains('Time Worked is required when changing Status to resolved');
    $m->content_contains('Test Field is required when changing Status to resolved');
    $m->content_contains('Test Field3 must be one of: normal, restored when changing Status to resolved');

    $m->submit_form_ok( { form_name => 'TicketUpdate',
                          fields => { UpdateTimeWorked => 10,
                                    'Object-RT::Ticket-' . $t->id . "-CustomField-$id-Values" => 'foo',
                                    'Object-RT::Ticket-' . $t->id . "-CustomField-$id3-Values" => 'other',
                                    'Object-RT::Ticket-' . $t->id . "-CustomField-$id4-Values" => 'down',},

                          button => 'SubmitTicket',
                        }, 'Submit resolve with Time Worked and Test Field');

    $m->content_contains('Test Field3 must be one of: normal, restored when changing Status to resolved');
    $m->content_contains('Test Field4 must not be one of: down, reduced when changing Status to resolved');

    $m->submit_form_ok( { form_name => 'TicketUpdate',
                          fields => { UpdateTimeWorked => 10,
                                    'Object-RT::Ticket-' . $t->id . "-CustomField-$id-Values" => 'foo',
                                    'Object-RT::Ticket-' . $t->id . "-CustomField-$id3-Values" => 'normal',
                                    'Object-RT::Ticket-' . $t->id . "-CustomField-$id4-Values" => 'normal',},

                          button => 'SubmitTicket',
                        }, 'Submit resolve with Time Worked and Test Field');


    if ( $RT::VERSION =~ /^4\.0\.\d+/ ){
        $m->content_contains("TimeWorked changed from &#40;no value&#41; to &#39;10&#39;");
    }
    else{
        # 4.2 or later
        $m->content_contains("Worked 10 minutes");
    }
    $m->content_contains("Status changed from &#39;open&#39; to &#39;resolved&#39;");
}

diag "Try a resolve without TimeWorked in mobile interface";
{
    $m->get_ok($m->rt_base_url . "/m/");

    $m->follow_link_ok( { text => 'New ticket' }, 'Click New ticket');
    $m->title_is('Create a ticket');
    $m->follow_link_ok( { text => 'General' }, 'Click General queue');
    $m->title_is('Create a ticket');

    $m->submit_form_ok( { form_name => 'TicketCreate',
                        }, 'Create new ticket');

    my $title = $m->title();
    my ($ticket_id) = $title =~ /^#(\d+)/;
    like( $ticket_id, qr/\d+/, "Got number $ticket_id for ticket id");

    $m->get_ok($m->rt_base_url . "/m/ticket/show/?id=$ticket_id");

    $m->follow_link_ok( { text => 'Reply' }, 'Click Reply link');

    $m->submit_form_ok( { form_number => 1,
                          fields => { Status => 'resolved' },
                          button => 'SubmitTicket',
                        }, 'Submit resolve with no Time Worked');

    $m->content_contains('Time Worked is required when changing Status to resolved');
    $m->content_contains('Test Field is required when changing Status to resolved');
    $m->content_contains('Test Field3 must be one of: normal, restored when changing Status to resolved');

    $m->submit_form_ok( { form_number => 1,
                          fields => { UpdateTimeWorked => 10,
                                    'Object-RT::Ticket-' . $ticket_id . "-CustomField-$id-Values" => 'foo',
                                    'Object-RT::Ticket-' . $ticket_id . "-CustomField-$id3-Values" => 'other',
                                    'Object-RT::Ticket-' . $ticket_id . "-CustomField-$id4-Values" => 'down',},

                          button => 'SubmitTicket',
                        }, 'Submit resolve with Time Worked and Test Field');

    $m->content_contains('Test Field3 must be one of: normal, restored when changing Status to resolved');
    $m->content_contains('Test Field4 must not be one of: down, reduced when changing Status to resolved');

    $m->submit_form_ok( { form_number => 1,
                          fields => { UpdateTimeWorked => 10,
                                    'Object-RT::Ticket-' . $ticket_id . "-CustomField-$id-Values" => 'foo',
                                    'Object-RT::Ticket-' . $ticket_id . "-CustomField-$id3-Values" => 'normal',
                                    'Object-RT::Ticket-' . $ticket_id . "-CustomField-$id4-Values" => 'normal',},

                          button => 'SubmitTicket',
                        }, 'Submit resolve with Time Worked and Test Field');

    # Try to confirm the page was updated.
    $m->title_like(qr/^#$ticket_id:/, "Page title starts with ticket number $ticket_id");
    like($m->uri->as_string, qr/show/, "On show page after ticket resolve");
}

my $content = RT::Test->load_or_create_queue( Name => 'Content' );

diag "Try a resolve without Content";
{
    my $t = RT::Test->create_ticket(
         Queue => 'Content',
         Subject => 'Test Mandatory On Resolve',
         Content => 'Testing',
         );

    ok( $t->id, 'Created test ticket: ' . $t->id);
    ok( $t->SetStatus('open'), 'Set status to open');
    $m->goto_ticket($t->id);

    $m->follow_link_ok( { text => 'Resolve' }, 'Try to resolve ticket');
    $m->submit_form_ok( { form_name => 'TicketUpdate',
                          button => 'SubmitTicket',},
                          'Submit resolve with no Content');
    $m->content_contains('Content is required when changing Status to resolved');

    # Space shouldn't count as content
    $m->submit_form_ok( { form_name => 'TicketUpdate',
                          fields => { UpdateTimeWorked => 10,
                                    'UpdateContent' => ' ',},
                          button => 'SubmitTicket',
                        }, 'Submit resolve with space as Content');
    $m->content_contains('Content is required when changing Status to resolved');

    $m->submit_form_ok( { form_name => 'TicketUpdate',
                          fields => { UpdateTimeWorked => 10,
                                    'UpdateContent' => 'Some real content',},
                          button => 'SubmitTicket',
                        }, 'Submit resolve with real content');

    $m->content_contains("Status changed from &#39;open&#39; to &#39;resolved&#39;");
}

undef $m;
done_testing;
