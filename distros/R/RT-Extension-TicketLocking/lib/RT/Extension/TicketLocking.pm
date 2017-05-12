# BEGIN BPS TAGGED BLOCK {{{
#
# COPYRIGHT:
#
# This software is Copyright (c) 2007-2015 Best Practical Solutions, LLC
#                                          <sales@bestpractical.com>
#
# (Except where explicitly superseded by other copyright notices)
#
#
# LICENSE:
#
# This work is made available to you under the terms of Version 2 of
# the GNU General Public License. A copy of that license should have
# been provided with this software, but in any event can be snarfed
# from www.gnu.org.
#
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301 or visit their web page on the internet at
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.html.
#
#
# CONTRIBUTION SUBMISSION POLICY:
#
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of
# the GNU General Public License and is only of importance to you if
# you choose to contribute your changes and enhancements to the
# community by submitting them to Best Practical Solutions, LLC.)
#
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with
# Request Tracker, to Best Practical Solutions, LLC, you confirm that
# you are the copyright holder for those contributions and you grant
# Best Practical Solutions,  LLC a nonexclusive, worldwide, irrevocable,
# royalty-free, perpetual, license to use, copy, create derivative
# works based on those contributions, and sublicense and distribute
# those contributions and any derivatives thereof.
#
# END BPS TAGGED BLOCK }}}

use v5.8.3;
use strict;
use warnings;

package RT::Extension::TicketLocking;

our $VERSION = '1.06';

=head1 NAME

RT::Extension::TicketLocking - Enables users to place advisory locks on tickets

=head1 RT VERSION

Works with RT 4.0, 4.2 and 4.4.

=head1 DESCRIPTION

Locks can be of several different types. Current types are:

=over 4

=item hard (manual) lock

A lock can be initiated manually by clicking the "Lock" link on one of the pages
for the ticket. However, hard locks are available only to users who can ModifyTicket.

=item take lock

This is only applicable within RTIR. See L</RTIR> section below.

=item auto lock

A lock is created whenever a user performs an action on a ticket that takes
multiple steps if a hard lock is not already in place for that ticket.

An auto lock is removed once the user is done with whatever he was doing
on the page (e.g., when he clicks "Save Changes" on the Edit page).
It is also removed if the Unlock link is clicked from a page that generated
an auto lock.

Auto-lock is set for the following actions in RT:

    - Comment
    - Reply
    - Resolve

RTIR's user may find list of actions below.

=back

Locks are advisory: if a ticket is locked by one user, other users
will be given a notification (in red) that another user has locked
the ticket, with the locking user's name and how long he has had
it locked for, but they will still be allowed to edit and submit
changes on the ticket.

When a user locks a ticket (auto lock or hard lock), they are given
a notification informing them of their lock and how long they have
had the ticket locked (in some other color - currently green).

=head2 Removing locks

Locks will remain in place until:

=over 4

=item * The user is done editing/replying/etc. (for auto locks, if
there is no hard lock on the ticket)

=item * A lock can be removed manually by clicking the "Unlock" link on one
of the pages for the ticket. This removes B<any> type of lock.

=item * The user logs out

=item * A configurable expiry period has elapsed (if the $LockExpiry
config variable has been set to a value greater than zero)

=back

When a user unlocks a ticket (auto unlock or hard unlock),
they are given a notification informing them that their
lock has been removed, and how long they had the ticket
locked for.

=head2 Merging tickets

When a locked ticket (hard or take lock) is merged into another ticket,
the ticket being merged into will get the lock type of the ticket being
merged from. This lock shift is conditional upon priority, as
usual - if the merged from ticket has a lock of a lower priority than
the merged-to ticket, the merged-to ticket will retain its lock.
If the merged-to ticket is locked by a different user, that user will
retain the lock. Basically, the merged-to ticket will retain its lock
if it is higher priority than the lock on the ticket being merged from.

=head2 RTIR

Within RTIR auto locks are applied for the following actions:

    - Edit
    - Split
    - Merge
    - Advanced
    - Reply
    - Resolve
    - Reject
    - Comment
    - Remove

As well, there is special type of lock implemented in RTIR. When a
user clicks the "Take" link for an RTIR Incident ticket, a Take lock
is added. This lock will only be removed when the IR is linked to
a new or existing Incident. If RTIR is not installed, this type
will not be available.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::TicketLocking');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::TicketLocking));

or add C<RT::Extension::TicketLocking> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back


=head1 CONFIGURATION

=head2 LockExpiry option

In the config you can set LockExpiry option to a number of seconds,
the longest time a lock can remain without being automatically removed,
for example:

    Set( $LockExpiry, 5*60 ); # lock expires after five minutes

If you don't wish to have your locks automatically expire, simply
set $LockExpiry to a false (zero or undef) value. This is the default if
you do not provide a $LockExpiry.

=head2 Allowing users to use 'MyLocks' portlet

The extension comes with a portlet users can place on thier home
page RT's or RTIR's. Using this portlet user can easily jump to
locked tickets, remove particular lock or all locks at once.

If you want the MyLocks portlet to be available then you have
to place it in the list of allowed components.

