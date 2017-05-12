use strict;
use warnings;

use RT::Extension::AutomaticAssignment::Test tests => undef;

my $queue = RT::Queue->new(RT->SystemUser);
$queue->Load('General');
ok($queue->Id, 'loaded General queue');

my $root_user = RT::User->new(RT->SystemUser);
$root_user->Load('root');
ok($root_user->Id, 'loaded root user');

my $scrip = RT::Scrip->new(RT->SystemUser); 
my ($ok, $msg) = $scrip->Create(
    Queue => $queue->Id,
    ScripCondition => 'On Create',
    ScripAction => 'Automatic Assignment',
    Template => 'Blank',
);
ok($ok, "created On Create Automatic Assignment scrip");

{
    my $ticket = RT::Ticket->new(RT->SystemUser);
    $ticket->Create(
        Queue => $queue->Id,
        Subject => "no automatic assignment config yet",
    );
    ok($ticket->Id, 'created ticket');
    is($ticket->Owner, RT->Nobody->Id, 'no owner because no automatic assignment config yet');
}

($ok, $msg) = RT::Extension::AutomaticAssignment->_SetConfigForQueue(
    $queue,
    [ ], # no filters
    { ClassName => 'Random' },
);
ok($ok, "set AutomaticAssignment config");

{
    my $ticket = RT::Ticket->new(RT->SystemUser);
    $ticket->Create(
        Queue => $queue->Id,
        Subject => "no automatic assignment config yet",
    );
    ok($ticket->Id, 'created ticket');
    is($ticket->Owner, $root_user->Id, 'automatically assigned ticket');
}

done_testing;

