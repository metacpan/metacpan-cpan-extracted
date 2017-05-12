use strict;
use warnings;

use RT::Extension::RepeatTicket::Test tests => undef;

use_ok('RT::Extension::RepeatTicket');
require_ok('bin/rt-repeat-ticket');

my $cf = RT::CustomField->new(RT->SystemUser);
ok( $cf->Create( Name => 'foo', Queue => 0, Type => 'Freeform' ) );

my ( $baseurl, $m ) = RT::Test->started_ok();

ok( $m->login( 'root', 'password' ), 'logged in' );

$m->submit_form_ok({
    form_name => 'CreateTicketInQueue',
    fields    => {
       'Queue' => 'General' },
    }, 'Click to create ticket');

$m->content_contains('Enable Recurrence');

diag "Create a ticket with a recurrence in the General queue.";

my $day = DateTime->today;

$m->submit_form_ok(
    {
        form_name => 'TicketCreate',
        fields    => {
            'Subject' => 'test cf values',
            'Content' => 'Testing CF values',
            'Object-RT::Ticket--CustomField-' . $cf->id . '-Value' => 'bar',
            'repeat-coexistent-number'                             => 2,
            'repeat-enabled'                                       => 1,
            'repeat-type'                                          => 'daily',
            'repeat-details-daily'                                 => 'day',
            'repeat-details-daily-day'                             => 1,
        },
    },
    'Create'
);

$m->text_like( qr/Ticket\s(\d+)\screated in queue/);

my $ticket_id = $m->content =~ /Ticket\s(\d+)\screated in queue/;
ok( $ticket_id, "Created ticket with id: $ticket_id" );
my $ticket = RT::Ticket->new(RT->SystemUser);
$ticket->Load($ticket_id);
is( $ticket->FirstCustomFieldValue('Original Ticket'),
    $ticket_id, 'Original Ticket is set' );

my $tomorrow = $day->clone->add( days => 1 );
ok(!(RT::Repeat::Ticket::Run->run('-date=' . $tomorrow->ymd)),
   'Ran recurrence script for two weeks from now: ' . $tomorrow->ymd );
my $second = $ticket_id + 1;
ok( $m->goto_ticket($second), "Recurrence ticket $second created.");

my $ticket2 = RT::Ticket->new( RT->SystemUser );
$ticket2->Load($second);
is( $ticket2->FirstCustomFieldValue('Original Ticket'),
    $ticket_id, 'Original Ticket is set' );
is( $ticket2->FirstCustomFieldValue('foo'), 'bar', 'cf foo is cloned' );

my ($attr) = $ticket->Attributes->Named('RepeatTicketSettings');
ok( RT::Extension::RepeatTicket::SetRepeatAttribute(
    $ticket,
    %{ $attr->Content },
    'repeat-enabled' => 0,
));

is( $ticket->FirstCustomFieldValue('Original Ticket'),
    undef, 'Original Ticket is unset' );

undef $m;
done_testing;
