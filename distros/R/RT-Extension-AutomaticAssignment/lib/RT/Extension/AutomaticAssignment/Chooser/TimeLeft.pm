package RT::Extension::AutomaticAssignment::Chooser::TimeLeft;
use strict;
use warnings;
use base 'RT::Extension::AutomaticAssignment::Chooser';
use List::Util 'reduce';

sub ChooseOwnerForTicket {
    my $class  = shift;
    my $ticket = shift;
    my @users  = @{ shift(@_) };
    my $config = shift;

    # for TimeLeft we only consider tickets in the same queue
    my $tickets = RT::Tickets->new($ticket->CurrentUser);
    $tickets->LimitQueue(VALUE => $ticket->Queue);
    $tickets->LimitToActiveStatus;

    my %timeleft_by_owner;
    while (my $ticket = $tickets->Next) {
        next if $ticket->Owner == RT->Nobody->id;
        my $time_left = $ticket->TimeLeft || ($ticket->TimeEstimated - $ticket->TimeWorked);
        next if $time_left < 0;

        $timeleft_by_owner{ $ticket->Owner } += $time_left;
    }

    return reduce { $timeleft_by_owner{$a->id} < $timeleft_by_owner{$b->id} ? $a : $b } @users;
}

sub Description { "Time Left" }

1;

