use strict;
use warnings;

use RT::Extension::MandatoryOnTransition::Test tests => undef;

use_ok('RT::Extension::MandatoryOnTransition');

my ( $baseurl, $m ) = RT::Test->started_ok();

ok( $m->login( 'root', 'password' ), 'logged in' );

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

diag "Test mandatory fields on create";
{
    $m->get_ok($m->rt_base_url);
    $m->submit_form_ok( { form_name => 'CreateTicketInQueue',
                          fields => { Queue => 'General',},
                        }, 'Click button to create ticket');

    if (RT::Handle::cmp_version( '4.4.0', $RT::VERSION) <= 0) {
        $m->title_is('Create a new ticket in General');
    }
    else{
        # RT 4.2 or older
        $m->title_is('Create a new ticket');
    }

    $m->submit_form_ok( { form_name => 'TicketCreate',
                          fields => { Status => 'resolved' },
                        }, 'Submit with resolved status');

    $m->content_contains('Time Worked is required when changing Status to resolved');
    $m->content_contains('Test Field is required when changing Status to resolved');

    $m->submit_form_ok( { form_name => 'TicketCreate',
                          fields => { Status => 'resolved',
                                    "Object-RT::Ticket--CustomField-$id-Values" => '    '},
                        }, 'Submit with resolved status');

    $m->content_contains('Time Worked is required when changing Status to resolved');
    $m->content_contains('Test Field is required when changing Status to resolved');

    $m->submit_form_ok( { form_name => 'TicketCreate',
                          fields => { Status => 'resolved',
                                    "Object-RT::Ticket--CustomField-$id-Values" => 'foo'},
                        }, 'Submit with resolved status');

    $m->content_contains('Time Worked is required when changing Status to resolved');

    $m->submit_form_ok( { form_name => 'TicketCreate',
                          fields => { Status => 'resolved',
                                      "Object-RT::Ticket--CustomField-$id-Values" => 'foo',
                                      'TimeWorked' => '10', },
                          button => 'SubmitTicket',
                        }, 'Submit with resolved status');

    $m->content_contains("Ticket 1 created in queue &#39;General&#39;");
}

diag "Test mandatory fields on create for mobile";
{
    $m->get_ok($m->rt_base_url . '/m/');
    $m->follow_link_ok( { text => 'New ticket' }, 'Click New ticket');
    $m->title_is('Create a ticket');
    $m->follow_link_ok( { text => 'General' }, 'Click General queue');
    $m->title_is('Create a ticket');

    $m->submit_form_ok( { form_name => 'TicketCreate',
                          fields => { Status => 'resolved' },
                        }, 'Submit with resolved status');

    $m->content_contains('Time Worked is required when changing Status to resolved');
    $m->content_contains('Test Field is required when changing Status to resolved');

    $m->submit_form_ok( { form_name => 'TicketCreate',
                          fields => { Status => 'resolved',
                                    "Object-RT::Ticket--CustomField-$id-Values" => '    '},
                        }, 'Submit with resolved status');

    $m->content_contains('Time Worked is required when changing Status to resolved');
    $m->content_contains('Test Field is required when changing Status to resolved');

    $m->submit_form_ok( { form_name => 'TicketCreate',
                          fields => { Status => 'resolved',
                                    "Object-RT::Ticket--CustomField-$id-Values" => 'foo'},
                        }, 'Submit with resolved status');

    $m->content_contains('Time Worked is required when changing Status to resolved');

    $m->submit_form_ok( { form_name => 'TicketCreate',
                          fields => { Status => 'resolved',
                                      "Object-RT::Ticket--CustomField-$id-Values" => 'foo',
                                      'TimeWorked' => '10', },
                        }, 'Submit with resolved status');

    $m->title_like(qr/#(\d+):/, 'Looks like a ticket number in the title');
    like($m->uri->as_string, qr/show/, "On show page after ticket create");
}

my $content = RT::Test->load_or_create_queue( Name => 'Content' );

diag "Test mandatory fields on create with content";
{
    $m->get_ok($m->rt_base_url);
    $m->submit_form_ok( { form_name => 'CreateTicketInQueue',
                          fields => { Queue => 'Content',},
                        }, 'Click button to create ticket');

    if (RT::Handle::cmp_version( '4.4.0', $RT::VERSION) <= 0) {
        $m->title_is('Create a new ticket in Content');
    }
    else{
        # RT 4.2 or older
        $m->title_is('Create a new ticket');
    }

    $m->submit_form_ok( { form_name => 'TicketCreate',
                          fields => { Status => 'resolved' },
                        }, 'Submit with resolved status');

    $m->content_contains('Content is required when changing Status to resolved');

    # Space should not count as content
    $m->submit_form_ok( { form_name => 'TicketCreate',
                          fields => { Status => 'resolved',
                                      'TimeWorked' => '10',
                                      'Content' => ' ' },
                        }, 'Submit with resolved status');

    $m->content_contains('Content is required when changing Status to resolved');

    $m->submit_form_ok( { form_name => 'TicketCreate',
                          fields => { Status => 'resolved',
                                      'TimeWorked' => '10',
                                      'Content' => 'This is a message' },
                          button => 'SubmitTicket',
                        }, 'Submit with resolved status');

    $m->content_contains("Ticket 3 created in queue &#39;Content&#39;");
}

done_testing();
