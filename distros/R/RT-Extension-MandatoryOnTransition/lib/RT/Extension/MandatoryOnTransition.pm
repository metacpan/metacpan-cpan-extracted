use strict;
use warnings;
package RT::Extension::MandatoryOnTransition;

our $VERSION = '0.23';

=head1 NAME

RT-Extension-MandatoryOnTransition - Require core fields and ticket custom fields on status transitions

=head1 RT VERSION

Works with RT 4.4, 5.0

RT 4.0 and 4.2 are now end-of-life, so compatibility with
newer versions of this extension is unknown.

Also works with RTIR 5.0.3 and later

=head1 DESCRIPTION

This RT extension enforces that certain fields have values before tickets are
explicitly moved to or from specified statuses.  If you list custom fields
which must have a value before a ticket is resolved, those custom fields will
automatically show up on the "Resolve" page.  The reply/comment won't be
allowed until a value is provided.

See the configuration example under L</INSTALLATION>.

=head2 Supported fields

This extension only enforces mandatory-ness on defined status transitions.
It also supports defining mandatory fields when transitioning a ticket
from one queue to another.

=head3 Basics

Currently the following are supported:

=over 4

=item Content

Requires an update message (reply/comment text) before the transition.

=item TimeWorked

Requires the ticket has a non-zero amount of Time Worked recorded already B<or>
that time worked will be recorded with the current reply/comment in the Worked
field on the update page.

=item TimeTaken

Requires that the Worked field on the update page is non-zero.

=back

A larger set of basic fields may be supported in future releases.  If you'd
like to see additional fields added, please email your request to the bug
address at the bottom of this documentation.

=head3 Custom fields

Ticket custom fields of all types are supported.

=head1 CAVEATS

=head2 Custom field validation (I<Input must match [Mandatory]>)

The custom fields enforced by this extension are validated by the standard RT
rules.  If you've set Validation patterns for your custom fields, those will be
checked before mandatory-ness is checked.  B<< Setting a CFs Validation to
C<(?#Mandatory).> will not magically make it enforced by this extension. >>

=head2 Not all pages where you can change status are supported

SelfService, for example.  See L</TODO> for others.

On 4.0, Basics and Jumbo are not supported because they do not have the
needed code, which is present in 4.2.

=head2 Multiple-entry CFs do not play well with C<must_be> and C<must_not_be>

The C<must_be> and C<must_not_be> configurations are currently not
well-defined for multiply-valued CFs.  At current, only their first
value is validated against the configured whitelist or blacklist.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt5/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::MandatoryOnTransition');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::MandatoryOnTransition));

or add C<RT::Extension::MandatoryOnTransition> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt5/var/mason_data/obj

=item Restart your webserver

=back

If running with RTIR, the C<Plugin> line for RTIR must come first in your
configuration as shown below.

    Plugin('RT::IR');
    Plugin('RT::Extension::MandatoryOnTransition');

=head1 CONFIGURATION

To define which fields should be mandatory on certain status changes
(either globally or in a specific queue) use the C<%MandatoryOnTransition>
config option.  This option takes the generic form of:

    Set( %MandatoryOnTransition,
        'QueueName' => {
            'from -> to' => [ 'BasicField', 'CF.MyField', 'CustomRole.MyRole' ],
        },
    );

C<from> and C<to> are expected to be valid status names.  C<from> may also be
C<*> which will apply to any status and also tickets about to be created with
status C<to>. If you need to express rules that apply only on ticket creation
and not on updates, you can use the special C<from> value of C<'__CREATE__'>.
For example,

    Set( %MandatoryOnTransition,
        'MyQueue' => {
            '__CREATE__ -> open' => [ 'CF.MyField1' ],
            '* -> open' => [ 'CF.MyField2', 'CF.MyField3' ],
        },
    );

would require C<CF.MyField1> on ticket creation and C<CF.MyField2> and
C<CF.MyField3> on any other transition to C<open>.

The fallback for queues without specific rules is specified with C<'*'> where
the queue name would normally be.

=head2 Requiring Any Value

Below is an example which requires 1) time worked and filling in a custom field
named Resolution before resolving tickets in the Helpdesk queue and 2) a
Category selection before resolving tickets in every other queue.

    Set( %MandatoryOnTransition,
        Helpdesk => {
            '* -> resolved'      => ['TimeWorked', 'CF.Resolution', 'CustomRole.Analyst'],
        },
        '*' => {
            '* -> resolved' => ['CF.Category'],
        },
    );

