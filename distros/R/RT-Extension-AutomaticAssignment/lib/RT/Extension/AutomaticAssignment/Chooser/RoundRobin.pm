package RT::Extension::AutomaticAssignment::Chooser::RoundRobin;
use strict;
use warnings;
use base 'RT::Extension::AutomaticAssignment::Chooser';
use List::Util 'reduce';

sub ChooseOwnerForTicket {
    my $class   = shift;
    my $ticket  = shift;
    my @users   = @{ shift(@_) };
    my $config  = shift;
    my $context = shift;

    my $queue = $ticket->Queue;
    my $attr = 'AutomaticAssignment-RoundRobin-Queue' . $queue;

    my %last_assignment;
    for my $user (@users) {
        my $attr = $user->FirstAttribute($attr);
        $last_assignment{$user->Id} = $attr->Content if $attr;
        $last_assignment{$user->Id} ||= 0;
    }

    # find the user whose last round-robin automatic assignment in this queue
    # was the longest time ago
    my $owner = reduce {
        $last_assignment{$a->Id} < $last_assignment{$b->Id} ? $a : $b
    } @users;

    if ($owner && !$context->{dry_run}) {
        $owner->SetAttribute(Name => $attr, Content => time);
    }

    return $owner;
}

sub Description { "Round Robin" }

1;

