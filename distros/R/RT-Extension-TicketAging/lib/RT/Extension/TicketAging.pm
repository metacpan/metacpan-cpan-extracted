package RT::Extension::TicketAging;

our $VERSION = '0.12';

use v5.8.3;
use strict;
use warnings;


=head1 NAME

RT::Extension::TicketAging - allows tickets to be made inaccessable
and finally completely deleted

=head1 DESCRIPTION

This extension allows closed tickets to be made inaccessable and
finally completely deleted as they get older.  It adds a new global
ticket field, "Age", to track a ticket's movement through the life
cycle.

The rt-aging program (see below) is used to move tickets through the
life cycle and must be run separately.

When we speak of "age" we are referring to a ticket's "LastUpdated"
property.


=head2 Default life cycle

The default life cycle is:

=over 4

=item Active

Any unresolved ticket or a ticket with unresolved children is
considered I<Active>.

=item Finished

When a ticket and all its children have been resolved it becomes
I<Finished>.  No further activity is expected on this ticket.

There is otherwise nothing special about a I<Finished> ticket.

=item Dead

When a ticket and all its children are I<Finished> and it has not been
updated for 2 months it becomes I<Dead>.  Dead tickets are just like
Finished tickets except they do not show up in RTIR's special lookup
tools.

=item Extinct

When a ticket is I<Dead> and has not been updated for 12 months it
becomes I<Extinct>.  Extinct tickets have their status set to
I<deleted>.  They won't show up in any searches unless explicitly
asked for (C<'CF.{Age} = "Extinct"'>).

=item Destroyed

When a ticket is I<Extinct> and has not been updated for 24 months and
if all linked tickets are also I<Extinct> a ticket is I<Destroyed>.
Destroyed tickets are no longer available in RT.  They are wholely
removed from RT using the Shredder.  Destroyed tickets are saved in a
SQL dump file from which they can be restored.

See L<RT::Shredder> for more information.

=item Reactivation

When users reopen a ticket (change Status from inactive to active)
it becomes Active again.

=back


=head2 rt-aging

The real work is done by the rt-aging program installed to your RT
local sbin.  In general you simply run rt-aging from the command line
or periodically from cron as an RT administrator.  It will apply the
aging rules and alter the tickets as necessary.

See L<rt-aging> for more details.


=head2 Aging configuration

=head3 Library preloading

Add the line
    C<use RT::Extension::TicketAging;> 
    
to the bottom of the RT site config, C<etc/RT_SiteConfig.pm> 
after adding all extension options described below.

This step is required to allow users to search by I<Extinct> age.

=head3 ACLs

By default we grant SeeCustomField right to all privileged users.

=head3 C<$TicketAgingFilenameTemplate>

This is the filename template used to create the Shredder dump file
when tickets are Destroyed.  Defaults to the RT::Shredder default.
Good candidates:

    Set($TicketAgingFilenameTemplate, 'aging-%t.XXXX.sql');
    # or
    Set($TicketAgingFilenameTemplate, '/var/backups/aging/%t.XXXX.sql');

See the documentation for C<<RT::Shredder->GetFileName>> for more
details.

=head3 C<$TicketAgingMap>

B<THIS IS AN EXPERIMENTAL FEATURE>

Administrators may define their own aging behaviors.

The ages available to RT are configured by changing the available
values for the C<Age> global custom field.  An administrator may
remove values to disable pre-configured options.  Adding new values
activates new age commands but if its not one of the above values you
have to configure the conditions and actions for each age.

C<$TicketAgingMap> can be set in your configuration to override or add
to the default life cycle.  Its easiest to illustrate this with code.

    Set( $TicketAgingMap, {
             AgeName => {
                 Condition => {
                     CallbackPre  => sub { ... },
                     SQL          => sub { ... },
                     CallbackPost => sub { ... },
                     Filter       => sub { ... },
                 },
                 Action => sub { ... }
             }
         });

=head3 Arguments

The aging conditions and actions generally have these arguments:

=over 4

=item Age

This is the name of the age being processed.  For example "Active".

=item Collection

This is an RT::Tickets object representing all the tickets visible to
the C<$RT::SystemUser>.  It can be filtered by the Callbacks and the
SQL.

=item Object

An individual RT::Ticket from the ticket C<Collection>.

=back


=head3 Fields

=over 4

=item AgeName

The name of your Age field.  For example, "Active".

=item Condition

Holds the rules for determining what tickets fall into this age.  The
rules are run in this order (excuse the pseudo-code):

    CallbackPre
    SQL
    CallbackPost
    foreach $Object ($Collection) {
        Filter
        Action
    }

=over 8

=item SQL

This is the TicketSQL to be run to get the tickets of this Age.
Generally its a check against LastUpdated and perhaps Status.

    SQL => sub { "LastUpdated < '-2 months'" }

The TicketSQL is run against the Collection.

Called with C<Age> and C<Collection> arguments.

Should return a valid TicketSQL string.


