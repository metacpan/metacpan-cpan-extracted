use strict;
use warnings;

use RT::Extension::MandatoryOnTransition::Test tests => undef, config => <<CONFIG
Set( %MandatoryOnTransition,
     'General' => {
         'Foo' => [ 'TimeWorked' ],
     }
);
CONFIG
  ;

my ( $baseurl, $m ) = RT::Test->started_ok();

ok( $m->login(), 'logged in' );

my $queue_general = RT::Test->load_or_create_queue( Name => 'General' );
my $queue_foo     = RT::Test->load_or_create_queue( Name => 'Foo' );

my $ticket = RT::Test->create_ticket(
    Queue   => 'General',
    Subject => 'Test ticket for queue change',
    Content => 'Testing',
);

$m->goto_ticket( $ticket->id );
$m->follow_link_ok( { text => 'Jumbo' } );
$m->submit_form_ok(
    {   form_name => 'TicketModifyAll',
        fields    => { Queue => $queue_foo->id, },
        button    => 'SubmitTicket',
    },
    'Change queue without required TimeWorked',
);

$m->text_contains( 'Time Worked is required when changing Queue' );

$ticket->Load( $ticket->id );
is( $ticket->Queue, $queue_general->id, 'Queue is not updated' );

$m->submit_form_ok(
    {   form_name => 'TicketModifyAll',
        fields    => { Queue => $queue_foo->id, TimeWorked => 10 },
        button    => 'SubmitTicket',
    },
    'Change queue with required TimeWorked',
);
$m->text_contains( 'Worked 10 minutes' );
$m->text_contains( 'Queue changed from General to Foo' );

$ticket->Load( $ticket->id );
is( $ticket->Queue, $queue_foo->id, 'Queue is updated' );

done_testing;
