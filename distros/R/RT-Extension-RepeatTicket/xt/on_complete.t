use strict;
use warnings;

use RT::Extension::RepeatTicket::Test tests => 22;

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

diag "Create a recurrence that starts based on completion of previous ticket.";

my $day = DateTime->now;
$m->submit_form_ok({
    form_name => 'TicketCreate',
    fields    => {
        'Subject' => 'Set up monthly aperture maintenance',
        'Content' => 'Perform work on portals on the first of each month',
        'repeat-enabled' => 1,
        'repeat-type' => 'monthly',
        'repeat-details-monthly' => 'complete',
        'repeat-details-monthly-complete' => 0,
     },}, 'Create');

$m->text_like( qr/Ticket\s(\d+)\screated in queue/);

my $monthly_id = $m->content =~ /Ticket\s(\d+)\screated in queue/;
ok($monthly_id, "Created ticket with id: $monthly_id");

my $second = $monthly_id + 1;
my $ticket2 = RT::Ticket->new(RT->SystemUser);
ok( !($ticket2->Load($second)), "Ticket $second not created initially");

ok(!(RT::Repeat::Ticket::Run->run('-date=' . $day->ymd)), 'Ran recurrence script for: ' . $day->ymd);
ok( !($ticket2->Load($second)), "Ticket $second not created after rt-repeat-ticket");

my $ticket1 = RT::Ticket->new(RT->SystemUser);
ok( $ticket1->Load($monthly_id), "Loaded ticket $monthly_id");
ok($ticket1->SetStatus('resolved'), "Ticket $monthly_id resolved");

ok(!(RT::Repeat::Ticket::Run->run('-date=' . $day->ymd)), 'Ran recurrence script for: ' . $day->ymd);

ok( $m->goto_ticket($second), "Recurrence ticket $second created.");

$ticket2->Load($second);
is($ticket2->StartsObj->ISO(Time => 0), $day->ymd, 'Starts 14 days before due: ' . $day->ymd);

# TODO: Better define due behavior for on complete recurrence.
#$day->add( days => 14 );
#is( $ticket2->DueObj->ISO(Time => 0), $day->ymd, 'Due on: ' . $day->ymd);
