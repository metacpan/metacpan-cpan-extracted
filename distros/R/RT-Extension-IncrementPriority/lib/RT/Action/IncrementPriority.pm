# BEGIN BPS TAGGED BLOCK {{{
#
# COPYRIGHT:
#
# Copyright (c) 2015 Genome Research Ltd.
#
# This software is Copyright (c) 1996-2014 Best Practical Solutions, LLC
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

=head1 NAME

    RT::Action::IncrementPriority - will increment a ticket's priority by 1 each time it is run.

=head1 DESCRIPTION

IncrementPriority is a ScripAction that will increment a ticket's 
current priority by one, unless the ticket's FinalPriority is set 
to a non-zero value and the ticket's Priority has already reached 
or exceeded the FinalPriority. 

This action is intended to be called by an RT escalation tool. 
One such tool is called rt-crontool and is located in $RTHOME/bin 
(see C<rt-crontool -h> for more details).

=head1 USAGE

Once the ScripAction is installed, the following script in "cron"
will increment priority for all 'new' or 'open' tickets:

    rt-crontool --search RT::Search::FromSQL --search-arg \
    "(Status='new' OR Status='open')" \
    --action RT::Action::IncrementPriority

=head1 CONFIGURATION

IncrementPriority's behavior can be controlled by two options:

=over 4

=item RecordTransaction - defaults to false and if option is true then
causes the tool to create a transaction on the ticket when it is escalated.

=item UpdateLastUpdated - which defaults to true and updates the LastUpdated
field when the ticket is escalated, otherwise don't touch anything.

=back

You cannot set "UpdateLastUpdated" to false unless "RecordTransaction"
is also false. Well, you can, but we'll just ignore you.

You can set this options using either in F<RT_SiteConfig.pm>, as action
argument in call to the rt-crontool or in DB if you want to use the action
in scrips.

From a shell you can use the following command to silently increment the 
priority of all tickets with either 'new' or 'open' Status:

    rt-crontool --search RT::Search::FromSQL \
    --search-arg "(Status='new' OR Status='open')" \
    --action RT::Action::IncrementPriority \
    --action-arg "UpdateLastUpdated: 0"

Or alternatively, to do the same thing but to update the LastUpdated 
timestamp and record a transaction, you could run:

    rt-crontool --search RT::Search::FromSQL \
    --search-arg "(Status='new' OR Status='open')" \
    --action RT::Action::IncrementPriority \
    --action-arg "RecordTransaction: 1"

This ScripAction uses RT's internal _Set or __Set calls to set ticket
priority without running scrips or recording a transaction on each
update, if it's been said to.

=cut

package RT::Action::IncrementPriority;

use strict;
use warnings;
use base qw(RT::Action);

#Do what we need to do and send it out.

#What does this type of Action does

sub Describe {
    my $self = shift;
    my $class = ref($self) || $self;
    return "$class will increment a ticket's priority by one, unless its final priority is greater than zero and it has already reached or exceeded the final priority.";
}

sub Prepare {
    my $self = shift;

    my $ticket = $self->TicketObj;

    if ( $ticket->FinalPriority > 0 && $ticket->Priority >= $ticket->FinalPriority ) {
        $RT::Logger->debug('Current priority is greater than final. Not escalating.');
        return 1;
    }

    $self->{'new_priority'} = $ticket->Priority + 1;

    return 1;
}

sub Commit {
    my $self = shift;

    my $new_value = $self->{'new_priority'};
    return 1 unless defined $new_value;

    my $ticket = $self->TicketObj;
    # if the priority hasn't changed do nothing
    return 1 if $ticket->Priority == $new_value;

    # override defaults from argument
    my ($record, $update) = (0, 1);
    {
        my $arg = $self->Argument || '';
        if ( $arg =~ /RecordTransaction:\s*(\d+)/i ) {
            $record = $1;
            $RT::Logger->debug("Overrode RecordTransaction: $record");
        }
        if ( $arg =~ /UpdateLastUpdated:\s*(\d+)/i ) {
            $update = $1;
            $RT::Logger->debug("Overrode UpdateLastUpdated: $update");
        }
        $update = 1 if $record;
    }

    $RT::Logger->debug(
        'Incrementing priority of ticket #'. $ticket->Id
        .' from '. $ticket->Priority .' to '. $new_value
        .' and'. ($record? '': ' do not') .' record a transaction'
        .' and'. ($update? '': ' do not') .' touch last updated field'
	);

    my ( $val, $msg );
    unless ( $record ) {
        unless ( $update ) {
            ( $val, $msg ) = $ticket->__Set(
                Field => 'Priority',
                Value => $new_value,
		);
        }
        else {
            ( $val, $msg ) = $ticket->_Set(
                Field => 'Priority',
                Value => $new_value,
                RecordTransaction => 0,
		);
        }
    }
    else {
        ( $val, $msg ) = $ticket->SetPriority( $new_value );
    }

    unless ($val) {
        $RT::Logger->error( "Couldn't set new priority value: $msg" );
        return (0, $msg);
    }
    return 1;
}

RT::Base->_ImportOverlays();

1;

=head1 AUTHORS

Joshua C. Randall E<lt>jcrandall@alum.mit.eduE<gt>

Kevin Riggle E<lt>kevinr@bestpractical.comE<gt>

Ruslan Zakirov E<lt>ruz@bestpractical.comE<gt>

=cut