For RT:

    Set($HomepageComponents, [qw(
        MyLocks 
        ... list of another portlets ...
    )]);

People can then choose to add the portlet to their homepage
in Preferences -> 'RT at a glance'.

If you are running RTIR, and want the portlet to be available
from the RTIR home page, you will need to do something similar
to set the RTIR_HomepageComponents array in your config file,
like this:

    Set(@RTIR_HomepageComponents, qw(
        MyLocks
        ... list of another portlets ...
    ));

People can then choose to add the portlet to their homepage
in Preferences -> 'RTIR Home'.

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-TicketLocking@rt.cpan.org|mailto:bug-RT-Extension-TicketLocking@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-TicketLocking>.

=head1 COPYRIGHT

This extension is Copyright (C) 2007-2014 Best Practical Solutions, LLC.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

# IMPLEMENTATION DETAILS
#  Each type is associated with a priority. Current priorities are as follows,
#  from highest priority to lowest:
#      - Hard
#      - Take (when applicable)
#      - Auto
#  
#  This allow us to store only one lock record with higher priority.

use RT::Ticket;
package RT::Ticket;

our @LockTypes = qw(Auto Take Hard);
our %CheckRightOnLock = (
    Hard => 'ModifyTicket',
);

sub LockPriority {
    my $self = shift;
    my $type = shift;
    
    my $priority;
    for( my $i = 0; $i < scalar @LockTypes; $i++) {
        $priority = $i if lc( $LockTypes[ $i ] ) eq lc( $type );
    }
    $RT::Logger->error( "There is no type '$type' in the list of lock types")
        unless defined $priority;

    return $priority || 0;
}

sub Locked {
    my $ticket = shift;

    my $lock = $ticket->FirstAttribute('RT_Lock');
    return $lock unless $lock;

    return $lock unless my $expiry = RT->Config->Get('LockExpiry');

    my $duration = time() - $lock->Content->{'Timestamp'};
    unless ( $duration < $expiry ) {
        $ticket->DeleteAttribute('RT_Lock');
        undef $lock;
    }
    return $lock;
}

sub Lock {
    my $ticket = shift;
    my $type = shift || 'Auto';

    if ( my $lock = $ticket->Locked() ) {
        return undef if $lock->Content->{'User'} != $ticket->CurrentUser->id;
        my $current_type = $lock->Content->{'Type'};
        return undef if $ticket->LockPriority( $type ) <= $ticket->LockPriority( $current_type );
    }

    if ( my $right = $CheckRightOnLock{ $type } ) {
        return undef unless $ticket->CurrentUserHasRight('ModifyTicket');
    }

    $ticket->Unlock($type);    #Remove any existing locks (because this one has greater priority)
    my $id = $ticket->id;
    my $username = $ticket->CurrentUser->Name;
    $ticket->SetAttribute(
        Name    => 'RT_Lock',
        Description => "$type lock on Ticket $id by user $username",
        Content => {
            User      => $ticket->CurrentUser->id,
            Timestamp => time(),
            Type => $type,
            Ticket => $id
        }
    );
}


sub Unlock {
    my $ticket = shift;
    my $type = shift || 'Auto';

    my $lock = $ticket->RT::Ticket::Locked();
    return (undef, $ticket->CurrentUser->loc("This ticket was not locked.")) unless $lock;
    return (undef, $ticket->CurrentUser->loc("You cannot unlock a ticket locked by another user."))
        unless $lock->Content->{User} == $ticket->CurrentUser->id;

    my $current_type = $lock->Content->{'Type'};
    return (undef, $ticket->CurrentUser->loc("There is a lock with a higher priority on this ticket."))
        if $ticket->LockPriority( $type ) < $ticket->LockPriority( $current_type );

    my $duration = time() - $lock->Content->{'Timestamp'};
    $ticket->DeleteAttribute('RT_Lock');
    return ($duration, $ticket->CurrentUser->loc("You have unlocked this ticket. It was locked for [_1] seconds.", $duration));
}


sub BreakLock {
    my $ticket = shift;
    return $ticket->DeleteAttribute('RT_Lock');
}


use RT::User;
package RT::User;

sub GetLocks {
    my $self = shift;
    
    my $attribs = RT::Attributes->new($self);
    $attribs->Limit(FIELD => 'Creator', OPERATOR=> '=', VALUE => $self->id(), ENTRYAGGREGATOR => 'AND');
    
    my $expiry = RT->Config->Get('LockExpiry');
    return $attribs->Named('RT_Lock') unless $expiry;
    my @locks;
    
    foreach my $lock ($attribs->Named('RT_Lock')) {
        my $duration = time() - $lock->Content->{'Timestamp'};
        if($duration < $expiry) {
            push @locks, $lock;
        }
        else {
            $lock->Delete();
        }
    }
    return @locks;
}

sub RemoveLocks {
    my $self = shift;
    
    my $attribs = RT::Attributes->new($self);
    $attribs->Limit(FIELD => 'Creator', OPERATOR=> '=', VALUE => $self->id(), ENTRYAGGREGATOR => 'AND');
    my @attributes = $attribs->Named('RT_Lock');
    foreach my $lock (@attributes) {
        $lock->Delete();
    }
}

1;
