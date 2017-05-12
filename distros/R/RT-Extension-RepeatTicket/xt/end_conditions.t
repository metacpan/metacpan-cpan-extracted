use strict;
use warnings;

use RT::Extension::RepeatTicket::Test tests => 59;

use_ok('RT::Extension::RepeatTicket');
require_ok('bin/rt-repeat-ticket');

my ( $baseurl, $m ) = RT::Test->started_ok();
{
    diag "Test ending after 3 occurences";
    my $daily_id = run_tests($baseurl, $m);

    # End after 3.
    ok( $m->goto_ticket($daily_id), "Found ticket $daily_id.");
    $m->follow_link_ok( {text => 'Recurrence'}, 'Loaded recurrence edit' );

    $m->form_name("ModifyRecurrence");
    $m->field('repeat-end' => 'number');
    $m->field('repeat-end-number' => 3);
    $m->click_button(name => 'SubmitTicket');
    $m->text_like( qr/Recurrence updated/);

    my $day = DateTime->now;
    my $id = $daily_id;
    for (1..2){
        my $next_id = $id + 1;
        my $ticket = RT::Ticket->new(RT->SystemUser);

        ok( $ticket->Load($id), "Loaded ticket $id");
        ok($ticket->SetStatus('resolved'), "Ticket $id resolved");

        $day->add( days => 1 );
        ok(!(RT::Repeat::Ticket::Run->run('-date=' . $day->ymd)),
           'Ran recurrence script for tomorrow.');
        ok( $m->goto_ticket($next_id), "Recurrence ticket $next_id created.");
        $m->text_like( qr/Set up recurring aperture maintenance/);
        $id++;
    }

    my $ticket = RT::Ticket->new(RT->SystemUser);
    ok( $ticket->Load($id), "Loaded ticket $id" );
    ok($ticket->SetStatus('resolved'), "Ticket $id resolved");

    $day->add( days => 1 );
    ok(!(RT::Repeat::Ticket::Run->run('-date=' . $day->ymd)),
       'Ran recurrence script for tomorrow.');

    my $ticket1 = RT::Ticket->new(RT->SystemUser);
    ok( !($ticket1->Load($id + 1)), "Ticket " . ($id+1) . " not created" );
}

{
    diag "Test ending by a date";
    my $daily_id = run_tests($baseurl, $m);

    # End after 3.
    ok( $m->goto_ticket($daily_id), "Found ticket $daily_id.");
    $m->follow_link_ok( {text => 'Recurrence'}, 'Loaded recurrence edit' );

    my $set_day = DateTime->now->add( days => 3 );
    diag "Set end date to " . $set_day->ymd;
    $m->form_name("ModifyRecurrence");
    $m->field('repeat-end' => 'date');
    $m->field('repeat-end-date' => $set_day->ymd);
    $m->click_button(name => 'SubmitTicket');
    $m->text_like( qr/Recurrence updated/);

    my $day = DateTime->now;
    my $id = $daily_id;
    for (1..3){
        my $next_id = $id + 1;
        my $ticket = RT::Ticket->new(RT->SystemUser);

        ok( $ticket->Load($id), "Loaded ticket $id");
        ok($ticket->SetStatus('resolved'), "Ticket $id resolved");

        $day->add( days => 1 );
        ok(!(RT::Repeat::Ticket::Run->run('-date=' . $day->ymd)),
           'Ran recurrence script for ' . $day->ymd );
        ok( $m->goto_ticket($next_id), "Recurrence ticket $next_id created.");
        $m->text_like( qr/Set up recurring aperture maintenance/);
        $id++;
    }

    my $ticket = RT::Ticket->new(RT->SystemUser);
    ok( $ticket->Load($id), "Loaded ticket $id" );
    ok($ticket->SetStatus('resolved'), "Ticket $id resolved");

    $day->add( days => 1 );
    ok(!(RT::Repeat::Ticket::Run->run('-date=' . $day->ymd)),
       'Ran recurrence script for tomorrow.');

    my $ticket1 = RT::Ticket->new(RT->SystemUser);
    ok( !($ticket1->Load($id + 1)), "Ticket " . ($id+1) . " not created" );
}


sub run_tests{
    my ($baseurl, $m) = @_;

    ok( $m->login( 'root', 'password' ), 'logged in' );

    $m->submit_form_ok({
                        form_name => 'CreateTicketInQueue',
                        fields    => {
                                      'Queue' => 'General' },
                       }, 'Click to create ticket');

    $m->content_contains('Enable Recurrence');

    diag "Create a ticket with a recurrence in the General queue.";

    $m->submit_form_ok({
                        form_name => 'TicketCreate',
                        fields    => {
                                      'Subject' => 'Set up recurring aperture maintenance',
                                      'Content' => 'Perform work on portals once per day',
                                      'repeat-enabled' => 1,
                                      'repeat-type' => 'daily',
                                      'repeat-details-daily' => 'day',
                                      'repeat-details-daily-day' => 1,
                                     },}, 'Create');

    $m->text_like( qr/Ticket\s(\d+)\screated in queue/);

    my ($daily_id) = $m->content =~ /Ticket\s(\d+)\screated in queue/;
    ok($daily_id, "Created ticket with id: $daily_id");

    my $ticket = RT::Ticket->new(RT->SystemUser);
    $ticket->Load($daily_id);


    return $daily_id;
}