The transition syntax is similar to that found in RT's Lifecycles.  See
C<perldoc /opt/rt5/etc/RT_Config.pm>.

=head2 Requiring role values

You can require any core or custom role on a RT::Ticket object, below is an
example of requiring a custom role "customer" be set on transition from open
and the owner also be set for the ticket on transition from a status of open.

    Set( %MandatoryOnTransition,
        'General' => {
            '* -> resolved' => ['CustomRole.customer', 'Owner'],
        },
    );

=head2 Role Membership in a Group

Roles can require the members of the role to also be a member of a group
before satisfying to mandatory condition. Below we require that the Owner
role be set and that the member it is set to is a member of the group
'SupportReps' or 'Admins'.

    Set( %MandatoryOnTransition,
        'General' => {
            'open -> *' => ['Owner'],
            'Owner' => { transition => 'open -> *', group => ['SupportReps', 'Admins'] },
        }
    );

=head2 Restrictions on Queue Transitions

The default behavior for C<MandatoryOnTransition> operates on status transitions,
so a change from C<new> to C<open> or from C<open> to C<resolved>. It also supports
making fields mandatory when transitioning from one queue to another. To define
fields that are required when changing the queue for a ticket, add an entry to
the configuration like this:

    Set( %MandatoryOnTransition,
        Helpdesk => {
            'Engineering' => ['CF.Category'],
        },
    );

The key is the destination queue and the values are the mandatory fields. In this
case, before a user can move a ticket from the Helpdesk queue to the
Engineering queue, they must provide a value for Category, possibly something like
"bug" or "feature request".

Note that this configuration makes the most sense if the custom fields are applied
to both queues. Otherwise the users on the destination queue won't be able to see
the required values.

=head2 Requiring or Restricting Specific Values