=item CallbackPre

=item CallbackPost

These callbacks can be used to alter the Collection before the SQL is
run or before the Filter.

Called with C<Age> and C<Collection> arguments.

Must return true on success or a tuple of C<(false, $error_message)>
on failure.

For example:

    # Search for deleted tickets
    CallbackPre => sub {
        my %args = @_;
        return $args{Collection}{allow_deleted_search} = 1;
    };


=item Filter

Each ticket found by the SQL condition in the C<Collection> is
iterated over and the C<Filter> is called on each one.  This gives an
opportunity to cull out individual tickets.

Called with C<Age>, C<Collection> and C<Object> arguments.  C<Object>
is an individual RT::Ticket from the ticket C<Collection>.

Returns true if the ticket should be included in the age, false if it
should be ignored.

    # Filter out tickets whose children are not of the same age.
    Filter => sub {
        my %args = @_;
        my $id = $args{Object}->id;

        my $find_different_children = qq{
              (CF.{Age} IS NULL OR CF.{Age} != $args{Age})
              AND Linked = $id
        };

        my $tickets = RT::Tickets->new( $RT::SystemUser );
        $tickets->{allow_deleted_search} = 1;
        $tickets->FromSQL( $find_different_children );
        return !$tickets->Count;
    }

=back

=item Action

After filtering, each ticket found in the C<Collection> is iterated
over and the C<Action> is called on each one.  This is where whatever
changes that need to be made to individual tickets when they change
age should be done.

Called with C<Age>, C<Collection> and C<Object> arguments.

Like the Callbacks, it returns true on success or a tuple of C<(false,
$error_message)> on failure.

    # Mark the ticket as deleted.
    Action => sub {
        my %args = @_;
        my $ticket = $args{Object};

        return $ticket->__Set( Field => "Status", Value => "deleted" );
    }

=back

=cut


sub loc(@) { return $RT::SystemUser->loc(@_) }

our @Ages = ();
sub Ages {
    return @Ages if @Ages;

    my $cf = RT::CustomField->new( $RT::SystemUser );
    $cf->Load('Age');
    die "Couldn't load the 'Age' custom field. May be you forgot to run `make initdb`"
        unless $cf->id;

    my $values = $cf->Values;
    while ( my $value = $values->Next ) {
        push @Ages, $value->Name;
    }
    return @Ages;
}

our $FilenameTemplate = FilenameTemplate();
sub FilenameTemplate {
    my $tmpl = RT->Config->Get('TicketAgingFilenameTemplate') || 'aging-%t.XXXX.sql';
    require File::Spec;
    unless ( File::Spec->file_name_is_absolute( $tmpl ) ) {
        require RT::Shredder;
        $tmpl = File::Spec->catfile( RT::Shredder->StoragePath, $tmpl );
    }
    return $tmpl;
}

our %Default_Map = (
    Active   => { },
    Finished => {
        Condition => {
            SQL => sub {
                return join ' OR ', map "Status = '$_'",
                    RT::Queue->InactiveStatusArray;
            },
            Filter => sub {
                my %arg = @_;
                my $id = $arg{'Object'}->id;

                my $status_condition = join ' OR ', map "Status = '$_'",
                    $arg{'Object'}->QueueObj->ActiveStatusArray;

                my $tickets = RT::Tickets->new( $RT::SystemUser );
                $tickets->FromSQL( "( $status_condition ) AND DependedOnBy = $id" );
                $tickets->RowsPerPage(1);
                return 0 if $tickets->First;

                $tickets = RT::Tickets->new( $RT::SystemUser );
                $tickets->FromSQL( "( $status_condition ) AND MemberOf = $id" );
                $tickets->RowsPerPage(1);
                return 0 if $tickets->First;

                return 1;
            },
        },
    },
    Dead => {
        Condition => {
            SQL => "LastUpdated < '-2 months'",
        },
    },
    Extinct => {
        Condition => {
            SQL => "LastUpdated < '-12 months'",
        },
        Action => sub { my %arg = @_; return $arg{'Object'}->__Set( Field => 'Status', Value => 'deleted' ) },
    },
    Destroyed  => {
        Condition => {
            CallbackPre => sub { my %arg = @_; return $arg{'Collection'}->{'allow_deleted_search'} = 1 },
            SQL => "Status = 'deleted' AND LastUpdated < '-24 months'",
            Filter => sub {
                my %arg = @_;
                my $id = $arg{'Object'}->id;
                my $query = "(CF.{Age} IS NULL OR CF.{Age} != 'Extinct') AND Linked = $id";
                my $tickets = RT::Tickets->new( $RT::SystemUser );
                $tickets->{'allow_deleted_search'} = 1;
                $tickets->FromSQL( $query );
                return !$tickets->Count;
            },
        },
        Action => sub {
            my %arg = @_;

            require RT::Shredder::Plugin;
            my $plugin = new RT::Shredder::Plugin;
            my ($status, $msg) = $plugin->LoadByName('SQLDump');
            return ($status, $msg) unless $status;
            ($status, $msg) = $plugin->TestArgs(
                file_name    => $FilenameTemplate,
                from_storage => 0,
            );
            return ($status, $msg) unless $status;

            require RT::Shredder;
            my $shredder = new RT::Shredder;
            $shredder->AddDumpPlugin(
                Object => $plugin,
            );
            $shredder->PutObject( Object => $arg{'Object'} );
            $shredder->WipeoutAll;
            return 1;
        },
    },
);

