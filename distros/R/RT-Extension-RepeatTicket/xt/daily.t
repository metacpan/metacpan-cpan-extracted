use strict;
use warnings;

use RT::Extension::RepeatTicket::Test tests => undef;

use_ok('RT::Extension::RepeatTicket');
require_ok('bin/rt-repeat-ticket');

my ( $baseurl, $m ) = RT::Test->started_ok();
{
    diag "Run with default coexist value of 1";
    my $daily_id = run_tests($baseurl, $m);

    # No additional tickets should be created with a coexist value of 1.

    ok(!(RT::Repeat::Ticket::Run->run()), 'Ran recurrence script for today.');

    my $next_id = $daily_id + 1;
    my $ticket = RT::Ticket->new(RT->SystemUser);
    ok( !($ticket->Load($next_id)), "No ticket created for today.");

    my $tomorrow = DateTime->now->add( days => 1 );
    ok(!(RT::Repeat::Ticket::Run->run('-date=' . $tomorrow->ymd)), 'Ran recurrence script for tomorrow.');
    ok( !($ticket->Load($next_id)), "No ticket created for tomorrow.");

    ok( $ticket->Load($daily_id), "Loaded ticket $daily_id");
    ok($ticket->SetStatus('resolved'), "Ticket $daily_id resolved");
    ok(!(RT::Repeat::Ticket::Run->run('-date=' . $tomorrow->ymd)), 'Ran recurrence script for tomorrow.');
    ok( $m->goto_ticket($next_id), "Recurrence ticket $next_id created for tomorrow.");
    $m->text_like( qr/Set up recurring aperture maintenance/);

    my $ticket2 = RT::Ticket->new(RT->SystemUser);
    $ticket2->Load($next_id);

    is($ticket2->StartsObj->ISO(Time => 0), $tomorrow->ymd, 'Starts tomorrow');
    $tomorrow->add( days => 14 );
    is( $ticket2->DueObj->ISO(Time => 0), $tomorrow->ymd, 'Due in default 14 days');
    is( $ticket2->Subject(), 'Set up recurring aperture maintenance',
        'Got default subject: ' . $ticket2->Subject());
}

{
    diag "Run with Coexistent value of 2";
    my $daily_id = run_tests($baseurl, $m);

    # Set concurrent active tickets to 2.
    ok( $m->goto_ticket($daily_id), "Found ticket $daily_id.");
    $m->follow_link_ok( {text => 'Recurrence'}, 'Loaded recurrence edit' );

    $m->form_name("ModifyRecurrence");
    $m->field('repeat-coexistent-number' => 2);
    $m->click_button(name => 'SubmitTicket');
    $m->text_like( qr/Recurrence updated/);

    ok(!(RT::Repeat::Ticket::Run->run()), 'Ran recurrence script for today.');

    my $second = $daily_id + 1;
    ok( $m->goto_ticket($second), 'Recurrence ticket $second created for today.');
    $m->text_like( qr/Set up recurring aperture maintenance/);

    my $tomorrow = DateTime->now->add( days => 1 );
    ok(!(RT::Repeat::Ticket::Run->run('-date=' . $tomorrow->ymd)), 'Ran recurrence script for tomorrow.');

    my $third = $daily_id + 2;
    my $ticket = RT::Ticket->new(RT->SystemUser);
    ok( !($ticket->Load($third)), "Third ticket $third not created.");

    $ticket->Load($second);
    ok($ticket->SetStatus('resolved'), "Ticket $second resolved");
    ok(!(RT::Repeat::Ticket::Run->run()), 'Ran recurrence script for today.');

    ok( $m->goto_ticket($third), "Recurrence ticket $third created.");
    $m->text_like( qr/Set up recurring aperture maintenance/);
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

undef $m;
done_testing;