Sometimes you want to restrict a transition if a field has a specific
value (maybe a ticket can't be resolved if System Status = down) or
require a specific value to to allow a transition (ticket can't be
resolved unless a problem was fixed). To enforce specific values, you
can add the following:

    Set( %MandatoryOnTransition,
        Helpdesk => {
            '* -> resolved' => ['TimeWorked', 'CF.Resolution', 'CF.System Status'],
            'CF.Resolution' => { transition => '* -> resolved', must_be => ['fixed', 'not an issue'] },
            'CF.System Status' => { transition => '* -> resolved', must_not_be => ['reduced', 'down']}
        },
    );

This will then enforce both that the value is set and that it either has
one of the required values on the configured transition or does
not have one of the restricted values.

Note that you need to specify the transition the rule applies to
since a given queue configuration could have multiple transition rules.

=head2 C<$ShowAllCustomFieldsOnMandatoryUpdate>

By default, this extension shows only the mandatory fields on the update page
to make it easy for users to fill them out when completing an action. If you
would like to show all custom fields rather than just the mandatory ones,
use this configuration option. You can set it like this:

    Set($ShowAllCustomFieldsOnMandatoryUpdate, 1);

=head1 IMPLEMENTATION DETAILS

If you're just using this module on your own RT instance, you should stop
reading now.  You don't need to know about the implementation details unless
you're writing a patch against this extension.

=head2 Package variables

=over 4

=item @CORE_SUPPORTED

The core (basic) fields supported by the extension.  Anything else configured
but not in this list is stripped.

=item @CORE_TICKET

The core (basic) fields which should be called as methods on ticket objects to
check for current values.

=item %CORE_FOR_UPDATE

A mapping which translates core fields into their form input names.  For
example, Content is submitted as UpdateContent.  All fields must be mapped,
even if they are named exactly as listed in @CORE_SUPPORTED.  A supported
field which doesn't appear in the mapping is skipped, the implication being
that it isn't available during update.

If your core field is called different things on Update.html and Modify.html
you will need to modify the Modify.html/Default callback so the the
extension knows what field to use.  Look at TimeWorked vs UpdateTimeWorked
for an example.

=item %CORE_FOR_CREATE

A mapping similar to %CORE_FOR_UPDATE but consulted during ticket creation.
The same rules and restrictions apply.

=back

If you're looking to add support for other core fields, you'll need to push
into @CORE_SUPPORTED and possibly @CORE_TICKET.  You'll also need to add a
pair to %CORE_FOR_UPDATE and/or %CORE_FOR_CREATE.

=cut

our @CORE_SUPPORTED  = qw(Content TimeWorked TimeTaken);
our @CORE_TICKET     = qw(TimeWorked);
our %CORE_FOR_UPDATE = (
    TimeWorked  => 'UpdateTimeWorked',
    TimeTaken   => 'UpdateTimeWorked',
    Content     => 'UpdateContent',
);
our %CORE_FOR_CREATE = (
    TimeWorked  => 'TimeWorked',
    Content     => 'Content',
);

=head2 Methods

=head3 RequiredFields

Returns three array refs of required fields for the described status transition.
The first is core fields, the second is CF names, the third is roles.  Returns
empty array refs on error or if nothing is required.

A fourth returned parameter is a hashref of must-have values for custom fields.

The fifth parameter is a hashref of groups a role member must be in.

Takes a paramhash with the keys Ticket, Queue, From, and To.  Ticket should be
an object.  Queue should be a name.  From and To should be statuses.  If you
specify Ticket, only To is otherwise necessary.  If you omit Ticket, From, To,
and Queue are all necessary.

The first transition found in the order below is used:

    from -> to
    *    -> to
    from -> *

=cut

sub RequiredFields {
    my $self  = shift;
    my %args  = (
        Ticket  => undef,
        Queue   => undef,
        From    => undef,
        To      => undef,
        NewQueue => undef,
        ToQueue => undef,
        @_,
    );

    if ($args{Ticket}) {
        $args{Queue} ||= $args{Ticket}->QueueObj->__Value('Name');
        $args{From}  ||= $args{Ticket}->Status;
    }
    my ($from, $to) = @args{qw(From To)};

    if ($args{NewQueue}) {
        my $queue = RT::Queue->new(RT->SystemUser);
        $queue->Load($args{NewQueue});
        $args{ToQueue} = $queue->Name;
    }

    my ($from_queue, $to_queue) = ($args{Queue}, $args{ToQueue} || $args{Queue});

    return ([], [], []) unless ($from and $to and $from ne $to) or ($from_queue and $to_queue and $from_queue ne $to_queue);

    my %config = ();
    %config = $self->Config($args{Queue});

    return ([], [], []) unless %config;

   $to ||= '';
   $from ||= '';
   $to_queue ||= '*';

    my $required = $config{"$from -> $to"}
                || $config{"* -> $to"}
                || $config{"$from -> *"}
		|| $config{$to_queue}
                || [];

    my %core_supported = map { $_ => 1 } @CORE_SUPPORTED;

    my @core = grep { !/^CF\./i && $core_supported{$_} } @$required;
    my @cfs  =  map { /^CF\.(.+)$/i; $1; }
               grep { /^CF\./i } @$required;
    my @roles = map { /^(:?[CustomRole\.]?.+)$/i; $1; }
               grep { /^CustomRole\.|^AdminCc|^Cc|^Requestor|^Owner/i } @$required;

    # Pull out any must_be or must_not_be rules
    my %cf_must_values = ();
    foreach my $cf (@cfs){
        if ( $config{"CF.$cf"} ){
            my $transition = $config{"CF.$cf"}->{'transition'};
            unless ( $transition ){
                RT->Logger->error("No transition defined in must_be or must_not_be rules for $cf");
                next;
            }

            if ( $transition eq "$from -> $to"
                 || $transition eq "* -> $to"
                 || $transition eq "$from -> *" ) {

                $cf_must_values{$cf} = $config{"CF.$cf"};
            }
        }
    }

    my %role_group_values;
    my $queue_id;
    if ( $args{Ticket} ) {
        $queue_id = $args{Ticket}->Queue;
    }
    else {
        my $queue = RT::Queue->new( RT->SystemUser );
        $queue->Load($args{Queue});
        $queue_id = $queue->id;
    }

    foreach my $role (@roles){
        if ( $role =~ /^CustomRole\.(.*)/i ) {
            my $cr = RT::CustomRole->new(RT->SystemUser);
            my $role_name = $1;
            my ($ret, $msg) = $cr->Load($role_name);
            if ( not $cr and $cr->Id ) {
                RT::Logger->error("Could not load Custom role $role_name: $msg");
                @roles = grep { $_ ne $role } @roles;
                next;
            } elsif ( not $cr->IsAdded($queue_id) or $cr->Disabled ) {
                RT::Logger->error("Custom role $role_name is not applied to: " . $args{Ticket}->QueueObj->Name );
                @roles = grep { $_ ne $role } @roles;
                next;
            }
        }
        if ( $config{$role} ){
            my $transition = $config{$role}->{'transition'};
            unless ( $transition ){
                RT->Logger->error("No transition defined in group rules for $role");
                next;
            }

            if ( $transition eq "$from -> $to"
                || $transition eq "* -> $to"
                || $transition eq "$from -> *" ) {

                $role_group_values{$role} = $config{$role};
            }
        }
    }
    return (\@core, \@cfs, \@roles, \%cf_must_values, \%role_group_values);
}

=head3 CheckMandatoryFields

Pulls core and custom mandatory fields from the configuration and
checks that they have a value set before transitioning to the
requested status.

Accepts a paramhash of values:
    ARGSRef => Reference to Mason ARGS
    Ticket => ticket object being updated
    Queue  => Queue object for the queue in which a new ticket is being created
    From   => Ticket status transitioning from
    To     => Ticket status transitioning to

Works for both create, where no ticket exists yet, and update on an
existing ticket. ARGSRef is required for both.

For create, you must also pass Queue, From, and To. In this case, the
From status should be the special flag value of '__CREATE__'.

Update requires only Ticket and To since From can be fetched from the
ticket object.

=cut

sub CheckMandatoryFields {
    my $self = shift;
    my %args  = (
        Ticket  => undef,
        Queue   => undef,
        From    => undef,
        To      => undef,
        @_,
    );
    my $ARGSRef = $args{'ARGSRef'};
    my @errors;

    # Labels for error messages
    my %field_label;
    $field_label{'Status'} = $ARGSRef->{'Status'};

    if ( $ARGSRef->{'Queue'} ){
        # Provide queue name instead of id for errors and retain
        # status handling.
        my $dest_queue_obj = RT::Queue->new(RT->SystemUser);
        my ($ret, $msg) = $dest_queue_obj->Load($ARGSRef->{'Queue'});
        RT::Logger->error("Unable to load queue for id " . $ARGSRef->{'Queue'} . " $msg")
            unless $ret;
        $field_label{'Queue'} = $dest_queue_obj->Name;
    }

    # Some convenience variables set depending on what gets passed
    my ($CFs, $CurrentUser);
    if ( $args{'Ticket'} ){
        $CFs = $args{'Ticket'}->CustomFields;
        $CurrentUser = $args{'Ticket'}->CurrentUser();
    }
    elsif ( $args{'Queue'} ){
        $CFs = $args{'Queue'}->TicketCustomFields;
        $CurrentUser = $args{'Queue'}->CurrentUser();
    }
    else{
        $RT::Logger->error("CheckMandatoryFields requires a Ticket object or a Queue object");
        return \@errors;
    }

    my ($core, $cfs, $roles, $must_values, $role_group_values) = $self->RequiredFields(
        Ticket  => $args{'Ticket'},
        Queue   => $args{'Queue'} ? $args{'Queue'}->Name : undef,
        From    => $args{'From'},
        To      => $args{'To'},
        NewQueue => $$ARGSRef{'Queue'},
    );
    return \@errors unless @$core or @$cfs or @$roles;

    my $transition =  ($args{'From'} ||'') ne ($args{'To'} || '') ? 'Status' : 'Queue';

    # If we were called from Modify.html (Basics) or ModifyAll.html
    # (Jumbo), where the SubmitTicket button goes by 'Save Changes',
    # then set the form field name for Time Worked to 'TimeWorked' in
    # our local copy of %CORE_FOR_UPDATE
    my %CORE_FOR_UPDATE_COPY = %CORE_FOR_UPDATE;
    if ( exists $ARGSRef->{'SubmitTicket'} && $ARGSRef->{'SubmitTicket'} eq 'Save Changes' ) {
        $CORE_FOR_UPDATE_COPY{'TimeWorked'} = 'TimeWorked';
        $CORE_FOR_UPDATE_COPY{'TimeTaken'} = 'TimeWorked';
    }

    # Check core fields, after canonicalization for update
    for my $field (@$core) {

        # Will we have a value on update/create?
        my $arg = $args{'Ticket'}
            ? $CORE_FOR_UPDATE_COPY{$field}
            : $CORE_FOR_CREATE{$field};
        next unless $arg;

        # Process Content the same way it will be processed by RT on update
        # Which means cleaning out any possible signature
        if ( $field eq 'Content' && defined $ARGSRef->{$arg} && length $ARGSRef->{$arg} ) {

            # Create = ContentType, Update = UpdateContentType,
            # So use $arg to find the ARG for ContentType
            my $content_type_arg = $arg . 'Type';
            my $sig_removed = RT::Interface::Web::StripContent(
                Content        => $ARGSRef->{$arg},
                ContentType    => $ARGSRef->{$content_type_arg},
                StripSignature => $ARGSRef->{SkipSignatureOnly} || 1,
                CurrentUser    => $CurrentUser,
            );
            next if defined $sig_removed and length $sig_removed;
        }
        else {
            next if defined $ARGSRef->{$arg} and length $ARGSRef->{$arg};
        }

        # Do we have a value currently?
        # In Create the ticket hasn't been created yet.
        next if grep { $_ eq $field } @CORE_TICKET
          and ($args{'Ticket'} && $args{'Ticket'}->$field());

        (my $label = $field) =~ s/(?<=[a-z])(?=[A-Z])/ /g; # /
        push @errors,
          $CurrentUser->loc("[_1] is required when changing [_2] to [_3]",
            $label, $CurrentUser->loc($transition),  $CurrentUser->loc($field_label{$transition}));
    }

    if (@$roles and $args{'To'}) {
        foreach my $role (@$roles) {
            my $role_values;
            my $role_arg = $role;
            my $role_name = $role;

            my $role_object;
            my @role_values;

            my $value;

            if ( $role =~ /^CustomRole\.(.+)/ ) {
                $role_name = $1;
                $role_object = RT::CustomRole->new( $CurrentUser );

                my ( $ret, $msg ) = $role_object->Load($role_name);
                push @errors, $CurrentUser->loc("Could not load object for [_1]", $role_name) unless $ret;
                unless ( $ret ) {
                    RT::Logger->error("Unable to load custom role $role_name: $msg");
                    next;
                }

                $role_arg = $role_object->GroupType;

                # No need to load current value for single-member custom roles
                # as new passed value will override current one
                if ( !$role_object->SingleValue && $args{Ticket} ) {

                    $role_arg = "Add$role_arg";
                    $role_values = $args{Ticket}->RoleGroup( $role_object->GroupType );
                    if ( $role_values ) {
                        push @role_values, grep { $_->id != $RT::Nobody->id } @{ $role_values->UserMembersObj->ItemsArrayRef };
                    }
                    else {
                        RT::Logger->error( "Unable to load role group for " . $role_object->GroupType );
                    }
                }
            }
            else {
                if ( $role eq 'Owner' ) {

                    # There are 2 Owner fields on Jumbo page, copied the same handling from it.
                    if ( ref $ARGSRef->{$role} ) {
                        foreach my $owner ( @{ $ARGSRef->{$role} } ) {
                            if ( defined($owner) && $owner =~ /\D/ ) {
                                $value = $owner unless ( $args{'Ticket'}->OwnerObj->Name eq $owner );
                            }
                            elsif ( length $owner ) {
                                $value = $owner unless ( $args{'Ticket'}->OwnerObj->id == $owner );
                            }
                        }
                    }
                    else {
                        $value = $ARGSRef->{$role};
                    }
                }
                else {
                    $role_arg = "Add$role";
                }

                if ( $args{Ticket} ) {
                    $role_values = RT::Group->new( $args{Ticket}->CurrentUser );
                    my ( $ret, $msg ) = $role_values->LoadRoleGroup(
                        Object => $args{Ticket},
                        Name   => $role,
                    );
                    if ($ret) {
                        push @role_values,
                          grep { $_->id != $RT::Nobody->id } @{ $role_values->UserMembersObj->ItemsArrayRef };
                    }
                    else {
                        push @errors, $CurrentUser->loc("Failed to load role $role for ticket");
                    }
                }
            }

            $value = $ARGSRef->{$role_arg} unless $role eq 'Owner';

            if ($value) {

                my $user = RT::User->new( RT->SystemUser );
                $user->Load($value);
                $user->LoadByEmail($value) unless $user->id;

                if ( $user->id ) {
                    if ( $role eq 'Owner' || ( $role_object && $role_object->SingleValue ) ) {
                        if ( $user->id == $RT::Nobody->id ) {
                            undef @role_values if @role_values;
                        }
                        else {
                            @role_values = $user;
                        }
                    }
                    else {
                        push @role_values, $user unless $user->id == $RT::Nobody->id;
                    }
                }
                else {
                    # RT can automatically create users with email addresses.
                    if ( $value =~ /@/ ) {
                        push @role_values, $value;
                    }
                    else {
                        push @errors, $CurrentUser->loc( "Could not load user: [_1]", $value );
                    }
                }
            }
            else {
                if ( $role_object && $role_object->SingleValue ) {
                    undef @role_values if @role_values;
                }
                delete $ARGSRef->{$role_arg};
            }

            # Handle multi-members roles on Jumbo page
            my @values;

            if ( $role =~ /^(AdminCc|Cc|Requestors)$/i || ( $role_object && !$role_object->SingleValue ) ) {
                my $type = $role_object ? $role_object->GroupType : $role;

                for my $arg ( keys %$ARGSRef ) {
                    if ( $arg =~ /^WatcherTypeEmail(\d+)/ ) {
                        my $num = $1;
                        next unless $ARGSRef->{$arg} eq $type;
                        my $address = $ARGSRef->{ 'WatcherAddressEmail' . $num };
                        next unless $address;

                        push @values, $address;
                    }
                    elsif ( $arg =~ /^Ticket-DeleteWatcher-Type-$type-Principal-(\d+)$/ ) {
                        my $del_id = $1;
                        @role_values = grep { ref $_ ? $_->id != $del_id : $_ } @role_values;
                    }
                }
            }

            for my $value (@values) {
                my $user = RT::User->new( RT->SystemUser );
                $user->Load($value);
                $user->LoadByEmail($value) unless $user->id;

                if ( $user->id ) {
                    push @role_values, $user unless $user->id == $RT::Nobody->id;
                }
                else {
                    # RT can automatically create users with email addresses.
                    if ( $value =~ /@/ ) {
                        push @role_values, $value;
                    }
                    else {
                        push @errors, $CurrentUser->loc( "Could not load user: [_1]", $value );
                    }
                }
            }

            # Handle multi-members roles on Create page
            if ( $role =~ /^(AdminCc|Cc|Requestors)$/i || ( $role_object && !$role_object->SingleValue ) ) {
                my $type = $role_object ? $role_object->GroupType : $role;

                if ( $ARGSRef->{$role} ) {
                    for my $value ( RT::EmailParser->ParseEmailAddress( $ARGSRef->{$role} ) ) {
                        my $user = RT::User->new( RT->SystemUser );
                        $user->LoadByEmail($value);

                        if ( $user->id ) {
                            push @role_values, $user unless $user->id == $RT::Nobody->id;
                        }
                        else {
                            # RT can automatically create users with email addresses.
                            if ( $value =~ /@/ ) {
                                push @role_values, $value;
                            }
                            else {
                                push @errors, $CurrentUser->loc( "Could not load user: [_1]", $value );
                            }
                        }
                    }
                }
            }


            # Check for mandatory group configuration, supports multiple groups where only
            # one true case needs to be found.
            if ( $role_group_values->{$role}->{group} ) {
                my $has_valid_member;

                foreach my $group_name ( @{ $role_group_values->{$role}->{group} } ) {
                    my $group = RT::Group->new( RT->SystemUser );

                    my ( $ret, $msg ) = $group->LoadUserDefinedGroup($group_name);
                    unless ( $ret ) {
                        RT::Logger->error("Failed to load group: $group_name : $msg");
                        next;
                    }

                    foreach my $member (@role_values) {
                        next unless ref $member; # Only check users alrady exist

                        $has_valid_member = $group->HasMemberRecursively( $member->Id );
                        last if $has_valid_member;
                    }
                    last if $has_valid_member;
                }

                unless ( $has_valid_member ) {
                    my $roles = join( ' or ', @{ $role_group_values->{$role}->{group} } );
                    push @errors,
                        $CurrentUser->loc( "A member of group [_1] is required for role: [_2]", $roles, $role_name );
                    next;
                }
            }


            if ( not scalar @role_values ) {
                push @errors, $CurrentUser->loc("[_1] is required when changing [_2] to [_3]",
                    $role_name,
                    $CurrentUser->loc($transition),
                    $CurrentUser->loc( $args{'To'} )
                );
                next;
            }
        }
    }

    return \@errors unless @$cfs;

    if ( not $CFs ){
        $RT::Logger->error("Custom Fields object required to process mandatory custom fields");
        return \@errors;
    }

    $CFs->Limit( FIELD => 'Name', VALUE => $_, SUBCLAUSE => 'names',
        ENTRYAGGREGRATOR => 'OR', CASESENSITIVE => 0 )
      for @$cfs;

    # For constructing NamePrefix for both update and create
    my $TicketId = $args{'Ticket'} ? $args{'Ticket'}->Id : '';

    # Validate them
    my $ValidCFs = $HTML::Mason::Commands::m->comp(
                            '/Elements/ValidateCustomFields',
                            CustomFields => $CFs,
                            NamePrefix => "Object-RT::Ticket-".$TicketId."-CustomField-",
                            ARGSRef => $ARGSRef
                           );

    # Check validation results and mandatory-ness
    while (my $cf = $CFs->Next) {
        # Is there a validation error?
        if ( not $ValidCFs
             and my $msg = $HTML::Mason::Commands::m->notes('InvalidField-' . $cf->Id)) {
            push @errors, $CurrentUser->loc($cf->Name) . ': ' . $msg;
            next;
        }

        # Do we have a submitted value for update?
        my $value;
        if ( HTML::Mason::Commands->can('_ParseObjectCustomFieldArgs') ) {
            # steal code from /Elements/ValidateCustomFields
            my $CFArgs = HTML::Mason::Commands::_ParseObjectCustomFieldArgs( $ARGSRef )->{'RT::Ticket'}{$TicketId || 0} || {};
            my $submitted = $CFArgs->{$cf->id};
            # Pick the first grouping
            $submitted = $submitted ? $submitted->{(sort keys %$submitted)[0]} : {};

            my @values;
            for my $argtype (qw/Values Value Upload/) {
                next if @values;
                @values = HTML::Mason::Commands::_NormalizeObjectCustomFieldValue(
                    CustomField => $cf,
                    Param => "Object-RT::Ticket-".$TicketId."-CustomField-".$cf->Id."-".$argtype,
                    Value => $submitted->{$argtype},
                );
            }
            # TODO: Understand multi-value CFs
            ($value) = @values;
        }
        else {
            my $arg;
            if ( $cf->Type =~ m/^(Binary|Image)$/ ) {
                $arg   = "Object-RT::Ticket-".$TicketId."-CustomField-".$cf->Id."-Upload";
            } else {
                $arg   = "Object-RT::Ticket-".$TicketId."-CustomField-".$cf->Id."-Value";
            }
            $value = ($ARGSRef->{"${arg}s-Magic"} and exists $ARGSRef->{"${arg}s"}) ? $ARGSRef->{$arg . "s"} : $ARGSRef->{$arg};
            ($value) = grep length, map {
                s/\r+\n/\n/g;
                s/^\s+//;
                s/\s+$//;
                $_;
                }
                grep defined, $value;
        }

        if ( $cf->can('CustomFieldValueIsEmpty') && $cf->CustomFieldValueIsEmpty( Field => $cf, Value => $value ) ) {
            undef $value;
        }

        # Check for specific values
        if ( exists $must_values->{$cf->Name} ){
            my $cf_value = $value;

            if ( not defined $cf_value and $args{'Ticket'} ){
                # Fetch the current value if we didn't receive a new one
                # TODO: Understand multi-value CFs
                $cf_value = $args{'Ticket'}->FirstCustomFieldValue($cf->Name);
            }

            if ( exists $must_values->{$cf->Name}{'must_be'} ){
                my @must_be = @{$must_values->{$cf->Name}{'must_be'}};

                # OK if it's defined and is one of the specified values
                next if defined $cf_value and grep { $cf_value eq $_ } @must_be;
                my $valid_values = join ", ", @must_be;
                if ( @must_be > 1 ){
                    push @errors,
                        $CurrentUser->loc("[_1] must be one of: [_4] when changing [_2] to [_3]",
                        $cf->Name, $CurrentUser->loc($transition), $CurrentUser->loc($field_label{$transition}), $valid_values);
                }
                else{
                    push @errors,
                        $CurrentUser->loc("[_1] must be [_4] when changing [_2] to [_3]",
                        $cf->Name, $CurrentUser->loc($transition),  $CurrentUser->loc($field_label{$transition}), $valid_values);
                }
                next;
            }

            if ( exists $must_values->{$cf->Name}{'must_not_be'} ){
                my @must_not_be = @{$must_values->{$cf->Name}{'must_not_be'}};

                # OK if it's defined and _not_ in the list
                next if defined $cf_value and !grep { $cf_value eq $_ } @must_not_be;
                my $valid_values = join ", ", @must_not_be;
                if ( @must_not_be > 1 ){
                    push @errors,
                        $CurrentUser->loc("[_1] must not be one of: [_4] when changing [_2] to [_3]",
                        $cf->Name, $CurrentUser->loc($transition), $CurrentUser->loc($field_label{$transition}), $valid_values);
                }
                else{
                    push @errors,
                        $CurrentUser->loc("[_1] must not be [_4] when changing [_2] to [_3]",
                        $cf->Name, $CurrentUser->loc($transition),$CurrentUser->loc($field_label{$transition}), $valid_values);
                }
                next;
            }
        }

        # Check for any value
        next if defined $value and length $value;

        # Is there a current value?  (Particularly important for Date/Datetime CFs
        # since they don't submit a value on update.)
        next if $args{'Ticket'} && $cf->ValuesForObject($args{'Ticket'})->Count;

        push @errors,
          $CurrentUser->loc("[_1] is required when changing [_2] to [_3]",
                                     $cf->Name, $CurrentUser->loc($transition), $CurrentUser->loc($field_label{$transition}));
    }

    return \@errors;
}

=head3 Config

Takes a queue name.  Returns a hashref for the given queue (possibly using the
fallback rules) which contains keys of transitions and values of arrayrefs of
fields.

You shouldn't need to use this directly.

=cut

sub Config {
    my $self  = shift;
    my $queue = shift || '*';
    my %config = RT->Config->Get('MandatoryOnTransition');
    return %{$config{$queue}} if $config{$queue};
    return %{$config{'*'}} if $config{'*'};
    return;
}

=head1 TODO

=over 4

=item Enforcement on Create

    index.html / QuickCreate    - Not yet implemented.
    SelfService                 - Not yet implemented.

=item Enforcement on other update pages

    SelfService - can't do it without patches to <form> POST + additional callbacks

=item Full Validation of Configuration

    Check that all CFs are actually CFs applied to the indicated queues (or global). Also
    validate additional CF's with "must" configuration are defined in a transition.

=item Allow empty values in "must" configuration

    When defining a list of "must be" or "must not be" values, there may be use cases where
    an empty value could be valid. Provide a way to specify and allow this.

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-MandatoryOnTransition@rt.cpan.org|mailto:bug-RT-Extension-MandatoryOnTransition@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-MandatoryOnTransition>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2012-2023 by Best Pracical Solutions, LLC.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
