use strict;
use warnings;

use RT::Extension::RepeatTicket::Test tests => 31;

use_ok('RT::Extension::RepeatTicket');
require_ok('bin/rt-repeat-ticket');

my ( $baseurl, $m ) = RT::Test->started_ok();

ok( $m->login( 'root', 'password' ), 'logged in' );

$m->submit_form_ok( { form_name => 'CreateTicketInQueue', }, 'Click to create ticket' );

$m->content_contains('Enable Recurrence');

diag "Create a ticket with a recurrence in the General queue.";

$m->submit_form_ok(
    {   form_name => 'TicketCreate',
        fields    => {
            'Subject'                         => 'Set up recurring aperture maintenance',
            'Content'                         => 'Perform work on portals on Tuesday and Thursday',
            'repeat-lead-time'                => 7,
            'repeat-coexistent-number'        => 2,
            'repeat-enabled'                  => 1,
            'repeat-type'                     => 'weekly',
            'repeat-details-weekly'           => 'week',
            'repeat-details-weekly-week'      => 1,
            'repeat-details-weekly-weeks'     => 'th',
            'repeat-create-on-recurring-date' => 0,
        },
        button => 'SubmitTicket',
    },
    'Create'
);

$m->text_like( qr/Ticket\s(\d+)\screated in queue/);

my $weekly_id = $m->content =~ /Ticket\s(\d+)\screated in queue/;
ok($weekly_id, "Created ticket with id: $weekly_id");

# Submiting the form with concurrent = 2 runs the create
my $second = $weekly_id + 1;
ok( $m->goto_ticket($second), "Recurrence ticket $second created.");

my $ticket2 = RT::Ticket->new(RT->SystemUser);
$ticket2->Load($second);
my $day = DateTime->now;
GetThursday($day);
is($ticket2->StartsObj->ISO(Time => 0), $day->ymd, 'Starts tomorrow: ' . $day->ymd);
$day->add( days => 7 );
is( $ticket2->DueObj->ISO(Time => 0), $day->ymd, 'Due in 7 days: ' . $day->ymd);

my $tomorrow = DateTime->now->add( days => 1 );
my $ticket1 = RT::Ticket->new(RT->SystemUser);
ok( $ticket1->Load($weekly_id), "Loaded ticket $weekly_id");
ok($ticket1->SetStatus('resolved'), "Ticket $weekly_id resolved");
ok(!(RT::Repeat::Ticket::Run->run('-date=' . $tomorrow->ymd)), 'Ran recurrence script for tomorrow.');

my $third = $weekly_id + 2;
ok( $m->goto_ticket($third), "Recurrence ticket $third created.");
$m->text_like( qr/Set up recurring aperture maintenance/);

my $ticket3 = RT::Ticket->new(RT->SystemUser);
$ticket3->Load($third);
GetThursday($day);
is($ticket3->StartsObj->ISO(Time => 0), $day->ymd, 'Starts tomorrow: ' . $day->ymd);
$day->add( days => 7 );
is( $ticket3->DueObj->ISO(Time => 0), $day->ymd, 'Due in 7 days: ' . $day->ymd);

my $thurs = DateTime->now;
GetThursday($thurs);
ok(!(RT::Repeat::Ticket::Run->run('-date=' . $thurs->ymd)), 'Ran recurrence script for next Thursday.');
my $ticket4 = RT::Ticket->new(RT->SystemUser);
ok(!($ticket4->Load($third + 1)), 'No fourth ticket created.');

diag "Run after changing create-on-recurring-date to 1";
# change to create on recurring date and then a 4th ticket should be created
ok( $m->goto_ticket($weekly_id), "Found ticket $weekly_id.");
$m->follow_link_ok( {text => 'Recurrence'}, 'Loaded recurrence edit' );

$m->form_name("ModifyRecurrence");
$m->field('repeat-create-on-recurring-date' => 1);
$m->click_button(name => 'SubmitTicket');
$m->text_like( qr/Recurrence updated/);

ok(!(RT::Repeat::Ticket::Run->run('-date=' . $thurs->ymd)), 'Ran recurrence script for next Thursday again.');
ok($ticket4->Load($third + 1), 'Fourth ticket created after changing create-on-recurring-date to 1.');

# Didn't want to add DateTime::Format::Natural as a dependency.
sub GetThursday {
    my $dt = shift;

    foreach (1..7){
        return if $dt->day_of_week == 4;
        $dt->add( days => 1);
    }
}
