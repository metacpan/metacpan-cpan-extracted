use strict;
use warnings;

use RT::Extension::RepeatTicket::Test tests => 20;

use_ok('RT::Extension::RepeatTicket');
require_ok('bin/rt-repeat-ticket');

my ( $baseurl, $m ) = RT::Test->started_ok();

ok( $m->login( 'root', 'password' ), 'logged in' );

$m->submit_form_ok({
    form_name => 'CreateTicketInQueue',
    fields    => {
       'Queue' => 'General' },
    }, 'Click to create ticket');

$m->content_contains('Enable Recurrence');

diag "Create a ticket with a recurrence in the General queue.";

my $day = DateTime->now;
$m->submit_form_ok({
    form_name => 'TicketCreate',
    fields    => {
        'Subject' => 'Set up monthly aperture maintenance',
        'Content' => 'Perform work on portals on the first of each month',
        'repeat-lead-time' => 21,
        'repeat-coexistent-number' => 1,
        'repeat-enabled' => 1,
        'repeat-type' => 'yearly',
        'repeat-details-yearly-day-month' => $day->month,
        'repeat-details-yearly-day-day' => $day->day,
     },}, 'Create');

$m->text_like( qr/Ticket\s(\d+)\screated in queue/);

my $yearly_id = $m->content =~ /Ticket\s(\d+)\screated in queue/;
ok($yearly_id, "Created ticket with id: $yearly_id");

my $ticket1 = RT::Ticket->new(RT->SystemUser);
ok( $ticket1->Load($yearly_id), "Loaded ticket $yearly_id");
ok($ticket1->SetStatus('resolved'), "Ticket $yearly_id resolved");

# This is to get the day 21 days before the next recurrence to match lead time.
# DateTime cautions there are times when adding and subtracting are not 100%
# reversible.
$day->add( years => 1 );
$day->subtract( days => 21 );
ok(!(RT::Repeat::Ticket::Run->run('-date=' . $day->ymd)), 'Ran recurrence script for: ' . $day->ymd);

my $second = $yearly_id + 1;
ok( $m->goto_ticket($second), "Recurrence ticket $second created.");

my $ticket2 = RT::Ticket->new(RT->SystemUser);
$ticket2->Load($second);
is($ticket2->StartsObj->ISO(Time => 0), $day->ymd, 'Starts 21 days before due: ' . $day->ymd);
$day->add( days => 21 );
is( $ticket2->DueObj->ISO(Time => 0), $day->ymd, 'Due on: ' . $day->ymd);
