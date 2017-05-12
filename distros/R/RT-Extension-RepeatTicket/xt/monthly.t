use strict;
use warnings;

use RT::Extension::RepeatTicket::Test tests => undef;

use_ok('RT::Extension::RepeatTicket');
require_ok('bin/rt-repeat-ticket');

RT::Config->Set('RepeatTicketSubjectFormat', '__Due__ __Subject__');

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
        'repeat-lead-time' => 14,
        'repeat-coexistent-number' => 1,
        'repeat-enabled' => 1,
        'repeat-type' => 'monthly',
        'repeat-details-monthly-day-day' => $day->day,
        'repeat-details-monthly-day-month' => 1,
     },}, 'Create');

$m->text_like( qr/Ticket\s(\d+)\screated in queue/);

my $monthly_id = $m->content =~ /Ticket\s(\d+)\screated in queue/;
ok($monthly_id, "Created ticket with id: $monthly_id");

my $ticket1 = RT::Ticket->new(RT->SystemUser);
ok( $ticket1->Load($monthly_id), "Loaded ticket $monthly_id");
ok($ticket1->SetStatus('resolved'), "Ticket $monthly_id resolved");

# This is to get the day 14 days before the next recurrence to match lead time.
# DateTime cautions there are times when adding and subtracting are not 100%
# reversible.
$day->add( months => 1 );
$day->subtract( days => 14 );
ok(!(RT::Repeat::Ticket::Run->run('-date=' . $day->ymd)), 'Ran recurrence script for: ' . $day->ymd);

my $second = $monthly_id + 1;
ok( $m->goto_ticket($second), "Recurrence ticket $second created.");

my $ticket2 = RT::Ticket->new(RT->SystemUser);
$ticket2->Load($second);
is($ticket2->StartsObj->ISO(Time => 0), $day->ymd, 'Starts 14 days before due: ' . $day->ymd);
$day->add( days => 14 );
is( $ticket2->DueObj->ISO(Time => 0), $day->ymd, 'Due on: ' . $day->ymd);

is( $ticket2->Subject, $ticket2->DueObj->AsString . ' Set up monthly aperture maintenance',
    'Ticket subject matches subject configuration: ' . $ticket2->Subject);

undef $m;
done_testing;
