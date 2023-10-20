use strict;
use warnings;

use RT::Extension::RepeatTicket::Test tests => undef;

use_ok('RT::Extension::RepeatTicket');
require_ok('bin/rt-repeat-ticket');

my ( $baseurl, $m ) = RT::Test->started_ok();
{
    diag "Run with repeat-create-on-recurring-date value of 1 so repeat-coexistent-number is 0";
    my $daily_id = run_tests($baseurl, $m);

    # A new ticket should be created for any day recurrence script runs for after start date of today
    my $today = DateTime->now;
    my $next_id = $daily_id + 1;
    ok(!(RT::Repeat::Ticket::Run->run()), 'Ran recurrence script for today.');
    my $ticket = RT::Ticket->new(RT->SystemUser);
    ok(!($ticket->Load($next_id)), "No ticket created for today");

    my $tomorrow = DateTime->now->add( days => 1 );
    ok(!(RT::Repeat::Ticket::Run->run('-date=' . $tomorrow->ymd)), 'Ran recurrence script for tomorrow.');
    ok($m->goto_ticket($next_id), "Recurrence ticket $next_id created for tomorrow.");
    $m->text_like( qr/Set up recurring aperture maintenance/);
    $ticket = RT::Ticket->new(RT->SystemUser);
    ok($ticket->Load($next_id), "Loaded ticket $next_id");
    is($ticket->StartsObj->ISO(Time => 0), $tomorrow->ymd, 'Starts tomorrow');
    $tomorrow->add( days => 3 );
    is($ticket->DueObj->ISO(Time => 0), $tomorrow->ymd, 'Due 3 days from tomorrow');

    my $three_months = DateTime->now->add( months => 3 );
    $next_id = $next_id + 1;
    ok(!(RT::Repeat::Ticket::Run->run('-date=' . $three_months->ymd)), 'Ran recurrence script for 3 months from now.');
    ok($m->goto_ticket($next_id), "Recurrence ticket $next_id created for 3 months from now.");
    $m->text_like( qr/Set up recurring aperture maintenance/);
    $ticket = RT::Ticket->new(RT->SystemUser);
    ok($ticket->Load($next_id), "Loaded ticket $next_id");
    is($ticket->StartsObj->ISO(Time => 0), $three_months->ymd, 'Starts 3 months from now');
    $three_months->add( days => 3 );
    is($ticket->DueObj->ISO(Time => 0), $three_months->ymd, 'Due 3 days from 3 months from now');

    # a new ticket should be created even if there are existing tickets on the same day
    $tomorrow = DateTime->now->add( days => 1 );
    $next_id = $next_id + 1;
    ok(!(RT::Repeat::Ticket::Run->run('-date=' . $tomorrow->ymd)), 'Ran recurrence script for tomorrow.');
    ok($m->goto_ticket($next_id), "Recurrence ticket $next_id created for tomorrow.");
    $m->text_like( qr/Set up recurring aperture maintenance/);
    $ticket = RT::Ticket->new(RT->SystemUser);
    ok($ticket->Load($next_id), "Loaded ticket $next_id");
    is($ticket->StartsObj->ISO(Time => 0), $tomorrow->ymd, 'Starts tomorrow');
    $tomorrow->add( days => 3 );
    is($ticket->DueObj->ISO(Time => 0), $tomorrow->ymd, 'Due 3 days from tomorrow');

    $three_months = DateTime->now->add( months => 3 );
    $next_id = $next_id + 1;
    ok(!(RT::Repeat::Ticket::Run->run('-date=' . $three_months->ymd)), 'Ran recurrence script for 3 months from now.');
    ok($m->goto_ticket($next_id), "Recurrence ticket $next_id created for 3 months from now.");
    $m->text_like( qr/Set up recurring aperture maintenance/);
    $ticket = RT::Ticket->new(RT->SystemUser);
    ok($ticket->Load($next_id), "Loaded ticket $next_id");
    is($ticket->StartsObj->ISO(Time => 0), $three_months->ymd, 'Starts 3 months from now');
    $three_months->add( days => 3 );
    is($ticket->DueObj->ISO(Time => 0), $three_months->ymd, 'Due 3 days from 3 months from now');
}

sub run_tests{
    my ($baseurl, $m) = @_;

    ok( $m->login( 'root', 'password' ), 'logged in' );

    $m->submit_form_ok( { form_name => 'CreateTicketInQueue', }, 'Click to create ticket' );

    $m->content_contains('Enable Recurrence');

    diag "Create a ticket with a recurrence in the General queue.";

    $m->submit_form_ok(
        {   form_name => 'TicketCreate',
            fields    => {
                'Subject'                         => 'Set up recurring aperture maintenance',
                'Content'                         => 'Perform work on portals once per day M - F',
                'repeat-enabled'                  => 1,
                'repeat-type'                     => 'daily',
                'repeat-details-daily'            => 'day',
                'repeat-details-daily-day'        => 1,
                'repeat-create-on-recurring-date' => 1,
                'repeat-coexistent-number'        => 0,
                'repeat-lead-time'                => 3,
                'repeat-start-date'               => DateTime->now->ymd,
            },
            button => 'SubmitTicket',
        },
        'Create'
    );

    $m->text_like( qr/Ticket\s(\d+)\screated in queue/);

    my ($daily_id) = $m->content =~ /Ticket\s(\d+)\screated in queue/;
    ok($daily_id, "Created ticket with id: $daily_id");

    # resolving the parent ticket should have no affect on creating new tickets
    my $ticket = RT::Ticket->new(RT->SystemUser);
    ok($ticket->Load($daily_id), "Loaded ticket $daily_id");
    ok($ticket->SetStatus('resolved'), "Ticket $daily_id resolved");

    return $daily_id;
}

done_testing;