sub PrepareMap {
    my $self = shift || __PACKAGE__;
    my %res = %Default_Map;
    my $user_map = RT->Config->Get('TicketAgingMap');
    if ( $user_map ) {
        $self->_MergeMaps( \%res, $user_map );
    }
    foreach my $age ( $self->Ages ) {
        my ($status, $msg) = $self->_CleanupAge( \%res, $age );
        return (undef, $msg) unless $status;
    }
    return (\%res);
}

sub _MergeMaps {
    my ($self, $default, $overlay) = @_;

    foreach my $age ( keys %$overlay ) {
        next unless $overlay->{ $age };
        unless ( ref $overlay->{ $age } eq 'HASH' ) {
            $RT::Logger->error( "TicketAgingMap -> $age is not a hash reference" );
            next;
        }

        my $cond = $overlay->{ $age }{'Condition'};
        if( $cond && ref $cond ne 'HASH' ) {
            $RT::Logger->error(
                "TicketAgingMap -> $age -> Condition is not a hash reference"
            );
            next;
        }

        foreach my $field ( qw(CallbackPre SQL CallbackPost Filter) ) {
            next unless defined $cond->{ $field };
            unless ( $cond->{$field} ) {
                $RT::Logger->info( "$age -> Condition -> $field is disabled due to TicketAgingMap" );
                delete $default->{ $age }{'Condition'}{ $field };
                next;
            }
            if ( ref $cond->{$field} eq 'CODE' || ( $field eq 'SQL' && !ref $cond->{$field} )) {
                $default->{ $age }{'Condition'}{ $field } = $cond->{$field};
                next;
            }
            $RT::Logger->info( "TicketAgingMap -> $age -> Condition -> $field has incorrect type" );
        }

        if ( defined $overlay->{ $age }{'Action'} ) {
            unless ( $overlay->{ $age }{'Action'} ) {
                $RT::Logger->info( "$age -> Action is disabled due to TicketAgingMap" );
                delete $default->{ $age }{'Action'};
            }
            elsif ( ref $overlay->{ $age }{'Action'} eq 'CODE' ) {
                $default->{ $age }{'Action'} = $overlay->{ $age }{'Action'};
            }
            else {
                $RT::Logger->error( "TicketAgingMap -> $age -> Condition is not a code reference" );
            }
        }
    }
}

sub _CleanupAge {
    my ($self, $map, $age) = @_;

    unless( $map->{ $age } ) {
        delete $map->{ $age };
        return 1;
    }

    my $condition = $map->{ $age }->{'Condition'}
        or return 1;

    if ( my $query = $condition->{'SQL'} ) {
        $condition->{'SQL'} = sub { return "$query" }
            unless ref $query eq 'CODE';
    }
    else {
        delete $condition->{'SQL'};
    }

    foreach my $callback ( qw(CallbackPre Filter CallbackPost) ) {
        next unless my $code_ref = $condition->{$callback};
        unless ( ref $code_ref eq 'CODE' ) {
            return 0, loc "Filter(age [_1]) '[_2]' is not code reference", $age, $callback;
        }
    }
    return 1;
}


our $age_cf_id = 0;
sub GetAgeCustomFieldId {
    return $age_cf_id if $age_cf_id;
    my $cf = RT::CustomField->new( $RT::SystemUser );
    $cf->Load('Age');
    return $age_cf_id = $cf->id;
}

use Hook::LexWrap;
require RT::Tickets;
wrap 'RT::Tickets::_CustomFieldLimit',
    pre => sub {
        return unless lc($_[3]||'') eq 'extinct'; # trigger only extinct value
        return unless ($_[2]||'=') =~ /^(?:=|>=|<=)$/; # deal only when op is positive
        my $field = ({@_[4..($#_-1)]})->{'SUBKEY'} or return;
        $field =~ s/^{?['"]?|['"]?}?$//g; # strip leading/trailing crap
        if ( $field =~ /\D/ ) {
            return unless lc $field eq 'age'; # it's name, but not age
        } else {
            GetAgeCustomFieldId() unless $age_cf_id;
            return unless $age_cf_id == $field;
        }
        $_[0]->{'allow_deleted_search'} = 1;
    };
$RT::Tickets::dispatch{'CUSTOMFIELD'} = \&RT::Tickets::_CustomFieldLimit;

1;

=head1 AUTHOR

Ruslan Zakirov E<lt>ruz@bestpractical.comE<gt>

=cut
