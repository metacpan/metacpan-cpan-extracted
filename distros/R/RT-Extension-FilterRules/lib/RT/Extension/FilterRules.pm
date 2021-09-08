use strict;
use warnings;

package RT::Extension::FilterRules;

our $VERSION = '0.01';

our @ConditionProviders = ();
our @ActionProviders    = ();

=head1 NAME

RT::Extension::FilterRules - Filter incoming tickets through rule sets

=head1 DESCRIPTION

This extension provides a way for non-technical users to set up ticket
filtering rules which perform actions on tickets when they arrive in a
queue.

Filter rules are grouped into filter rule groups.  The RT administrator
defines the criteria a ticket must meet to be processed by each filter rule
group, and defines which RT groups can manage the filter rules in each rule
group.

For each applicable filter rule group, the rules are checked in order, and
any actions for matching rules are performed on the ticket.  If a matching
rule says that processing must then stop, processing of the rules in that
filter rule group will end, and the next rule group will then be considered.

Filter rules are managed under I<Tools> - I<Filter rules>.

=head1 REQUIREMENTS

Requires C<Email::Address> and C<HTML::FormatText>.

=head1 RT VERSION

Known to work with RT 4.2.16, 4.4.4, and 5.0.1.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions.

=item B<Set up the database>

After running C<make install> for the first time, you will need to create
the database tables for this extension.  Use C<etc/schema-mysql.sql> for
MySQL or MariaDB, or C<etc/schema-postgresql.sql> for PostgreSQL.

=item B<Edit your> F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::FilterRules');

=item B<Clear your Mason cache>

    rm -rf /opt/rt4/var/mason_data/obj

=item B<Restart your web server>

=item B<Add the processing scrip>

Create a new global scrip under I<Admin> - I<Global> - I<Scrips>:

=over 14

=item Description:

Filter rule processing

=item Condition:

User Defined

=item Action:

User Defined

=item Template:

Blank

=item Stage:

Normal

=item Custom condition:

 return 0 if (not $RT::Extension::FilterRules::VERSION);
 return RT::Extension::FilterRules->ScripIsApplicable($self);

=item Custom action preparation code:

 return 0 if (not $RT::Extension::FilterRules::VERSION);
 return RT::Extension::FilterRules->ScripPrepare($self);

=item Custom action commit code:

 return 0 if (not $RT::Extension::FilterRules::VERSION);
 return RT::Extension::FilterRules->ScripCommit($self);

=back

No filter rules will actually perform any actions until this scrip is
created and enabled.

Note that the C<return 0> lines are only there to prevent errors if you
later remove this extension without disabling the scrip.

=item B<Set up some filter rule groups>

Rule groups are set up by the RT administrator under I<Admin> - I<Filter
rule groups>.

=back

=head1 TUTORIAL

For the purposes of this tutorial, we assume that you have these queues:

=over

=item *

B<"General"> - for general queries;

=item *

B<"Technical"> - for more technical matters to be escalated to.

=back

We also assume that you have these user-defined groups set up:

=over

=item *

B<"Service desk"> - containing all first-line analysts;

=item *

B<"Service desk management"> - containing the leadership team for the service desk;

=item *

B<"Third line"> - containing all technical teams.

=back

These are only examples for illustration, there is no need for your system
to be set up this way to use it with this extension.

=head2 Create a new filter rule group

=over

=item 1.

As a superuser, go to I<Admin> - I<Filter rule groups> - I<Create>.

=item 2.

Provide a name for the new filter rule group, such as
I<"General inbound message filtering">, and click on the B<Create> button.

=item 3.

Now that the filter rule group has been created, you can define the queues
and groups it can use.

Next to I<Queues to allow in match rules>, select your I<General> queue and
click on the B<Add queue> button.

=item 4.

You will see the I<General> queue is now listed next to I<Queues to allow in
match rules>.  If you select it and click on the B<Save Changes> button, the
queue will be removed from the list.

If you tried that, add it back again before the next step.

=item 5.

Rules in this filter rule group need to be able to transfer tickets into the
I<Technical> queue, so next to I<Queues to allow as transfer destinations>,
select your I<Technical> queue and click on the B<Add queue> button.

=item 6.

Add the I<Service desk> and I<Third line> groups to
I<Groups to allow in rule actions> to be able to use them in filter rules,
such as sending notifications to members of those groups.

=back

After saving your changes, go back to I<Admin> - I<Filter rule groups>, and
you will see your new filter rule group and its settings.

Once you have more than one, you can move them up and down in the list to
control the order in which they are processed, using the I<Up> and I<Down>
links at the right.

=head2 Set the requirements for the filter rule group

A filter rule group will not process any messages unless its requirements
are met.  Each one starts off with no requirements, so will remain inactive
until you define some.

From I<Admin> - I<Filter rule groups>, click on your new filter rule group,
and then choose I<Requirements> from the page menu at the top.

Click on the B<Create new requirement rule> button to create a new
requirement rule for that filter rule group.

=over

=item 1.

Give the requirement rule a name, such as I<"Created in the General queue">.

=item 2.

Set the trigger type.  This rule will be processed when an event of this
type occurs, and skipped over otherwise.  The available trigger types are
I<"On ticket creation"> and I<"When a ticket moves between queues">; for
this example, select I<"On ticket creation">.

=item 3.

Choose the conflict conditions.  If I<any> of these conditions are met, the
rule will I<not> match.  For this example, leave this empty.

=item 4.

Choose the requirement conditions.  I<All> of these conditions must be met
for the rule to match.  Click on the B<Add condition> button, choose
I<"In queue">, and select the I<"General"> queue.

For each condition, although all of the conditions must be met, you can
specify multiple values for each condition using the B<Add value> button for
that condition.  This means that the condition will be met if any one of its
values matches.

=item 5.

Click on the B<Create> button to create the new requirement rule.

=back

In the list of requirement rules, click on a rule's number or name to edit
it.

Add as many requirement rules as you need.  They can be switched off
temporarily by marking them as disabled.

=head2 Delegate control of the filter rule group

In this example, the new filter rule group you created above, called
I<General inbound message filtering>, is going to be managed by the
service desk management team.  This means that you want them to be able to
create, update, and delete filter rules within that group with no
assistance.

We will also allow the service desk team to view the filter rules, so that
they have visibility of what automated processing is being applied to
tickets they are receiving.

=over

=item 1.

From I<Admin> - I<Filter rule groups>, click on your new filter rule group,
and then choose I<Group Rights> from the page menu at the top.

=item 2.

In the text box under I<ADD GROUP> at the bottom left, type
I<"Service desk management"> but do not hit Enter.

=item 3.

On the right side of the screen, under I<Rights for Staff>, select all of
the rights so that the management team can fully control the filter rules in
this filter rule group.

=item 4.

Click on the B<Save Changes> button at the bottom right to grant these
rights.

=item 5.

In the text box under I<ADD GROUP> at the bottom left, type
I<"Service desk"> but do not hit Enter.

=item 6.

On the right side of the screen, under I<Rights for Staff>, select only the
I<View filter rules> right, so that the service desk analysts can only view
these filter rules, not edit them.

=item 7.

Click on the B<Save Changes> button at the bottom right to grant these
rights.

=back

Members of the I<Service desk management> group will now be able to manage
the filter rules of the I<General inbound message filtering> filter rule
group, under the I<Tools> - I<Filter rules> menu.

Members of the I<Service desk> group will be able to see those rules there
too, but will not be able to modify them.

=head2 Creating filter rules

RT super users can edit filter rules by starting from I<Admin> - I<Filter
rule groups> - I<Select>, choosing a filter rule group, and then choosing
I<Filters> from the page menu at the top.

Members of the groups you delegated access to in the steps above can edit
the filter rules by going to I<Tools> - I<Filter rules>.  If they have
access to more than one filter rule group, they can then choose which one's
rules to edit from the list provided.

Click on the B<Create new filter rule> button to create a new filter rule.

=over

=item 1.

Give the filter rule a name, such as
I<"Escalate desktop wallpaper requests">.

=item 2.

Set the trigger type, as with the requirement rule above.  For this example,
select I<"On ticket creation">.

=item 3.

Choose the conflict conditions, as with the requirement rule above.  For
this example, click on the B<Add condition> button, choose I<"Subject or
message body contains">, and type C<paste> into the box next to it.

=item 4.

Choose the requirement conditions, as with the requirement rule above.  For
this example:

=over

=item *

Click on the B<Add condition> button, choose a I<"In queue">, and select the
I<"General"> queue.

=item *

Click on the B<Add condition> button again, choose  I<"Subject or
message body contains">, and type C<wallpaper> into the box next to it.

=item *

Click on the B<Add value> button underneath the box containing C<wallpaper>
and type C<background> into the box that appears.

=item *

Click on the B<Add condition> button again, choose  I<"Subject or
message body contains">, and type C<desktop> into the box next to it.

=back 

=item 5.

Choose the actions to perform when this rule is matched.  For this example,
click on the B<Add action> button, choose I<"Move to queue">, and select the
I<"Technical"> queue.

=item 6.

Choose whether to stop processing any further rules in this filter rule
group when this particular filter rule is matched.

By default, this is set to I<"No">, which means that even if this rule
matches, the rules after it will still be checked too.

For this example, leave it set to I<"No">.

=back

Click on the B<Create> button to create the new filter rule.  You will see a
message something like C<Filter rule 15 created>.  Click on the B<Back>
button below that message to return to the list of filter rules.

Your new rule will be shown in the list.  The conflicts, requirements, and
actions are detailed in the list.  You will see that this new rule:

=over

=item *

Will never match, if the subject or message body contains the word C<paste>.

=item *

Will match otherwise, if the ticket was created in the I<General> queue, and
its subject or message body contains either of the words C<wallpaper> or
C<background>, I<and> its subject or message body contains the word
C<desktop>.

=item *

When the rule matches, it will move the ticket to the I<Technical> queue.

=back

For example, if someone creates a ticket in the I<General> queue mentioning
C<desktop wallpaper> or C<desktop background>, the ticket will be moved to
the I<Technical> queue, but if they mention C<desktop wallpaper paste>, the
ticket will not be moved because of the conflict condition about the word
C<paste>.

Usually you would not actually move tickets based on keyword matches, this
is just an example - though you may want to send notification emails when
certain words appear, or set custom field values or priorities, for
instance.

Filter rules are processed in order.  In the list of filter rules, use the
I<[Up]> and I<[Down]> links to move filter rules up and down.

=head2 Testing filter rules

Filter rules can be tested without having to really create new tickets or
move them between queues, but you will need an existing ticket to use as a
point of reference.

From either I<Tools> - I<Filter rules> or I<Admin> - I<Filter rule groups>,
choose the I<Test> option from the page menu at the top right.

=over

=item 1.

Choose a ticket to test against.  This is used in rules regarding ticket
subject, message body, and so on.

=item 2.

Choose which filter rule group to test against, or I<"All"> to run the test
against all filter rule groups you have access to.

=item 3.

Select the type of triggering event to simulate.

=item 4.

Choose the queue or queues involved in the simulation.  For instance, if you
are simulating ticket creation, choose which queue to pretend it is being
created in.

=item 5.

Choose whether to include disabled rules in the test.  This can be useful if
you would like to set up new filter rules and test them before using them -
you can create them but leave them disabled, then run this test with
disabled rules included.

=back

Click on the B<Test> button to run the test; the results will be shown in
the I<Results> section below the input form.

The test will not make any changes to tickets or to filter rules.

For each filter rule group, the B<requirement rules> will be processed, and
a detailed breakdown of the steps involved will be displayed.

If any requirement rules matched, then a breakdown the B<filter rules> will
be shown, followed by the B<actions> which those filter rules would give
rise to.

The I<Rule>, I<Match type>, and I<Outcome of test> columns show the overall
outcome of each rule.  The I<Conflict conditions> and I<Requirement
conditions> columns give details of all of the individual conditions within
each rule.

Within the rule processing steps, the I<Event value> refers to the value
taken from the event - for instance, in a subject matching condition, this
would be the ticket's subject.  The I<Target value> refers to the value the
condition is looking for - that is, the values you entered into the form
when creating the filter rules.

=cut

=head1 INTERNAL FUNCTIONS

These functions are used internally by this extension.  They should all be
called as methods, like this:

 return RT::Extension::FilterRules->ScripIsApplicable($self);

=head2 ScripIsApplicable $Condition

The "is-applicable" condition of the scrip which applies filter rules to
tickets.  Returns true if it is appropriate for this extension to
investigate the action associated with this scrip.

=cut

sub ScripIsApplicable {
    my ( $Package, $Condition ) = @_;

    # The scrip should run on ticket creation.
    #
    return 1 if ( $Condition->TransactionObj->Type eq 'Create' );

    # The scrip should run when a ticket changes queue.
    #
    return 1
        if ( ( $Condition->TransactionObj->Type eq 'Set' )
        && ( $Condition->TransactionObj->Field eq 'Queue' ) );

    # The script should not run otherwise.
    #
    return 0;
}

=head2 ScripPrepare $Action

The "prepare" action of the scrip which applies filter rules to tickets. 
Returns true on success.

=cut

sub ScripPrepare {
    my ( $Package, $Action ) = @_;

    # There are no preparations to make.
    #
    return 1;
}

=head2 ScripCommit $Action

The "commit" action of the scrip which applies filter rules to tickets. 
Returns true on success.

=cut

sub ScripCommit {
    my ( $Package, $Action ) = @_;
    my ( $TriggerType, $QueueFrom, $QueueTo ) = ( undef, undef, undef );
    my ( $FilterRuleGroups, $FilterRuleGroup, $RuleChecks, $Actions );

    #
    # Determine the type of trigger to look for, and the queue(s) involved.
    #
    if ( $Action->TransactionObj->Type eq 'Create' ) {
        $TriggerType = 'Create';
        $QueueFrom   = $Action->TicketObj->Queue;
        $QueueTo     = $QueueFrom;
    } elsif ( ( $Action->TransactionObj->Type eq 'Set' )
        && ( $Action->TransactionObj->Field eq 'Queue' ) )
    {
        $TriggerType = 'QueueMove';
        $QueueFrom   = $Action->TransactionObj->OldValue;
        $QueueTo     = $Action->TransactionObj->NewValue;
    }

    # Nothing to do if we did not determine a trigger type.
    #
    return 0 if ( not defined $TriggerType );

    $RuleChecks = [];
    $Actions    = [];

    # Load all filter rule groups.
    #
    $FilterRuleGroups = RT::FilterRuleGroups->new( RT->SystemUser );
    $FilterRuleGroups->UnLimit();
    $FilterRuleGroups->Limit(
        'FIELD'    => 'Disabled',
        'VALUE'    => 0,
        'OPERATOR' => '='
    );
    $FilterRuleGroups->OrderByCols(
        { FIELD => 'SortOrder', ORDER => 'ASC' } );

    # Check the filter rules in each filter rule group whose group
    # requirements are met, building up a list of actions to perform.
    #
    while ( $FilterRuleGroup = $FilterRuleGroups->Next ) {
        my ( $Matched, $Message, $EventValue, $TargetValue );
        ( $Matched, $Message, $EventValue, $TargetValue )
            = $FilterRuleGroup->CheckGroupRequirements(
            'RuleChecks'      => $RuleChecks,
            'TriggerType'     => $TriggerType,
            'From'            => $QueueFrom,
            'To'              => $QueueTo,
            'Ticket'          => $Action->TicketObj,
            'RecordMatch'     => 1,
            'IncludeDisabled' => 0
            );
        next if ( not $Matched );

        ( $Matched, $Message, $EventValue, $TargetValue )
            = $FilterRuleGroup->CheckFilterRules(
            'RuleChecks'      => $RuleChecks,
            'Actions'         => $Actions,
            'TriggerType'     => $TriggerType,
            'From'            => $QueueFrom,
            'To'              => $QueueTo,
            'Ticket'          => $Action->TicketObj,
            'RecordMatch'     => 1,
            'IncludeDisabled' => 0
            );
    }

    # Keep track of the filter rule IDs we've performed actions on.
    #
    my %ActionedRules = ();

    # Perform the non-notification actions we have accumulated.
    #
    foreach ( grep { not $_->{'Action'}->IsNotification } @$Actions ) {
        $_->{'Action'}->Perform( $_->{'FilterRule'}, $Action->TicketObj );
        $ActionedRules{ $_->{'FilterRule'}->id } = 1;
    }

    # Perform the notification actions we have accumulated.
    #
    foreach ( grep { $_->{'Action'}->IsNotification } @$Actions ) {
        $_->{'Action'}->Perform( $_->{'FilterRule'}, $Action->TicketObj );
        $ActionedRules{ $_->{'FilterRule'}->id } = 1;
    }

    # Set an attribute on this ticket for each action we have taken to avoid
    # recursion.
    #
    my $Epoch = 0 + time;
    foreach ( keys %ActionedRules ) {
        $Action->TicketObj->SetAttribute(
            'Name'    => 'FilterRules-' . $_,
            'Content' => $Epoch
        );
    }

    return 1;
}

=head2 ConditionTypes $UserObj

Return an array of all available condition types, with the names localised
for the given user.

Each array entry is a hash reference containing these keys:

=over 18

=item B<ConditionType>

The internal name for this condition type; this should follow the naming
convention for variables - start with a letter, no spaces, and so on - and
it must be unique

=item B<Name>

Localised name, to be displayed to the operator

=item B<TriggerTypes>

Array reference listing the trigger actions with which this condition can be
used (as listed under the I<TriggerType> attribute of the C<RT::FilterRule>
class below), or an empty array reference (or undef) if this condition type
can be used with all trigger types

=item B<ValueType>

Which type of value the condition expects as a parameter - one of
I<None>, I<String>, I<Integer>, I<Email>, I<Queue>, or I<Status>

=item B<Function>

If present, this is a code reference which will be called to check this
condition; this code reference will be passed an C<RT::CurrentUser> object
and a hash of the parameters from inside an C<RT::FilterRule::Condition>
object (including I<TargetValue>), as it will be called from the
B<TestSingleValue> method of C<RT::FilterRule::Condition> - like
B<TestSingleValue>, it should return ( I<$matched>, I<$message>,
I<$eventvalue> ).

=back

If I<Function> is not present, the B<TestSingleValue> method of
C<RT::FilterRule::Condition> will attempt to call an
C<RT::FilterRule::Condition> method of the same name as I<ConditionType>
with C<_> prepended, returning a failed match (and logging an error) if such
a method does not exist.

Note that if I<ConditionType> contains the string C<CustomField>, then the
condition will require the person creating the condition to select an
applicable custom field.

=cut

sub ConditionTypes {
    my ( $Package, $UserObj ) = @_;
    my @ConditionTypes = ();

    push @ConditionTypes,
        (
        {   'ConditionType' => 'All',
            'Name'          => $UserObj->loc('Always match'),
            'TriggerTypes'  => [],
            'ValueType'     => 'None'
        },
        {   'ConditionType' => 'InQueue',
            'Name'          => $UserObj->loc('In queue'),
            'TriggerTypes'  => ['Create'],
            'ValueType'     => 'Queue'
        },
        {   'ConditionType' => 'FromQueue',
            'Name'          => $UserObj->loc('Moving from queue'),
            'TriggerTypes'  => ['QueueMove'],
            'ValueType'     => 'Queue'
        },
        {   'ConditionType' => 'ToQueue',
            'Name'          => $UserObj->loc('Moving to queue'),
            'TriggerTypes'  => ['QueueMove'],
            'ValueType'     => 'Queue'
        },
        {   'ConditionType' => 'RequestorEmailIs',
            'Name'          => $UserObj->loc('Requestor email address is'),
            'TriggerTypes'  => [],
            'ValueType'     => 'Email'
        },
        {   'ConditionType' => 'RequestorEmailDomainIs',
            'Name'          => $UserObj->loc('Requestor email domain is'),
            'TriggerTypes'  => [],
            'ValueType'     => 'String'
        },
        {   'ConditionType' => 'RecipientEmailIs',
            'Name'          => $UserObj->loc('Recipient email address is'),
            'TriggerTypes'  => ['Create'],
            'ValueType'     => 'Email'
        },
        {   'ConditionType' => 'SubjectContains',
            'Name'          => $UserObj->loc('Subject contains'),
            'TriggerTypes'  => [],
            'ValueType'     => 'String'
        },
        {   'ConditionType' => 'SubjectOrBodyContains',
            'Name' => $UserObj->loc('Subject or message body contains'),
            'TriggerTypes' => [],
            'ValueType'    => 'String'
        },
        {   'ConditionType' => 'BodyContains',
            'Name'          => $UserObj->loc('Message body contains'),
            'TriggerTypes'  => [],
            'ValueType'     => 'String'
        },
        {   'ConditionType' => 'HasAttachment',
            'Name'          => $UserObj->loc('Has an attachment'),
            'TriggerTypes'  => ['Create'],
            'ValueType'     => 'None'
        },
        {   'ConditionType' => 'PriorityIs',
            'Name'          => $UserObj->loc('Priority is'),
            'TriggerTypes'  => [],
            'ValueType'     => 'Integer'
        },
        {   'ConditionType' => 'PriorityUnder',
            'Name'          => $UserObj->loc('Priority less than'),
            'TriggerTypes'  => [],
            'ValueType'     => 'Integer'
        },
        {   'ConditionType' => 'PriorityOver',
            'Name'          => $UserObj->loc('Priority greater than'),
            'TriggerTypes'  => [],
            'ValueType'     => 'Integer'
        },
        {   'ConditionType' => 'CustomFieldIs',
            'Name'          => $UserObj->loc('Custom field exactly matches'),
            'TriggerTypes'  => [],
            'ValueType'     => 'String'
        },
        {   'ConditionType' => 'CustomFieldContains',
            'Name'          => $UserObj->loc('Custom field contains'),
            'TriggerTypes'  => [],
            'ValueType'     => 'String'
        },
        {   'ConditionType' => 'StatusIs',
            'Name'          => $UserObj->loc('Status is'),
            'TriggerTypes'  => [],
            'ValueType'     => 'Status'
        },
        );

    foreach (@ConditionProviders) {
        push @ConditionTypes, $_->($UserObj);
    }

    # Convert empty TriggerTypes into lists of all trigger types
    #
    foreach (@ConditionTypes) {
        if ( scalar @{ $_->{'TriggerTypes'} } == 0 ) {
            $_->{'TriggerTypes'} = [ 'Create', 'QueueMove' ];
        }
    }

    return @ConditionTypes;
}

=head2 ActionTypes $UserObj

Return an array of all available action types, with the names localised for
the given user.

Each array entry is a hash reference containing these keys:

=over 18

=item B<ActionType>

The internal name for this action type; this should follow the naming
convention for variables - start with a letter, no spaces, and so on - and
it must be unique

=item B<Name>

Localised name, to be displayed to the operator

=item B<ValueType>

Which type of value the action expects as a parameter - one of I<None>,
I<String>, I<Integer>, I<Email>, I<Group>, I<Queue>, I<Status>, or I<HTML>

=item B<Function>

If present, this is a code reference which will be called to perform this
action; this code reference will be passed an C<RT::CurrentUser> object and
a hash of the parameters from inside an C<RT::FilterRule::Action> object, as
it will be called from the B<Perform> method of C<RT::FilterRule::Action> -
it should return ( I<$ok>, I<$message> )

=back

If I<Function> is not present, the B<Perform> method of
C<RT::FilterRule::Action> will attempt to call an C<RT::FilterRule::Action>
method of the same name as I<ActionType> with C<_> prepended, returning a
failed action (and logging an error) if such a method does not exist.

Note that:

=over

=item *

If I<ActionType> contains the string C<CustomField>, then a custom field
must be selected by the person creating the action, separately to the value,
and this will populate the C<RT::FilterRule::Action>'s I<CustomField>
attribute;

=item *

If I<ActionType> contains the string C<NotifyEmail>, then an email address
must be entered by the person creating the action, separately to the value,
and this will populate the C<RT::FilterRule::Action>'s I<Notify> attribute;

=item *

If I<ActionType> contains the string C<NotifyGroup>, then an RT group must
be selected by the person creating the action, separately to the value, and
this will populate the C<RT::FilterRule::Action>'s I<Notify> attribute.

=back

=cut

sub ActionTypes {
    my ( $Package, $UserObj ) = @_;
    my @ActionTypes = ();

    push @ActionTypes,
        (
        {   'ActionType' => 'None',
            'Name'       => $UserObj->loc('Take no action'),
            'ValueType'  => 'None'
        },
        {   'ActionType' => 'SubjectPrefix',
            'Name'       => $UserObj->loc('Add prefix to subject'),
            'ValueType'  => 'String'
        },
        {   'ActionType' => 'SubjectSuffix',
            'Name'       => $UserObj->loc('Add suffix to subject'),
            'ValueType'  => 'String'
        },
        {   'ActionType' => 'SubjectRemoveMatch',
            'Name'       => $UserObj->loc('Remove string from subject'),
            'ValueType'  => 'String'
        },
        {   'ActionType' => 'SubjectSet',
            'Name'       => $UserObj->loc('Replace subject'),
            'ValueType'  => 'String'
        },
        {   'ActionType' => 'PrioritySet',
            'Name'       => $UserObj->loc('Set priority'),
            'ValueType'  => 'Integer'
        },
        {   'ActionType' => 'PriorityAdd',
            'Name'       => $UserObj->loc('Add to priority'),
            'ValueType'  => 'Integer'
        },
        {   'ActionType' => 'PrioritySubtract',
            'Name'       => $UserObj->loc('Subtract from priority'),
            'ValueType'  => 'Integer'
        },
        {   'ActionType' => 'StatusSet',
            'Name'       => $UserObj->loc('Set status'),
            'ValueType'  => 'Status'
        },
        {   'ActionType' => 'QueueSet',
            'Name'       => $UserObj->loc('Move to queue'),
            'ValueType'  => 'Queue'
        },
        {   'ActionType' => 'CustomFieldSet',
            'Name'       => $UserObj->loc('Set custom field value'),
            'ValueType'  => 'String'
        },
        {   'ActionType' => 'RequestorAdd',
            'Name'       => $UserObj->loc('Add requestor'),
            'ValueType'  => 'Email'
        },
        {   'ActionType' => 'RequestorRemove',
            'Name'       => $UserObj->loc('Remove requestor'),
            'ValueType'  => 'Email'
        },
        {   'ActionType' => 'CcAdd',
            'Name'       => $UserObj->loc('Add CC'),
            'ValueType'  => 'Email'
        },
        {   'ActionType' => 'CcAddGroup',
            'Name'       => $UserObj->loc('Add group as a CC'),
            'ValueType'  => 'Group'
        },
        {   'ActionType' => 'CcRemove',
            'Name'       => $UserObj->loc('Remove CC'),
            'ValueType'  => 'Email'
        },
        {   'ActionType' => 'AdminCcAdd',
            'Name'       => $UserObj->loc('Add AdminCC'),
            'ValueType'  => 'Email'
        },
        {   'ActionType' => 'AdminCcAddGroup',
            'Name'       => $UserObj->loc('Add group as an AdminCC'),
            'ValueType'  => 'Group'
        },
        {   'ActionType' => 'AdminCcRemove',
            'Name'       => $UserObj->loc('Remove AdminCC'),
            'ValueType'  => 'Email'
        },
        {   'ActionType' => 'Reply',
            'Name'       => $UserObj->loc('Reply to ticket'),
            'ValueType'  => 'HTML'
        },
        {   'ActionType' => 'NotifyEmail',
            'Name' => $UserObj->loc('Send notification to an email address'),
            'ValueType' => 'HTML'
        },
        {   'ActionType' => 'NotifyGroup',
            'Name' => $UserObj->loc('Send notification to RT group members'),
            'ValueType' => 'HTML'
        },
        );

    foreach (@ActionProviders) {
        push @ActionTypes, $_->($UserObj);
    }

    return @ActionTypes;
}

=head2 AddConditionProvider CODEREF

Add a condition provider, which is a function accepting an
C<RT::CurrentUser> object and returning an array of the same form as the
B<ConditionTypes> method.

The B<ConditionTypes> method will call the provided code reference and
append its returned values to the array it returns.

Other extensions can call this method to add their own filter condition
types.

=cut

sub AddConditionProvider {
    my ( $Package, $CodeRef ) = @_;
    push @ConditionProviders, $CodeRef;
}

=head2 AddActionProvider CODEREF

Add an action provider, which is a function accepting an
C<RT::CurrentUser> object and returning an array of the same form as the
B<ActionTypes> method.

The B<ActionTypes> method will call the provided code reference and append
its returned values to the array it returns.

Other extensions can call this method to add their own filter action types.

=cut

sub AddActionProvider {
    my ( $Package, $CodeRef ) = @_;
    push @ActionProviders, $CodeRef;
}

{

=head1 Internal package RT::FilterRuleGroup

This package provides the C<RT::FilterRuleGroup> class, which describes a
group of filter rules through which a ticket will be passed if it meets the
basic requirements of the group.

The attributes of this class are:

=over 20

=item B<id>

The numeric ID of this filter rule group

=item B<SortOrder>

The order of processing - filter rule groups with a lower sort order are
processed first

=item B<Name>

The displayed name of this filter rule group

=item B<CanMatchQueues>

The queues which rules in this rule group are allowed to use in their
conditions, as a comma-separated list of queue IDs (also presented as an
C<RT::Queues> object via B<CanMatchQueuesObj>)

=item B<CanTransferQueues>

The queues which rules in this rule group are allowed to use as transfer
destinations in their actions, as a comma-separated list of queue IDs (also
presented as an C<RT::Queues> object via B<CanTransferQueuesObj>)

=item B<CanUseGroups>

The groups which rules in this rule group are allowed to use in match
conditions and actions, as a comma-separated list of group IDs (also
presented as an C<RT::Groups> object via B<CanUseGroupsObj>)

=item B<Creator>

The numeric ID of the creator of this filter rule group (also presented as
an C<RT::User> object via B<CreatorObj>)

=item B<Created>

The date and time this filter rule group was created (also presented as an
C<RT::Date> object via B<CreatedObj>)

=item B<LastUpdatedBy>

The numeric ID of the user who last updated the properties of this filter
rule group (also presented as an C<RT::User> object via B<LastUpdatedByObj>)

=item B<LastUpdated>

The date and time this filter rule group's properties were last updated
(also presented as an C<RT::Date> object via B<LastUpdatedObj>)

=item B<Disabled>

Whether this filter rule group is disabled; the filter rule group is active
unless this property is true

=back

The basic requirements of the filter rule group are defined by its
B<GroupRequirements>, which is a collection of C<RT::FilterRule> objects
whose B<IsGroupRequirement> attribute is true.  If I<any> of these rules
match, the ticket is eligible to be passed through the filter rules for this
group.

The filter rules for this group are presented via B<FilterRules>, which is a
collection of C<RT::FilterRule> objects.

Filter rule groups themselves can only be created, modified, and deleted by
users with the I<SuperUser> right.

The following rights can be assigned to individual filter rule groups to
delegate control of the filter rules within them:

=over 18

=item B<SeeFilterRule>

View the filter rules in this filter rule group

=item B<ModifyFilterRule>

Modify existing filter rules in this filter rule group

=item B<CreateFilterRule>

Create new filter rules in this filter rule group

=item B<DeleteFilterRule>

Delete filter rules from this filter rule group

=back

These are assigned using the rights pages of the filter rule group, under
I<Admin> - I<Filter rule groups>.

=cut

    package RT::FilterRuleGroup;
    use base 'RT::Record';

    use Role::Basic 'with';
    with 'RT::Record::Role::Rights';

    sub Table {'FilterRuleGroups'}

    __PACKAGE__->AddRight(
        'Staff' => 'SeeFilterRule' => 'View filter rules' );    # loc
    __PACKAGE__->AddRight(
        'Staff' => 'ModifyFilterRule' => 'Modify filter rules' );    # loc
    __PACKAGE__->AddRight(
        'Staff' => 'CreateFilterRule' => 'Create new filter rules' );    # loc
    __PACKAGE__->AddRight(
        'Staff' => 'DeleteFilterRule' => 'Delete filter rules' );        # loc

    use RT::Transactions;

=head1 RT::FilterRuleGroup METHODS

Note that additional methods will be available, inherited from
C<RT::Record>.

=cut

=head2 Create Name => Name, ...

Create a new filter rule group with the supplied properties, as described
above.  The sort order will be set to 1 more than the highest current value
so that the new item appears at the end of the list.

Returns ( I<$id>, I<$message> ), where I<$id> is the ID of the new object,
which will be undefined if there was a problem.

=cut

    sub Create {
        my $self = shift;
        my %args = (
            'Name'              => '',
            'CanMatchQueues'    => '',
            'CanTransferQueues' => '',
            'CanUseGroups'      => '',
            'Disabled'          => 0,
            @_
        );

        # Allow the fields which take ID lists to be passed as arrayrefs of
        # IDs, arrayrefs of RT::Queue or RT::Group objects, or as RT::Queues
        # or RT::Groups collection objects, by converting all of those back
        # to a comma separated list of IDs.
        #
        foreach my $Field ( 'CanMatchQueues', 'CanTransferQueues',
            'CanUseGroups' )
        {
            my $Value = $args{$Field};

            # Convert a collection object into an array ref
            #
            if (   ( ref $Value )
                && ( ref $Value ne 'ARRAY' )
                && (   UNIVERSAL::isa( $Value, 'RT::Queues' )
                    || UNIVERSAL::isa( $Value, 'RT::Groups' ) )
               )
            {
                $Value = $Value->ItemsArrayRef();
            }

            # Convert an array ref into a comma separated ID list
            #
            if ( ref $Value eq 'ARRAY' ) {
                $Value = join( ',',
                    map { ref $Value ? $Value->id : $Value } @$Value );
            }

            $args{$Field} = $Value;
        }

        $args{'SortOrder'} = 1;

        $RT::Handle->BeginTransaction();

        my $AllFilterRuleGroups
            = RT::FilterRuleGroups->new( $self->CurrentUser );
        $AllFilterRuleGroups->UnLimit();
        $AllFilterRuleGroups->OrderByCols(
            { FIELD => 'SortOrder', ORDER => 'DESC' } );
        $AllFilterRuleGroups->GotoFirstItem();
        my $FinalFilterRuleGroup = $AllFilterRuleGroups->Next;
        $args{'SortOrder'} = 1 + $FinalFilterRuleGroup->SortOrder
            if ($FinalFilterRuleGroup);

        my ( $id, $msg ) = $self->SUPER::Create(%args);
        unless ($id) {
            $RT::Handle->Rollback();
            return ( undef, $msg );
        }

        my ( $txn_id, $txn_msg, $txn )
            = $self->_NewTransaction( Type => 'Create' );
        unless ($txn_id) {
            $RT::Handle->Rollback();
            return ( undef, $self->loc( 'Internal error: [_1]', $txn_msg ) );
        }
        $RT::Handle->Commit();

        return ( $id,
            $self->loc( 'Filter rule group [_1] created', $self->id ) );
    }

=head2 CanMatchQueues

Return the queues which rules in this rule group are allowed to use in their
conditions, as a comma-separated list of queue IDs in a scalar context, or
as an array of queue IDs in a list context.

=cut

    sub CanMatchQueues {
        my ($self) = @_;
        my $Value = $self->_Value('CanMatchQueues');
        return wantarray ? split /,/, $Value : $Value;
    }

=head2 CanMatchQueuesObj

Return the same as B<CanMatchQueues>, but as an C<RT::Queues> object, i.e. a
collection of C<RT::Queue> objects.

=cut

    sub CanMatchQueuesObj {
        my ($self) = @_;
        my ( @Values, $Collection );
        @Values     = $self->CanMatchQueues;
        $Collection = RT::Queues->new( $self->CurrentUser );
        $Collection->Limit(
            'FIELD'           => 'id',
            'VALUE'           => $_,
            'OPERATOR'        => '=',
            'ENTRYAGGREGATOR' => 'OR'
        ) foreach (@Values);
        $Collection->Limit(
            'FIELD'    => 'id',
            'VALUE'    => 0,
            'OPERATOR' => '='
        ) if ( scalar @Values < 1 );
        return $Collection;
    }

=head2 CanTransferQueues

Return the queues which rules in this rule group are allowed to use as
transfer destinations in their actions, as a comma-separated list of queue
IDs in a scalar context, or as an array of queue IDs in a list context.

=cut

    sub CanTransferQueues {
        my ($self) = @_;
        my $Value = $self->_Value('CanTransferQueues');
        return wantarray ? split /,/, $Value : $Value;
    }

=head2 CanTransferQueuesObj

Return the same as B<CanTransferQueues>, but as an C<RT::Queues> object,
i.e. a collection of C<RT::Queue> objects.

=cut

    sub CanTransferQueuesObj {
        my ($self) = @_;
        my ( @Values, $Collection );
        @Values     = $self->CanTransferQueues;
        $Collection = RT::Queues->new( $self->CurrentUser );
        $Collection->Limit(
            'FIELD'           => 'id',
            'VALUE'           => $_,
            'OPERATOR'        => '=',
            'ENTRYAGGREGATOR' => 'OR'
        ) foreach (@Values);
        $Collection->Limit(
            'FIELD'    => 'id',
            'VALUE'    => 0,
            'OPERATOR' => '='
        ) if ( scalar @Values < 1 );
        return $Collection;
    }

=head2 CanUseGroups

Return the groups which rules in this rule group are allowed to use in match
conditions and actions, as a comma-separated list of group IDs in a scalar
context, or as an array of group IDs in a list context.

=cut

    sub CanUseGroups {
        my ($self) = @_;
        my $Value = $self->_Value('CanUseGroups');
        return wantarray ? split /,/, $Value : $Value;
    }

=head2 CanUseGroupsObj

Return the same as B<CanUseGroups>, but as an C<RT::Groups> object, i.e. a
collection of C<RT::Group> objects.

=cut

    sub CanUseGroupsObj {
        my ($self) = @_;
        my ( @Values, $Collection );
        @Values     = $self->CanUseGroups;
        $Collection = RT::Groups->new( $self->CurrentUser );
        $Collection->Limit(
            'FIELD'           => 'id',
            'VALUE'           => $_,
            'OPERATOR'        => '=',
            'ENTRYAGGREGATOR' => 'OR'
        ) foreach (@Values);
        $Collection->Limit(
            'FIELD'    => 'id',
            'VALUE'    => 0,
            'OPERATOR' => '='
        ) if ( scalar @Values < 1 );
        return $Collection;
    }

=head2 SetCanMatchQueues id, id, ...

Set the queues which rules in this rule group are allowed to use in their
conditions, either as a comma-separated list of queue IDs, an array of queue
IDs, an array of C<RT::Queue> objects, or an C<RT::Queues> collection.

Returns ( I<$ok>, I<$message> ).

=cut

    sub SetCanMatchQueues {
        my ( $self, @NewValues ) = @_;
        my %NewIDs = ();

        foreach my $Item (@NewValues) {
            if ( not ref $Item ) {
                foreach ( split /,/, $Item ) {
                    next if ( !/([0-9]+)/ );
                    $NewIDs{$1} = 1;
                }
            } elsif ( UNIVERSAL::isa( $Item, 'RT::Queue' ) ) {
                $NewIDs{ $Item->id } = 1 if ( $Item->id );
            } elsif ( UNIVERSAL::isa( $Item, 'RT::Queues' ) ) {
                $Item->GotoFirstItem();
                while ( my $Object = $Item->Next() ) {
                    $NewIDs{ $Object->id } = 1 if ( $Object->id );
                }
            }
        }

        return $self->_Set(
            'Field' => 'CanMatchQueues',
            'Value' => join( ',', sort { $a <=> $b } keys %NewIDs )
        );
    }

=head2 SetCanTransferQueues id, id, ...

Set the queues which rules in this filter rule group are allowed to use as
transfer destinations in their actions, either as a comma-separated list of
queue IDs, an array of queue IDs, an array of C<RT::Queue> objects, or an
C<RT::Queues> collection.

Returns ( I<$ok>, I<$message> ).

=cut

    sub SetCanTransferQueues {
        my ( $self, @NewValues ) = @_;
        my %NewIDs = ();

        foreach my $Item (@NewValues) {
            if ( not ref $Item ) {
                foreach ( split /,/, $Item ) {
                    next if ( !/([0-9]+)/ );
                    $NewIDs{$1} = 1;
                }
            } elsif ( UNIVERSAL::isa( $Item, 'RT::Queue' ) ) {
                $NewIDs{ $Item->id } = 1 if ( $Item->id );
            } elsif ( UNIVERSAL::isa( $Item, 'RT::Queues' ) ) {
                $Item->GotoFirstItem();
                while ( my $Object = $Item->Next() ) {
                    $NewIDs{ $Object->id } = 1 if ( $Object->id );
                }
            }
        }

        return $self->_Set(
            'Field' => 'CanTransferQueues',
            'Value' => join( ',', sort { $a <=> $b } keys %NewIDs )
        );
    }

=head2 SetCanUseGroups id, id, ...

Set the groups which rules in this rule group are allowed to use in match
conditions and actions, either as a comma-separated list of group IDs, an
array of group IDs, an array of C<RT::Group> objects, or an C<RT::Groups>
collection.

Returns ( I<$ok>, I<$message> ).

=cut

    sub SetCanUseGroups {
        my ( $self, @NewValues ) = @_;
        my %NewIDs = ();

        foreach my $Item (@NewValues) {
            if ( not ref $Item ) {
                foreach ( split /,/, $Item ) {
                    next if ( !/([0-9]+)/ );
                    $NewIDs{$1} = 1;
                }
            } elsif ( UNIVERSAL::isa( $Item, 'RT::Group' ) ) {
                $NewIDs{ $Item->id } = 1 if ( $Item->id );
            } elsif ( UNIVERSAL::isa( $Item, 'RT::Groups' ) ) {
                $Item->GotoFirstItem();
                while ( my $Object = $Item->Next() ) {
                    $NewIDs{ $Object->id } = 1 if ( $Object->id );
                }
            }
        }

        return $self->_Set(
            'Field' => 'CanUseGroups',
            'Value' => join( ',', sort { $a <=> $b } keys %NewIDs )
        );
    }

=head2 GroupRequirements

Return an C<RT::FilterRules> collection object containing the requirements
of this filter rule group - if an event matches any of these requirement
rules, then the caller should process the event through the B<FilterRules>
for this group.

=cut

    sub GroupRequirements {
        my ($self) = @_;

        my $Collection = RT::FilterRules->new( $self->CurrentUser );
        $Collection->UnLimit();
        $Collection->Limit(
            'FIELD'    => 'FilterRuleGroup',
            'VALUE'    => $self->id,
            'OPERATOR' => '='
        );
        $Collection->Limit(
            'FIELD'    => 'IsGroupRequirement',
            'VALUE'    => 1,
            'OPERATOR' => '='
        );

        return $Collection;
    }

=head2 AddGroupRequirement Name => NAME, ...

Add a requirement rule to this filter rule group; calls the
C<RT::FilterRule> B<Create> method, overriding the I<FilterRuleGroup> and
I<IsGroupRequirement> parameters, and returns its output.

=cut

    sub AddGroupRequirement {
        my $self = shift;
        my %args = (@_);
        my $Object;

        $Object = RT::FilterRule->new( $self->CurrentUser );

        return $Object->Create(
            %args,
            'FilterRuleGroup'    => $self->id,
            'IsGroupRequirement' => 1
        );
    }

=head2 FilterRules

Return an C<RT::FilterRules> collection object containing the filter rules
for this rule group.

=cut

    sub FilterRules {
        my ($self) = @_;

        my $Collection = RT::FilterRules->new( $self->CurrentUser );
        $Collection->UnLimit();
        $Collection->Limit(
            'FIELD'    => 'FilterRuleGroup',
            'VALUE'    => $self->id,
            'OPERATOR' => '='
        );
        $Collection->Limit(
            'FIELD'    => 'IsGroupRequirement',
            'VALUE'    => 0,
            'OPERATOR' => '='
        );

        return $Collection;
    }

=head2 AddFilterRule Name => NAME, ...

Add a filter rule to this filter rule group; calls the C<RT::FilterRule>
B<Create> method, overriding the I<FilterRuleGroup> and I<IsGroupRequirement>
parameters, and returns its output.

=cut

    sub AddFilterRule {
        my $self = shift;
        my %args = (@_);
        my $Object;

        $Object = RT::FilterRule->new( $self->CurrentUser );

        return $Object->Create(
            %args,
            'FilterRuleGroup'    => $self->id,
            'IsGroupRequirement' => 0
        );
    }

=head2 Delete

Delete this filter rule group, and all of its filter rules.  Returns
( I<$ok>, I<$message> ).

=cut

    sub Delete {
        my ($self) = @_;
        my ( $Collection, $Item );

        # Delete the group requirements.
        #
        $Collection = $self->GroupRequirements();
        $Collection->FindAllRows();
        $Collection->GotoFirstItem();
        while ( $Item = $Collection->Next ) {
            $Item->Delete();
        }

        # Delete the filter rules.
        #
        $Collection = $self->FilterRules();
        $Collection->FindAllRows();
        $Collection->GotoFirstItem();
        while ( $Item = $Collection->Next ) {
            $Item->Delete();
        }

        # Delete the transactions.
        #
        $Collection = $self->Transactions();
        $Collection->GotoFirstItem();
        while ( $Item = $Collection->Next ) {
            $Item->Delete();
        }

        # Delete this object itself.
        #
        return $self->SUPER::Delete();
    }

=head2 CheckGroupRequirements RuleChecks => [], TriggerType => ...,

For the given event, append details of checked group requirements to the
I<RuleChecks> array reference.

A I<Ticket> should be supplied, either as an ID or as an C<RT::Ticket> object.

Returns ( I<$Matched>, I<$Message>, I<$EventValue>, I<$TargetValue> ), where
I<$Matched> will be true if there were any requirement rule matches (meaning
that the caller should pass the event through this filter rule group's
B<FilterRules>), false if there were no matches.  The other returned values
will relate to the last requirements rule matched.

If I<IncludeDisabled> is true, then even rules marked as disabled will be
checked.  The default is false.

If I<DescribeAll> is true, then all conditions for all requirement rules
will be added to I<RuleChecks> regardless of whether they influenced the
outcome; this can be used to present the operator with details of how an
event would be processed.

If I<RecordMatch> is true, then the fact that a rule is matched will be
recorded in the database (see C<RT::FilterRuleMatch>).  The default is not
to record the match.

A I<Cache> should be provided, pointing to a hash reference to store
information in while processing this event, which the caller should share
with the B<CheckFilterRules> method and other instances of this class, for
the same event.

See the C<RT::FilterRule> B<TestRule> method for more details of these
return values, for the structure of the I<RuleChecks> and I<Actions> array
entries, and for the event structure.

=cut

    sub CheckGroupRequirements {
        my $self = shift;
        my %args = (
            'RuleChecks'      => [],
            'TriggerType'     => '',
            'From'            => 0,
            'To'              => 0,
            'Ticket'          => 0,
            'IncludeDisabled' => 0,
            'DescribeAll'     => 0,
            'RecordMatch'     => 0,
            'Cache'           => {},
            @_
        );
        my ( $Collection, $Item );

        $Collection = $self->GroupRequirements();
        $Collection->FindAllRows();
        $Collection->Limit(
            'FIELD'    => 'Disabled',
            'VALUE'    => 0,
            'OPERATOR' => '='
        ) if ( not $args{'IncludeDisabled'} );
        $Collection->GotoFirstItem();

        my ( $Matched, $Message, $FinalEventValue, $FinalTargetValue )
            = ( 0, '', '', '' );

        while ( $Item = $Collection->Next ) {
            next if ( $Item->TriggerType ne $args{'TriggerType'} );
            my ($ItemMatch,      $ItemMessage,
                $ItemEventValue, $ItemTargetValue
               )
                = $Item->TestRule(
                'RuleChecks'  => $args{'RuleChecks'},
                'Actions'     => [],
                'TriggerType' => $args{'TriggerType'},
                'From'        => $args{'From'},
                'To'          => $args{'To'},
                'Ticket'      => $args{'Ticket'},
                'DescribeAll' => $args{'DescribeAll'},
                'Cache'       => $args{'Cache'}
                );
            if ( $ItemMatch && not $Matched ) {
                ( $Matched, $Message, $FinalEventValue, $FinalTargetValue )
                    = (
                    $ItemMatch,      $ItemMessage,
                    $ItemEventValue, $ItemTargetValue
                    );
                $Item->RecordMatch( 'Ticket' => $args{'Ticket'} )
                    if ( $args{'RecordMatch'} );
                last if ( not $args{'DescribeAll'} );
            }
        }

        return ( $Matched, $Message, $FinalEventValue, $FinalTargetValue );
    }

=head2 CheckFilterRules RuleChecks => [], Actions => [], TriggerType => ...,

For the given event, append details of matching filter rules to the
I<RuleChecks> array reference, and append details of the actions which should
be performed due to those matches to the I<Actions> array reference.

A I<Ticket> should be supplied, either as an ID or as an C<RT::Ticket> object.

If I<IncludeDisabled> is true, then even rules marked as disabled will be
checked.  The default is false.

If I<DescribeAll> is true, then all conditions for all filter rules will be
added to I<RuleChecks> regardless of whether they influenced the outcome;
this can be used to present the operator with details of how an event would
be processed.

If I<RecordMatch> is true, then the fact that a rule is matched will be
recorded in the database (see C<RT::FilterRuleMatch>).  The default is not
to record the match.

A I<Cache> should be provided, pointing to a hash reference to store
information in while processing this event, which the caller should share
with the B<CheckGroupRequirements> method and other instances of this class,
for the same event.

Returns ( I<$Matched>, I<$Message>, I<$EventValue>, I<$TargetValue> ), where
I<$Matched> will be true if there were any filter rule matches, false
otherwise, and the other parameters will be related to the last rule
matched.

See the C<RT::FilterRule> B<TestRule> method for more details of these
return values, for the structure of the I<RuleChecks> and I<Actions> array
entries, and for the event structure.

=cut

    sub CheckFilterRules {
        my $self = shift;
        my %args = (
            'RuleChecks'      => [],
            'Actions'         => [],
            'TriggerType'     => '',
            'From'            => 0,
            'To'              => 0,
            'Ticket'          => 0,
            'IncludeDisabled' => 0,
            'DescribeAll'     => 0,
            'RecordMatch'     => 0,
            'Cache'           => {},
            @_
        );
        my ( $Collection, $Item, $MatchesFound );

        $Collection = $self->FilterRules();
        $Collection->FindAllRows();
        $Collection->Limit(
            'FIELD'    => 'Disabled',
            'VALUE'    => 0,
            'OPERATOR' => '='
        ) if ( not $args{'IncludeDisabled'} );
        $Collection->GotoFirstItem();

        my ( $Matched, $Message, $FinalEventValue, $FinalTargetValue )
            = ( 0, '', '', '' );

        while ( $Item = $Collection->Next ) {
            next if ( $Item->TriggerType ne $args{'TriggerType'} );
            my ($ItemMatch,      $ItemMessage,
                $ItemEventValue, $ItemTargetValue
               )
                = $Item->TestRule(
                'RuleChecks'  => $args{'RuleChecks'},
                'Actions'     => $args{'Actions'},
                'TriggerType' => $args{'TriggerType'},
                'From'        => $args{'From'},
                'To'          => $args{'To'},
                'Ticket'      => $args{'Ticket'},
                'DescribeAll' => $args{'DescribeAll'},
                'Cache'       => $args{'Cache'}
                );
            if ($ItemMatch) {
                ( $Matched, $Message, $FinalEventValue, $FinalTargetValue )
                    = (
                    $ItemMatch,      $ItemMessage,
                    $ItemEventValue, $ItemTargetValue
                    );
                $Item->RecordMatch( 'Ticket' => $args{'Ticket'} )
                    if ( $args{'RecordMatch'} );
                last if ( $Item->StopIfMatched );
            }
        }

        return ( $Matched, $Message, $FinalEventValue, $FinalTargetValue );
    }

=head2 MoveUp

Move this filter rule group up in the sort order so it is processed earlier. 
Returns ( I<$ok>, I<$message> ).

=cut

    sub MoveUp {
        my $self = shift;
        return $self->Move(-1);
    }

=head2 MoveDown

Move this filter rule group down in the sort order so it is processed later. 
Returns ( I<$ok>, I<$message> ).

=cut

    sub MoveDown {
        my $self = shift;
        return $self->Move(1);
    }

=head2 Move OFFSET

Change this filter rule group's sort order by the given I<OFFSET>.

=cut

    sub Move {
        my ( $self, $Offset ) = @_;

        return ( 1, $self->loc('Not moved') ) if ( $Offset == 0 );

        my $Collection = RT::FilterRuleGroups->new( $self->CurrentUser );
        $Collection->UnLimit();
        $Collection->FindAllRows();
        $Collection->OrderByCols( { FIELD => 'SortOrder', ORDER => 'ASC' } );
        $Collection->GotoFirstItem();
        my @CollectionOrder = ();
        while ( my $Item = $Collection->Next ) {
            push @CollectionOrder, { 'Object' => $Item, 'id' => $Item->id };
        }

        my $SelfId          = $self->id;
        my $CurrentPosition = -1;
        for ( my $Index = 0; $Index <= $#CollectionOrder; $Index++ ) {
            next if ( $CollectionOrder[$Index]->{'id'} != $SelfId );
            $CurrentPosition = $Index;
        }
        return ( 0, $self->loc('Failed to find current position') )
            if ( $CurrentPosition < 0 );

        my $NewPosition = $CurrentPosition + $Offset;
        if ( $NewPosition < 0 ) {
            return ( 0,
                $self->loc("Can not move up. It's already at the top") );
        } elsif ( $NewPosition > $#CollectionOrder ) {
            return ( 0,
                $self->loc("Can not move down. It's already at the bottom") );
        }

        my $Swap = $CollectionOrder[$CurrentPosition];
        $CollectionOrder[$CurrentPosition] = $CollectionOrder[$NewPosition];
        $CollectionOrder[$NewPosition]     = $Swap;

        for ( my $Index = 0; $Index <= $#CollectionOrder; $Index++ ) {
            $CollectionOrder[$Index]->{'Object'}->SetSortOrder( 1 + $Index );
        }

        return ( 1, $self->loc('Moved') );
    }

=head2 _Set Field => FIELD, Value => VALUE

Set the value of a field, recording a transaction in the process if
appropriate.  Returns ( I<$ok>, I<$message> ).

=cut

    sub _Set {
        my $self = shift;
        my %args = (
            'Field' => '',
            'Value' => '',
            @_
        );

        my $OldValue = $self->__Value( $args{'Field'} );
        return ( 1, '' )
            if ( ( defined $OldValue )
            && ( defined $args{'Value'} )
            && ( $OldValue eq $args{'Value'} ) );

        $RT::Handle->BeginTransaction();

        my ( $ok, $msg ) = $self->SUPER::_Set(%args);

        if ( not $ok ) {
            $RT::Handle->Rollback();
            return ( $ok, $msg );
        }

        # NB we don't record a transaction for sort order changes, since
        # they are very frequent.
        #
        if ( ( $args{'Field'} || '' ) eq 'Disabled' ) {
            my ( $txn_id, $txn_msg, $txn )
                = $self->_NewTransaction(
                Type => $args{'Value'} ? 'Disabled' : 'Enabled' );
            if ( not $txn_id ) {
                $RT::Handle->Rollback();
                return ( 0, $self->loc( 'Internal error: [_1]', $txn_msg ) );
            }
        } elsif ( ( $args{'Field'} || '' ) ne 'SortOrder' ) {
            my ( $txn_id, $txn_msg, $txn ) = $self->_NewTransaction(
                'Type'     => 'Set',
                'Field'    => $args{'Field'},
                'NewValue' => $args{'Value'},
                'OldValue' => $OldValue
            );
            if ( not $txn_id ) {
                $RT::Handle->Rollback();
                return ( 0, $self->loc( 'Internal error: [_1]', $txn_msg ) );
            }
        }

        $RT::Handle->Commit();

        return ( $ok, $msg );
    }

=head2 CurrentUserCanSee

Return true if the current user has permission to see this object.

=cut

    sub CurrentUserCanSee {
        my $self = shift;
        return $self->CurrentUserHasRight('SuperUser');
    }

=head2 _CoreAccessible

Return a hashref describing the attributes of the database table for the
C<RT::FilterRuleGroup> class.

=cut

    sub _CoreAccessible {
        return {

            'id' => {
                read       => 1,
                sql_type   => 4,
                length     => 11,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'int(11)',
                default    => ''
            },

            'SortOrder' => {
                read       => 1,
                write      => 1,
                sql_type   => 4,
                length     => 11,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'int(11)',
                default    => '0'
            },

            'Name' => {
                read       => 1,
                write      => 1,
                sql_type   => 12,
                length     => 200,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'varchar(200)',
                default    => ''
            },

            'CanMatchQueues' => {
                read       => 1,
                write      => 1,
                sql_type   => -4,
                length     => 0,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'text',
                default    => ''
            },

            'CanTransferQueues' => {
                read       => 1,
                write      => 1,
                sql_type   => -4,
                length     => 0,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'text',
                default    => ''
            },

            'CanUseGroups' => {
                read       => 1,
                write      => 1,
                sql_type   => -4,
                length     => 0,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'text',
                default    => ''
            },

            'Creator' => {
                read       => 1,
                auto       => 1,
                sql_type   => 4,
                length     => 11,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'int(11)',
                default    => '0'
            },

            'Created' => {
                read       => 1,
                auto       => 1,
                sql_type   => 11,
                length     => 0,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'datetime',
                default    => ''
            },

            'LastUpdatedBy' => {
                read       => 1,
                auto       => 1,
                sql_type   => 4,
                length     => 11,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'int(11)',
                default    => '0'
            },

            'LastUpdated' => {
                read       => 1,
                auto       => 1,
                sql_type   => 11,
                length     => 0,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'datetime',
                default    => ''
            },

            'Disabled' => {
                read       => 1,
                write      => 1,
                sql_type   => 5,
                length     => 6,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'smallint(6)',
                default    => '0'
            }
        };
    }

    RT::Base->_ImportOverlays();
}

{

=head1 Internal package RT::FilterRuleGroups

This package provides the C<RT::FilterRuleGroups> class, which describes a
collection of filter rule groups.

=cut

    package RT::FilterRuleGroups;

    use base 'RT::SearchBuilder';

    sub Table {'FilterRuleGroups'}

    sub _Init {
        my $self = shift;
        $self->OrderByCols( { FIELD => 'SortOrder', ORDER => 'ASC' } );
        return $self->SUPER::_Init(@_);
    }

    RT::Base->_ImportOverlays();
}

{

=head1 Internal package RT::FilterRule

This package provides the C<RT::FilterRule> class, which describes a filter
rule - the conditions it must meet, the conditions it must I<not> meet, and
the actions to perform on the ticket if the rule matches.

The attributes of this class are:

=over 20

=item B<id>

The numeric ID of this filter rule

=item B<FilterRuleGroup>

The numeric ID of the filter rule group to which this filter rule belongs
(also presented as an C<RT::FilterRuleGroup> object via
B<FilterRuleGroupObj>)

=item B<IsGroupRequirement>

Whether this is a filter rule which describes requirements for the filter
rule group as a whole to be applicable (true), or a filter rule for
processing an event through and performing actions if matched (false).

This is true for requirement rules under a rule group's
B<GroupRequirements>, and false for filter rules under a rule group's
B<FilterRules>.

This attribute is set automatically when a C<RT::FilterRule> object is
created via the B<AddGroupRequirement> and B<AddFilterRule> methods of
C<RT::FilterRuleGroup>.

=item B<SortOrder>

The order of processing - filter rules with a lower sort order are processed
first

=item B<Name>

The displayed name of this filter rule

=item B<TriggerType>

The type of action which triggers this filter rule - one of:

=over 10

=item I<Create>

Consider this rule on ticket creation

=item I<QueueMove>

Consider this rule when the ticket moves between queues

=back

=item B<StopIfMatched>

If this is true, then processing of the remaining rules in this filter rule
group should be skipped if this rule matches (this field is unused for
filter rule group requirement rules, i.e. where B<IsGroupRequirement> is 1)

=item B<Conflicts>

Conditions which, if I<any> are met, mean this rule cannot match; this is
presented as an array of C<RT::FilterRule::Condition> objects, and stored as
a Base64-encoded string encoding an array ref containing hash refs.

=item B<Requirements>

Conditions which, if I<all> are met, mean this rule matches, so long as none
of the conflict conditions above have matched; this is also presented as an
array of C<RT::FilterRule::Condition> objects, and stored in the same way as
above.

=item B<Actions>

Actions to carry out on the ticket if the rule matches (this field is unused
for filter rule group requirement rules, i.e. where B<IsGroupRequirement>
is 1); it is presented as an array of C<RT::FilterRule::Action> objects, and
stored as a Base64-encoded string encoding an array ref containing hash
refs.

=item B<Creator>

The numeric ID of the creator of this filter rule (also presented as an
C<RT::User> object via B<CreatorObj>)

=item B<Created>

The date and time this filter rule was created (also presented as an
C<RT::Date> object via B<CreatedObj>)

=item B<LastUpdatedBy>

The numeric ID of the user who last updated the properties of this filter
rule (also presented as an C<RT::User> object via B<LastUpdatedByObj>)

=item B<LastUpdated>

The date and time this filter rule's properties were last updated (also
presented as an C<RT::Date> object via B<LastUpdatedObj>)

=item B<Disabled>

Whether this filter rule is disabled; the filter rule is active unless this
property is true

=back

=cut

    package RT::FilterRule;
    use base 'RT::Record';

    sub Table {'FilterRules'}

    use RT::Transactions;

    use Storable;
    use MIME::Base64;

=head1 RT::FilterRule METHODS

Note that additional methods will be available, inherited from
C<RT::Record>.

=cut

=head2 Create Name => Name, ...

Create a new filter rule with the supplied properties, as described above. 
The sort order will be set to 1 more than the highest current value so that
the new item appears at the end of the list.

Returns ( I<$id>, I<$message> ), where I<$id> is the ID of the new object,
which will be undefined if there was a problem.

=cut

    sub Create {
        my $self = shift;
        my %args = (
            'FilterRuleGroup'    => 0,
            'IsGroupRequirement' => 0,
            'Name'               => '',
            'TriggerType'        => '',
            'StopIfMatched'      => 0,
            'Conflicts'          => '',
            'Requirements'       => '',
            'Actions'            => '',
            'Disabled'           => 0,
            @_
        );

        # Convert FilterRuleGroup to an ID if an object was passed.
        #
        $args{'FilterRuleGroup'} = $args{'FilterRuleGroup'}->id
            if ( ( ref $args{'FilterRuleGroup'} )
            && UNIVERSAL::isa( $args{'FilterRuleGroup'},
                'RT::FilterRuleGroup' ) );

        foreach my $Attribute ( 'Conflicts', 'Requirements', 'Actions' ) {
            my $Value = $args{$Attribute};
            next if ( not ref $Value );
            my @NewList = map { $_->Properties() } @$Value;
            $Value = '';
            eval {
                $Value
                    = MIME::Base64::encode_base64(
                    Storable::nfreeze( \@NewList ) );
            };
            if ($@) {
                RT->Logger->error(
                    "RT::Extension::FilterRules - failed to serialise RT::FilterRule attribute $Attribute"
                );
            }
            $self->{ '_' . $Attribute } = $args{$Attribute};
            $args{$Attribute} = $Value;
        }

        # Normalise IsGroupRequirement to 1 or 0
        $args{'IsGroupRequirement'} = $args{'IsGroupRequirement'} ? 1 : 0;

        $args{'SortOrder'} = 1;

        $RT::Handle->BeginTransaction();

        my $AllFilterRules = RT::FilterRules->new( $self->CurrentUser );
        $AllFilterRules->UnLimit();

        $AllFilterRules->Limit(
            'FIELD'    => 'FilterRuleGroup',
            'VALUE'    => $args{'FilterRuleGroup'},
            'OPERATOR' => '='
        );
        $AllFilterRules->Limit(
            'FIELD'    => 'IsGroupRequirement',
            'VALUE'    => $args{'IsGroupRequirement'},
            'OPERATOR' => '='
        );
        $AllFilterRules->OrderByCols(
            { FIELD => 'SortOrder', ORDER => 'DESC' } );
        $AllFilterRules->GotoFirstItem();
        my $FinalFilterRule = $AllFilterRules->Next;
        $args{'SortOrder'} = 1 + $FinalFilterRule->SortOrder
            if ($FinalFilterRule);

        my ( $id, $msg ) = $self->SUPER::Create(%args);
        unless ($id) {
            $RT::Handle->Rollback();
            return ( undef, $msg );
        }

        my ( $txn_id, $txn_msg, $txn )
            = $self->_NewTransaction( Type => 'Create' );
        unless ($txn_id) {
            $RT::Handle->Rollback();
            return ( undef, $self->loc( 'Internal error: [_1]', $txn_msg ) );
        }
        $RT::Handle->Commit();

        return ( $id, $self->loc( 'Filter rule [_1] created', $self->id ) );
    }

=head2 FilterRuleGroupObj

Return an C<RT::FilterRuleGroup> object containing this filter rule's filter
rule group.

=cut

    sub FilterRuleGroupObj {
        my ($self) = @_;

        if (   !$self->{'_FilterRuleGroup_obj'}
            || !$self->{'_FilterRuleGroup_obj'}->id )
        {

            $self->{'_FilterRuleGroup_obj'}
                = RT::FilterRuleGroup->new( $self->CurrentUser );
            my ($result)
                = $self->{'_FilterRuleGroup_obj'}
                ->Load( $self->__Value('FilterRuleGroup') );
        }
        return ( $self->{'_FilterRuleGroup_obj'} );
    }

=head2 Conflicts

Return an array of C<RT::FilterRule::Condition> objects describing the
conditions which, if I<any> are met, mean this rule cannot match.

=cut

    sub Conflicts {
        my ($self) = @_;
        if ( not defined $self->{'_Conflicts'} ) {
            my $CurrentValue = [];

            # Thaw the encoded value
            eval {
                $CurrentValue
                    = Storable::thaw(
                    MIME::Base64::decode_base64( $self->_Value('Conflicts') )
                    );
            };
            if ($@) {
                RT->Logger->error(
                    "RT::Extension::FilterRules - failed to deserialise RT::FilterRule attribute Conflicts"
                );
            }

            # Convert the thawed data from hashrefs into objects
            $self->{'_Conflicts'} = [];
            foreach (@$CurrentValue) {
                my $NewObject
                    = RT::FilterRule::Condition->new( $self->CurrentUser,
                    %$_ );
                push @{ $self->{'_Conflicts'} }, $NewObject;
            }
        }
        return @{ $self->{'_Conflicts'} };
    }

=head2 SetConflicts CONDITION, CONDITION, ...

Set the conditions which, if I<any> are met, mean this rule cannot match. 
Expects an array of C<RT::FilterRule::Condition> objects.

=cut

    sub SetConflicts {
        my ( $self, @Conditions ) = @_;

        my @NewList = map { $_->Properties() } @Conditions;
        my $NewValue = '';
        eval {
            $NewValue
                = MIME::Base64::encode_base64(
                Storable::nfreeze( \@NewList ) );
        };

        if ($@) {
            RT->Logger->error(
                "RT::Extension::FilterRules - failed to serialise RT::FilterRule attribute Conflicts"
            );
            return ( 0, $self->loc('Failed to serialise conflicts') );
        }

        $self->{'_Conflicts'} = [@Conditions];
        return $self->_Set(
            'Field' => 'Conflicts',
            'Value' => $NewValue
        );
    }

=head2 DescribeConflicts

Return HTML, localised to the current user, describing the conflict
conditions.  Uses B<DescribeConditions>.

=cut

    sub DescribeConflicts {
        my ($self) = @_;

        my $HTML
            = $self->DescribeConditions( $self->loc('OR'), $self->Conflicts );

        if ( $HTML eq '' ) {
            $HTML = '<em>'
                . $HTML::Mason::Commands::m->interp->apply_escapes(
                $self->loc(
                    'No conflict conditions - rule will match if requirements are met'
                ),
                'h'
                ) . '</em>';
        } else {
            $HTML = $self->loc('Do not match if') . ':<br />' . $HTML;
        }

        return $HTML;
    }

=head2 Requirements

Return an array of C<RT::FilterRule::Condition> objects describing the
conditions which, if I<all> are met, mean this rule matches, so long as none
of the conflict conditions above have matched.

=cut

    sub Requirements {
        my ($self) = @_;
        if ( not defined $self->{'_Requirements'} ) {
            my $CurrentValue = [];

            # Thaw the encoded value
            eval {
                $CurrentValue = Storable::thaw(
                    MIME::Base64::decode_base64(
                        $self->_Value('Requirements')
                    )
                );
            };
            if ($@) {
                RT->Logger->error(
                    "RT::Extension::FilterRules - failed to deserialise RT::FilterRule attribute Requirements"
                );
            }

            # Convert the thawed data from hashrefs into objects
            $self->{'_Requirements'} = [];
            foreach (@$CurrentValue) {
                my $NewObject
                    = RT::FilterRule::Condition->new( $self->CurrentUser,
                    %$_ );
                push @{ $self->{'_Requirements'} }, $NewObject;
            }
        }
        return @{ $self->{'_Requirements'} };
    }

=head2 SetRequirements CONDITION, CONDITION, ...

Set the conditions which, if I<all> are met, mean this rule matches, so long
as none of the conflict conditions above have matched.  Expects an array of
C<RT::FilterRule::Condition> objects.

=cut

    sub SetRequirements {
        my ( $self, @Conditions ) = @_;

        my @NewList = map { $_->Properties() } @Conditions;
        my $NewValue = '';
        eval {
            $NewValue
                = MIME::Base64::encode_base64(
                Storable::nfreeze( \@NewList ) );
        };

        if ($@) {
            RT->Logger->error(
                "RT::Extension::FilterRules - failed to serialise RT::FilterRule attribute Requirements"
            );
            return ( 0, $self->loc('Failed to serialise conflicts') );
        }

        $self->{'_Requirements'} = [@Conditions];
        return $self->_Set(
            'Field' => 'Requirements',
            'Value' => $NewValue
        );
    }

=head2 DescribeRequirements

Return HTML, localised to the current user, describing the requirement
conditions.  Uses B<DescribeConditions>.

=cut

    sub DescribeRequirements {
        my ($self) = @_;

        my $HTML = $self->DescribeConditions( $self->loc('AND'),
            $self->Requirements );

        if ( $HTML eq '' ) {
            $HTML = '<em>'
                . $HTML::Mason::Commands::m->interp->apply_escapes(
                $self->loc(
                    'No requirement conditions - rule will never match'),
                'h'
                ) . '</em>';
        } else {
            $HTML = $self->loc('Match if') . ':<br />' . $HTML;
        }

        return $HTML;
    }

=head2 DescribeConditions AGGREGATOR, CONDITION, ...

Return HTML, localised to the current user, describing the given conditions,
with the given aggregator word (such as "or" or "and") between each one.

This is called by B<DescribeConflicts> and B<DescribeRequirements>.

Uses C<$HTML::Mason::Commands::m>'s B<notes> method for caching, as this is
only expected to be called from user-facing components.

=cut

    sub DescribeConditions {
        my ( $self, $Aggregator, @Conditions ) = @_;

        my $ConditionTypeDetail = $HTML::Mason::Commands::m->notes(
            'FilterRules-ConditionTypeDetail');
        if ( not $ConditionTypeDetail ) {
            $ConditionTypeDetail = {};
            my @ConditionTypes = RT::Extension::FilterRules->ConditionTypes(
                $self->CurrentUser );
            foreach (@ConditionTypes) {
                $ConditionTypeDetail->{ $_->{'ConditionType'} } = {
                    'Name'      => $_->{'Name'},
                    'ValueType' => $_->{'ValueType'}
                };
            }
            $HTML::Mason::Commands::m->notes(
                'FilterRules-ConditionTypeDetail',
                $ConditionTypeDetail );
        }

        my $HTML = '';

        my $CustomFieldObj = RT::CustomField->new( $self->CurrentUser );
        my $GroupObj       = RT::Group->new( $self->CurrentUser );
        my $QueueObj       = RT::Queue->new( $self->CurrentUser );

        foreach my $Condition (@Conditions) {
            $HTML .= '<br /><em>'
                . $HTML::Mason::Commands::m->interp->apply_escapes(
                $Aggregator, 'h' )
                . '</em> '
                if ( $HTML ne '' );
            if ( $Condition->ConditionType =~ /CustomField/ ) {
                if ( $CustomFieldObj->Load( $Condition->CustomField ) ) {
                    $HTML .= '"'
                        . $HTML::Mason::Commands::m->interp->apply_escapes(
                        $CustomFieldObj->Name, 'h' )
                        . '"';
                } else {
                    $HTML .= '"#'
                        . $HTML::Mason::Commands::m->interp->apply_escapes(
                        $Condition->CustomField, 'h' )
                        . '"';
                }
                $HTML .= ' ';
            }
            $HTML .= $HTML::Mason::Commands::m->interp->apply_escapes(
                (   $ConditionTypeDetail->{ $Condition->ConditionType }
                        ->{'Name'} || $Condition->ConditionType
                ),
                'h'
            );

            my @Values = $Condition->Values;

            my $ValueType
                = $ConditionTypeDetail->{ $Condition->ConditionType }
                ->{'ValueType'} || '';

            if ( $ValueType eq 'Queue' ) {
                @Values = map {
                    my $x = $QueueObj->Load($_) ? $QueueObj->Name : '#' . $_;
                    '"'
                        . $HTML::Mason::Commands::m->interp->apply_escapes(
                        $x, 'h' )
                        . '"';
                } @Values;
            } elsif ( $ValueType eq 'Group' ) {
                @Values = map {
                    my $x = $GroupObj->Load($_) ? $GroupObj->Name : '#' . $_;
                    '"'
                        . $HTML::Mason::Commands::m->interp->apply_escapes(
                        $x, 'h' )
                        . '"';
                } @Values;
            } elsif ( $ValueType ne 'None' ) {
                @Values = map {
                    '"'
                        . $HTML::Mason::Commands::m->interp->apply_escapes(
                        $_, 'h' )
                        . '"'
                } @Values;
            }

            if ( scalar @Values > 0 ) {
                $HTML .= ': '
                    . join(
                    ' <em>'
                        . $HTML::Mason::Commands::m->interp->apply_escapes(
                        $self->loc('OR'), 'h' )
                        . '</em> ',
                    @Values
                    );
            }
        }

        return $HTML;
    }

=head2 Actions

Return an array of C<RT::FilterRule::Action> objects describing the actions
to carry out on the ticket if the rule matches.

=cut

    sub Actions {
        my ($self) = @_;
        if ( not defined $self->{'_Actions'} ) {
            my $CurrentValue = [];

            # Thaw the encoded value
            eval {
                $CurrentValue
                    = Storable::thaw(
                    MIME::Base64::decode_base64( $self->_Value('Actions') ) );
            };
            if ($@) {
                RT->Logger->error(
                    "RT::Extension::FilterRules - failed to deserialise RT::FilterRule attribute Actions"
                );
            }

            # Convert the thawed data from hashrefs into objects
            $self->{'_Actions'} = [];
            foreach (@$CurrentValue) {
                my $NewObject
                    = RT::FilterRule::Action->new( $self->CurrentUser, %$_ );
                push @{ $self->{'_Actions'} }, $NewObject;
            }
        }
        return @{ $self->{'_Actions'} };
    }

=head2 SetActions ACTION, ACTION, ...

Set the actions to carry out on the ticket if the rule matches; this field
is unused for filter rule group requirement rules (where
B<IsGroupRequirement> is 1).  Expects an array of C<RT::FilterRule::Action>
objects.

=cut

    sub SetActions {
        my ( $self, @Actions ) = @_;

        my @NewList = map { $_->Properties() } @Actions;
        my $NewValue = '';
        eval {
            $NewValue
                = MIME::Base64::encode_base64(
                Storable::nfreeze( \@NewList ) );
        };

        if ($@) {
            RT->Logger->error(
                "RT::Extension::FilterRules - failed to serialise RT::FilterRule attribute Actions"
            );
            return ( 0, $self->loc('Failed to serialise conflicts') );
        }

        $self->{'_Actions'} = [@Actions];
        return $self->_Set(
            'Field' => 'Actions',
            'Value' => $NewValue
        );
    }

=head2 DescribeActions

Return HTML, localised to the current user, describing this filter rule's
actions.

Uses C<$HTML::Mason::Commands::m>'s B<notes> method for caching, as this is
only expected to be called from user-facing components.

=cut

    sub DescribeActions {
        my ($self) = @_;

        my $ActionTypeDetail = $HTML::Mason::Commands::m->notes(
            'FilterRules-ActionTypeDetail');
        if ( not $ActionTypeDetail ) {
            $ActionTypeDetail = {};
            my @ActionTypes = RT::Extension::FilterRules->ActionTypes(
                $self->CurrentUser );
            foreach (@ActionTypes) {
                $ActionTypeDetail->{ $_->{'ActionType'} } = {
                    'Name'      => $_->{'Name'},
                    'ValueType' => $_->{'ValueType'}
                };
            }
            $HTML::Mason::Commands::m->notes( 'FilterRules-ActionTypeDetail',
                $ActionTypeDetail );
        }

        my $HTML = '';

        my $CustomFieldObj = RT::CustomField->new( $self->CurrentUser );
        my $GroupObj       = RT::Group->new( $self->CurrentUser );
        my $QueueObj       = RT::Queue->new( $self->CurrentUser );

        foreach my $Action ( $self->Actions ) {
            $HTML .= '<li>'
                . $HTML::Mason::Commands::m->interp->apply_escapes(
                (   $ActionTypeDetail->{ $Action->ActionType }->{'Name'}
                        || $Action->ActionType
                ),
                'h'
                );

            if ( $Action->ActionType =~ /CustomField/ ) {
                $HTML .= ' ';
                if ( $CustomFieldObj->Load( $Action->CustomField ) ) {
                    $HTML .= '"'
                        . $HTML::Mason::Commands::m->interp->apply_escapes(
                        $CustomFieldObj->Name, 'h' )
                        . '"';
                } else {
                    $HTML .= '"#'
                        . $HTML::Mason::Commands::m->interp->apply_escapes(
                        $Action->CustomField, 'h' )
                        . '"';
                }
                $HTML .= ' ';
            }

            my $ValueType
                = $ActionTypeDetail->{ $Action->ActionType }->{'ValueType'}
                || '';

            if ( $ValueType eq 'Queue' ) {
                $HTML .= ': ';
                if ( $QueueObj->Load( $Action->Value ) ) {
                    $HTML .= '"'
                        . $HTML::Mason::Commands::m->interp->apply_escapes(
                        $QueueObj->Name, 'h' )
                        . '"';
                } else {
                    $HTML .= '"#'
                        . $HTML::Mason::Commands::m->interp->apply_escapes(
                        $Action->Value, 'h' )
                        . '"';
                }
            } elsif ( $ValueType eq 'Group' ) {
                $HTML .= ': ';
                if ( $GroupObj->Load( $Action->Value ) ) {
                    $HTML .= '"'
                        . $HTML::Mason::Commands::m->interp->apply_escapes(
                        $GroupObj->Name, 'h' )
                        . '"';
                } else {
                    $HTML .= '"#'
                        . $HTML::Mason::Commands::m->interp->apply_escapes(
                        $Action->Value, 'h' )
                        . '"';
                }
            } elsif ( $ValueType eq 'CustomField' ) {
                $HTML .= ': ';
                if ( $CustomFieldObj->Load( $Action->Value ) ) {
                    $HTML .= '"'
                        . $HTML::Mason::Commands::m->interp->apply_escapes(
                        $CustomFieldObj->Name, 'h' )
                        . '"';
                } else {
                    $HTML .= '"#'
                        . $HTML::Mason::Commands::m->interp->apply_escapes(
                        $Action->Value, 'h' )
                        . '"';
                }
            } elsif ( $ValueType !~ /^(None|HTML)$/ ) {
                $HTML .= ': "'
                    . $HTML::Mason::Commands::m->interp->apply_escapes(
                    $Action->Value, 'h' )
                    . '"';
            }

            if ( $Action->IsNotification ) {
                if ( $Action->ActionType =~ /Group/ ) {
                    $HTML .= ' &rarr; ';
                    if ( $GroupObj->Load( $Action->Notify ) ) {
                        $HTML .= '"'
                            . $HTML::Mason::Commands::m->interp
                            ->apply_escapes( $GroupObj->Name, 'h' ) . '"';
                    } else {
                        $HTML .= '"#'
                            . $HTML::Mason::Commands::m->interp
                            ->apply_escapes( $Action->Notify, 'h' ) . '"';
                    }
                } else {
                    $HTML .= ': "'
                        . $HTML::Mason::Commands::m->interp->apply_escapes(
                        $Action->Notify, 'h' )
                        . '"';
                }
            }

            $HTML .= "</li>\n";
        }

        if ( $HTML eq '' ) {
            $HTML = '<em>'
                . $HTML::Mason::Commands::m->interp->apply_escapes(
                $self->loc('No actions defined'), 'h' )
                . '</em>';
        } else {
            $HTML = '<ul>' . $HTML . '</ul>';
        }

        return $HTML;
    }

=head2 Delete

Delete this filter rule, and all of its history.  Returns ( I<$ok>,
I<$message> ).

=cut

    sub Delete {
        my ($self) = @_;
        my ( $Collection, $Item );

        # Delete the filter rule match history.
        #
        $Collection = $self->MatchHistory();
        $Collection->GotoFirstItem();
        while ( $Item = $Collection->Next ) {
            $Item->Delete();
        }

        # Delete the transactions.
        #
        $Collection = $self->Transactions();
        $Collection->GotoFirstItem();
        while ( $Item = $Collection->Next ) {
            $Item->Delete();
        }

        # Delete this object itself.
        #
        return $self->SUPER::Delete();
    }

=head2 MatchHistory

Return an C<RT::FilterRuleMatches> collection containing all of the times
this filter rule matched an event.

=cut

    sub MatchHistory {
        my ($self) = @_;
        my $Collection = RT::FilterRuleMatches->new( $self->CurrentUser );
        $Collection->UnLimit();
        $Collection->Limit(
            'FIELD'    => 'FilterRule',
            'VALUE'    => $self->id,
            'OPERATOR' => '='
        );
        return $Collection;
    }

=head2 TestRule RuleChecks => [], Actions => [], TriggerType => TYPE, From => FROM, To => TO, DescribeAll => 0

Test the event described in the parameters against the conditions in this
filter rule, returning ( I<$Matched>, I<$Message>, I<$EventValue>,
I<$TargetValue> ), where I<$Matched> is true if the rule matched,
I<$Message> describes the match, I<$EventValue> is the value from the event
that led to the result, and I<$TargetValue> is the value the event was
checked against which let to the result.

Details of this rule and the checked conditions will be appended to the
I<RuleChecks> array reference, and the actions this rule contains will be
appended to the I<Actions> array reference.

The I<TriggerType> should be one of the valid I<TriggerType> attribute
values listed above in the C<RT::FilterRule> class attributes documentation.

For a I<TriggerType> of B<Create>, indicating a ticket creation event, the
I<To> parameter should be the ID of the queue the ticket was created in.

For a I<TriggerType> of B<QueueMove>, indicating a ticket moving from one
queue to another, the I<From> parameter should be the ID of the queue the
ticket was in before the move, and the I<To> parameter should be the ID of
the queue the ticket moved into.

If I<DescribeAll> is true, then all conditions for this filter rule will be
added to I<RuleChecks> regardless of whether they influenced the outcome;
this can be used to present the operator with details of how an event would
be processed.

For instance, when I<DescribeAll> is false, if the rule did not match
because of a conflict condition, then only the conflict conditions up to and
including the first match will be included.

A I<Cache> should be provided, pointing to a hash reference shared with
other calls to this method for the same event.

One entry will be added to the I<RuleChecks> array reference, consisting of
a hash reference with these keys:

=over 12

=item B<Matched>

Whether the whole rule matched

=item B<Message>

Description associated with the whole rule match status

=item B<EventValue>

The value from the event which led to the whole rule match status

=item B<TargetValue>

The value, in the final condition which led to the whole rule match status,
which was tested against the I<EventValue>

=item B<FilterRule>

This C<RT::FilterRule> object

=item B<MatchType>

The type of condition which caused this rule to match - blank if the rule
did not match, or either C<Conflict> or C<Requirement> (see the
I<Conditions> B<MatchType> description beolow)

=item B<Conflicts>

An array reference containing one entry for each condition checked from this
filter rule's B<Conflicts>, each of which is a hash reference of condition
checks as described below.

=item B<Requirements>

An array reference containing one entry for each condition checked from this
filter rule's B<Requirements>, each of which is a hash reference of
condition checks as described below.

=back

The conditions check hash reference provided in each entry of the
I<Conflicts> and I<Requirements> array references contain the following
keys:

=over 11

=item B<Condition>

The C<RT::FilterRule::Condition> object describing this condition

=item B<Matched>

Whether this condition matched (see the note about I<DescribeAll> above)

=item B<Checks>

An array reference containing one entry for each value checked in the
condition (since conditions can have multiple OR values), stopping at the
first match unless I<DescribeAll> is true; each entry is a hash reference
containing the following keys:

=over 13

=item B<Matched>

Whether this check succeeded

=item B<Message>

Description associated with this check's match status

=item B<EventValue>

The value from the event which led to this check's match status

=item B<TargetValue>

The target value that the event was checked against

=back

=back

Each entry added to the I<Actions> array reference will be a hash reference
with these keys:

=over 11

=item B<FilterRule>

This C<RT::FilterRule> object

=item B<Action>

The C<RT::FilterRule::Action> object describing this action

=back

=cut

    sub TestRule {
        my $self = shift;
        my %args = (
            'RuleChecks'  => [],
            'Actions'     => [],
            'TriggerType' => '',
            'From'        => 0,
            'To'          => 0,
            'Ticket'      => undef,
            'DescribeAll' => 0,
            'Cache'       => {},
            @_
        );

        my %TestConditionParameters = (
            map { $_, $args{$_} } (
                'TriggerType', 'From', 'To', 'Ticket',
                'Cache',       'DescribeAll'
            )
        );

        my $RuleCheck = {
            'Matched'      => 0,
            'Message'      => '',
            'EventValue'   => '',
            'TargetValue'  => '',
            'FilterRule'   => $self,
            'MatchType'    => '',
            'Conflicts'    => [],
            'Requirements' => []
        };

        # Check whether any conflict conditions are met, in which case this
        # rule will not match.
        #
        my $ConflictFound = 0;
        foreach my $Condition ( $self->Conflicts ) {
            my $ConditionCheck = {
                'Condition' => $Condition,
                'Matched'   => 0,
                'Checks'    => []
            };

            my ( $Matched, $Message, $EventValue, $TargetValue )
                = $Condition->TestCondition( %TestConditionParameters,
                'Checks' => $ConditionCheck->{'Checks'} );
            $ConditionCheck->{'Matched'} = $Matched;
            push @{ $RuleCheck->{'Conflicts'} }, $ConditionCheck;

            if ( $Matched && not $ConflictFound ) {
                $ConflictFound              = 1;
                $RuleCheck->{'Message'}     = $Message;
                $RuleCheck->{'EventValue'}  = $EventValue;
                $RuleCheck->{'TargetValue'} = $TargetValue;
                $RuleCheck->{'MatchType'}   = 'Conflict';
                last if ( not $args{'DescribeAll'} );
            }
        }

        # If no conflicts were found, check that all requirement conditions
        # are met, in which case the rule matches.
        #
        if ( not $ConflictFound ) {
            my $MatchFound  = 0;
            my $MatchFailed = 0;

            foreach my $Condition ( $self->Requirements ) {
                my $ConditionCheck = {
                    'Condition' => $Condition,
                    'Matched'   => 0,
                    'Checks'    => []
                };

                my ( $Matched, $Message, $EventValue, $TargetValue )
                    = $Condition->TestCondition( %TestConditionParameters,
                    'Checks' => $ConditionCheck->{'Checks'} );
                $ConditionCheck->{'Matched'} = $Matched;
                push @{ $RuleCheck->{'Requirements'} }, $ConditionCheck;

                if ($Matched) {
                    $MatchFound = 1;
                } elsif ( not $MatchFailed ) {
                    $MatchFailed                = 1;
                    $RuleCheck->{'Message'}     = $Message;
                    $RuleCheck->{'EventValue'}  = $EventValue;
                    $RuleCheck->{'TargetValue'} = $TargetValue;
                    $RuleCheck->{'MatchType'}   = 'Requirement';
                    last if ( not $args{'DescribeAll'} );
                }
            }

            # The rule only matches if there were no failures and we did
            # find at least one matching conditionl, so any empty
            # requirements list means no match.
            #
            if ( $MatchFailed == 0 && $MatchFound ) {
                $RuleCheck->{'Matched'} = 1;
                $RuleCheck->{'Message'} = $self->loc('All requirements met');
                $RuleCheck->{'MatchType'} = 'Requirement';
            } elsif ( $MatchFailed == 0 && $MatchFound == 0 ) {
                $RuleCheck->{'Message'}
                    = $self->loc('No requirements defined');
                $RuleCheck->{'MatchType'} = 'Requirement';
            }
        }

        push @{ $args{'RuleChecks'} }, $RuleCheck;

        # If the rule matched, add its actions.
        #
        if ( $RuleCheck->{'Matched'} ) {
            foreach my $Action ( $self->Actions ) {
                push @{ $args{'Actions'} },
                    { 'FilterRule' => $self, 'Action' => $Action };
            }
        }

        return (
            $RuleCheck->{'Matched'},    $RuleCheck->{'Message'},
            $RuleCheck->{'EventValue'}, $RuleCheck->{'TargetValue'}
        );
    }

=head2 RecordMatch Ticket => ID

Record the fact that an event relating to the given ticket matched this
filter rule.

=cut

    sub RecordMatch {
        my $self = shift;
        my %args = ( 'Ticket' => 0, @_ );

        my $MatchObj = RT::FilterRuleMatch->new( $self->CurrentUser );

        return $MatchObj->Create(
            'FilterRule' => $self->id,
            'Ticket'     => $args{'Ticket'}
        );
    }

=head2 MatchCount HOURS

Return the number of times this rule has matched in the past I<HOURS> hours,
or the number of times it has ever matched if I<HOURS> is zero.

=cut

    sub MatchCount {
        my ( $self, $Hours ) = @_;
        my $Collection = RT::FilterRuleMatches->new( $self->CurrentUser );
        $Collection->UnLimit();
        $Collection->Limit(
            'FIELD'    => 'FilterRule',
            'VALUE'    => $self->id,
            'OPERATOR' => '='
        );
        if ($Hours) {
            my $LimitDate = RT::Date->new( $self->CurrentUser );
            $LimitDate->SetToNow();
            $LimitDate->AddSeconds( -3600 * $Hours );
            $Collection->Limit(
                'FIELD'    => 'Created',
                'VALUE'    => $LimitDate->ISO,
                'OPERATOR' => '>'
            );
        }
        return $Collection->CountAll;
    }

=head2 MoveUp

Move this filter rule up in the sort order so it is processed earlier. 
Returns ( I<$ok>, I<$message> ).

=cut

    sub MoveUp {
        my $self = shift;
        return $self->Move(-1);
    }

=head2 MoveDown

Move this filter rule down in the sort order so it is processed later. 
Returns ( I<$ok>, I<$message> ).

=cut

    sub MoveDown {
        my $self = shift;
        return $self->Move(1);
    }

=head2 Move OFFSET

Change this filter rule's sort order by the given I<OFFSET>.

=cut

    sub Move {
        my ( $self, $Offset ) = @_;

        return ( 1, $self->loc('Not moved') ) if ( $Offset == 0 );

        my $Collection = RT::FilterRules->new( $self->CurrentUser );
        $Collection->UnLimit();
        $Collection->Limit(
            'FIELD'    => 'FilterRuleGroup',
            'VALUE'    => $self->FilterRuleGroup,
            'OPERATOR' => '='
        );
        $Collection->Limit(
            'FIELD'    => 'IsGroupRequirement',
            'VALUE'    => $self->IsGroupRequirement,
            'OPERATOR' => '='
        );
        $Collection->FindAllRows();
        $Collection->OrderByCols( { FIELD => 'SortOrder', ORDER => 'ASC' } );
        $Collection->GotoFirstItem();
        my @CollectionOrder = ();

        while ( my $Item = $Collection->Next ) {
            push @CollectionOrder, { 'Object' => $Item, 'id' => $Item->id };
        }

        my $SelfId          = $self->id;
        my $CurrentPosition = -1;
        for ( my $Index = 0; $Index <= $#CollectionOrder; $Index++ ) {
            next if ( $CollectionOrder[$Index]->{'id'} != $SelfId );
            $CurrentPosition = $Index;
        }
        return ( 0, $self->loc('Failed to find current position') )
            if ( $CurrentPosition < 0 );

        my $NewPosition = $CurrentPosition + $Offset;
        if ( $NewPosition < 0 ) {
            return ( 0,
                $self->loc("Can not move up. It's already at the top") );
        } elsif ( $NewPosition > $#CollectionOrder ) {
            return ( 0,
                $self->loc("Can not move down. It's already at the bottom") );
        }

        my $Swap = $CollectionOrder[$CurrentPosition];
        $CollectionOrder[$CurrentPosition] = $CollectionOrder[$NewPosition];
        $CollectionOrder[$NewPosition]     = $Swap;

        for ( my $Index = 0; $Index <= $#CollectionOrder; $Index++ ) {
            $CollectionOrder[$Index]->{'Object'}->SetSortOrder( 1 + $Index );
        }

        return ( 1, $self->loc('Moved') );
    }

=head2 _Set Field => FIELD, Value => VALUE

Set the value of a field, recording a transaction in the process if
appropriate.  Returns ( I<$ok>, I<$message> ).

=cut

    sub _Set {
        my $self = shift;
        my %args = (
            'Field' => '',
            'Value' => '',
            @_
        );

        my $OldValue = $self->__Value( $args{'Field'} );
        return ( 1, '' )
            if ( ( defined $OldValue )
            && ( defined $args{'Value'} )
            && ( $OldValue eq $args{'Value'} ) );

        $RT::Handle->BeginTransaction();

        my ( $ok, $msg ) = $self->SUPER::_Set(%args);

        if ( not $ok ) {
            $RT::Handle->Rollback();
            return ( $ok, $msg );
        }

        # Don't record a transaction for sort order changes, since they are
        # very frequent.
        #
        # For Conflicts, Requirements, Actions, we don't record the old and
        # new values, just the fact that they changed.
        #
        if ( ( $args{'Field'} || '' ) eq 'Disabled' ) {
            my ( $txn_id, $txn_msg, $txn )
                = $self->_NewTransaction(
                Type => $args{'Value'} ? 'Disabled' : 'Enabled' );
            if ( not $txn_id ) {
                $RT::Handle->Rollback();
                return ( 0, $self->loc( 'Internal error: [_1]', $txn_msg ) );
            }
        } elsif ( ( $args{'Field'} || '' ) ne 'SortOrder' ) {
            my ( $RecordNew, $RecordOld ) = ( $args{'Value'}, $OldValue );
            if ( ( $args{'Field'} || '' )
                =~ /^(Conflicts|Requirements|Actions)$/ )
            {
                ( $RecordNew, $RecordOld ) = ( '(new)', '(old)' );
            }
            my ( $txn_id, $txn_msg, $txn ) = $self->_NewTransaction(
                'Type'     => 'Set',
                'Field'    => $args{'Field'},
                'NewValue' => $RecordNew,
                'OldValue' => $RecordOld
            );
            if ( not $txn_id ) {
                $RT::Handle->Rollback();
                return ( 0, $self->loc( 'Internal error: [_1]', $txn_msg ) );
            }
        }

        $RT::Handle->Commit();

        return ( $ok, $msg );
    }

=head2 CurrentUserCanSee

Return true if the current user has permission to see this object.

=cut

    sub CurrentUserCanSee {
        my $self = shift;
        return 1
            if (
            $self->FilterRuleGroupObj->CurrentUserHasRight('SuperUser') );
        return 1
            if (
            $self->FilterRuleGroupObj->CurrentUserHasRight('SeeFilterRule') );
        return 1
            if (
            $self->FilterRuleGroupObj->CurrentUserHasRight(
                'ModifyFilterRule')
               );
        return 1
            if (
            $self->FilterRuleGroupObj->CurrentUserHasRight(
                'CreateFilterRule')
               );
        return 1
            if (
            $self->FilterRuleGroupObj->CurrentUserHasRight(
                'DeleteFilterRule')
               );
        return 0;
    }

=head2 _CoreAccessible

Return a hashref describing the attributes of the database table for the
C<RT::FilterRule> class.

=cut

    sub _CoreAccessible {
        return {

            'id' => {
                read       => 1,
                sql_type   => 4,
                length     => 11,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'int(11)',
                default    => ''
            },

            'FilterRuleGroup' => {
                read       => 1,
                write      => 1,
                sql_type   => 4,
                length     => 11,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'int(11)',
                default    => '0'
            },

            'IsGroupRequirement' => {
                read       => 1,
                write      => 1,
                sql_type   => 5,
                length     => 6,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'smallint(6)',
                default    => '0'
            },

            'SortOrder' => {
                read       => 1,
                write      => 1,
                sql_type   => 4,
                length     => 11,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'int(11)',
                default    => '0'
            },

            'Name' => {
                read       => 1,
                write      => 1,
                sql_type   => 12,
                length     => 200,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'varchar(200)',
                default    => ''
            },

            'TriggerType' => {
                read       => 1,
                write      => 1,
                sql_type   => 12,
                length     => 200,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'varchar(200)',
                default    => ''
            },

            'StopIfMatched' => {
                read       => 1,
                write      => 1,
                sql_type   => 5,
                length     => 6,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'smallint(6)',
                default    => '0'
            },

            'Conflicts' => {
                read       => 1,
                write      => 1,
                sql_type   => -4,
                length     => 0,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'text',
                default    => ''
            },

            'Requirements' => {
                read       => 1,
                write      => 1,
                sql_type   => -4,
                length     => 0,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'text',
                default    => ''
            },

            'Actions' => {
                read       => 1,
                write      => 1,
                sql_type   => -4,
                length     => 0,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'text',
                default    => ''
            },

            'Creator' => {
                read       => 1,
                auto       => 1,
                sql_type   => 4,
                length     => 11,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'int(11)',
                default    => '0'
            },

            'Created' => {
                read       => 1,
                auto       => 1,
                sql_type   => 11,
                length     => 0,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'datetime',
                default    => ''
            },

            'LastUpdatedBy' => {
                read       => 1,
                auto       => 1,
                sql_type   => 4,
                length     => 11,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'int(11)',
                default    => '0'
            },

            'LastUpdated' => {
                read       => 1,
                auto       => 1,
                sql_type   => 11,
                length     => 0,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'datetime',
                default    => ''
            },

            'Disabled' => {
                read       => 1,
                write      => 1,
                sql_type   => 5,
                length     => 6,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'smallint(6)',
                default    => '0'
            }
        };
    }

    RT::Base->_ImportOverlays();
}

{

=head1 Internal package RT::FilterRule::Condition

This package provides the C<RT::FilterRule::Condition> class, which
describes a condition in a filter rule and provides methods to match an
event on a ticket against that condition.

Objects of this class are not stored directly in the database, but are
encoded within attributes of C<RT::FilterRule> objects.

=cut

    package RT::FilterRule::Condition;

    use base 'RT::Base';

    use Email::Address;
    use HTML::FormatText;

=head1 RT::FilterRule::Condition METHODS

This class inherits from C<RT::Base>.

=cut

=head2 new $UserObj[, PARAMS...]

Construct and return a new object, given an C<RT::CurrentUser> object.  Any
other parameters are passed to B<Set> below.

=cut

    sub new {
        my ( $proto, $UserObj, @args ) = @_;
        my ( $class, $self );

        $class = ref($proto) || $proto;

        $self = {
            'ConditionType' => 'All',
            'CustomField'   => 0,
            'Values'        => [],
            'TriggerType'   => 'Unspecified',
            'From'          => 0,
            'To'            => 0,
            'Ticket'        => undef,
            'Cache'         => {},
        };

        bless( $self, $class );

        $self->CurrentUser($UserObj);

        $self->Set(@args);

        return $self;
    }

=head2 Set Key => VALUE, ...

Set parameters of this condition object.  The following parameters define
the condition itself:

=over 15

=item B<ConditionType>

The type of condition, such as I<InQueue>, I<FromQueue>, I<SubjectContains>,
and so on - see the C<RT::Extension::FilterRules> method B<ConditionTypes>.

=item B<CustomField>

The custom field ID associated with this condition, if applicable

=item B<Values>

Array reference containing the list of values to match against, any one of
which will mean this condition has matched

=back

The following parameters define the event being matched against:

=over 

=item B<TriggerType>

The action which triggered this check, such as I<Create> or I<QueueMove>

=item B<From>

The value the ticket is changing from

=item B<To>

The value the ticket is changing to (the same as I<From> on ticket creation)

=item B<Ticket>

The C<RT::Ticket> object to match the condition against

=back

Finally, B<Cache> should be set to a hash reference, which should be
shared across all B<Test> or B<TestSingleValue> calls for this event;
lookups such as ticket subject, custom field ID to name mappings, and so on,
will be cached here so that they don't have to be done multiple times.

This method returns nothing.

=cut

    sub Set {
        my ( $self, %args ) = @_;

        foreach (
            'ConditionType', 'CustomField', 'Values', 'TriggerType',
            'From',          'To',          'Ticket', 'Cache'
            )
        {
            $self->{$_} = $args{$_} if ( exists $args{$_} );
        }

        return 1;
    }

=head2 TestCondition [PARAMS, Checks => ARRAYREF, DescribeAll => 1]

Test the event described in the parameters against this condition, returning
( I<$Matched>, I<$Message>, I<$EventValue>, I<$TargetValue> ), where
I<$Matched> is true if the condition matched, I<$Message> describes the
match, I<$EventValue> is the value from the event that led to the result,
and I<$TargetValue> is the value the event was checked against which let to
the result.

Appends details of the checks performed to the I<Checks> array reference,
where each addition is a hash reference of I<Matched>, I<Message>,
I<EventValue>, I<TargetValue>, as described above and in the
C<RT::FilterRule> B<TestRule> method.

If additional parameters are supplied, they are run through B<Set> above
before the test is performed.

The I<DescribeAll> parameter, and the contents of the I<Checks> array
reference, are described in the documentation of the C<RT::FilterRule>
B<TestRule> method.

=cut

    sub TestCondition {
        my $self         = shift;
        my %args         = ( 'Checks' => [], 'DescribeAll' => 0, @_ );
        my @TargetValues = ();

        $self->Set(%args);

        my ( $Matched, $Message, $FinalEventValue, $FinalTargetValue )
            = ( 0, undef, '', '' );
        @TargetValues = $self->Values;
        push @TargetValues, '' if ( scalar @TargetValues == 0 );

        foreach my $TargetValue (@TargetValues) {
            my ( $ValMatched, $ValMessage, $EventValue )
                = $self->TestSingleValue( 'TargetValue' => $TargetValue );
            $Message = $ValMessage if ( not defined $Message );
            push @{ $args{'Checks'} },
                {
                'Matched'     => $ValMatched,
                'Message'     => $ValMessage,
                'EventValue'  => $EventValue,
                'TargetValue' => $TargetValue
                };
            if ( $ValMatched && not $Matched ) {
                $Matched          = $ValMatched;
                $Message          = $ValMessage;
                $FinalEventValue  = $EventValue;
                $FinalTargetValue = $TargetValue;
                last if ( not $args{'DescribeAll'} );
            }
        }

        $Message = $self->loc('No match') if ( not defined $Message );

        return ( $Matched, $Message, $FinalEventValue, $FinalTargetValue );
    }

=head2 TestSingleValue PARAMS, TargetValue => VALUE

Test the event described in the parameters against this condition, returning
( I<$matched>, I<$message>, I<$eventvalue> ), where only the specific
I<VALUE> is tested against the event's I<From>/I<To>/I<Ticket> - the
specific event value tested against is returned in I<$eventvalue>.

This is called internally by the B<Test> method for each of the value checks
in the condition.

=cut

    sub TestSingleValue {
        my $self = shift;
        my %args = ( 'TargetValue' => '', @_ );

        $self->Set(%args);

        # Map condition types to their definitions.
        #
        if ( not $self->{'Cache'}->{'ConditionTypes'} ) {
            $self->{'Cache'}->{'ConditionTypes'} = {
                map { $_->{'ConditionType'}, $_ }
                    RT::Extension::FilterRules->ConditionTypes(
                    $self->CurrentUser
                    )
            };
        }

        my ( $Matched, $Message, $EventValue ) = ( 0, '', '' );

        my $Method = '_' . $self->ConditionType;
        if ( $self->can($Method) ) {
            ( $Matched, $Message, $EventValue )
                = $self->$Method( 'TargetValue' => $args{'TargetValue'} );
        } elsif (
            defined $self->{'Cache'}->{'ConditionTypes'}
            ->{ $self->ConditionType }->{'Function'} )
        {
            ( $Matched, $Message, $EventValue )
                = $self->{'Cache'}->{'ConditionTypes'}
                ->{ $self->ConditionType }->{'Function'}
                ->( $self->CurrentUser, %$self );
        } else {
            $Message = $self->loc( 'Undefined condition type: [_1]',
                $self->ConditionType );
            RT->Logger->error(
                "RT::Extension::FilterRules - undefined condition type: "
                    . $self->ConditionType );
        }

        return ( $Matched, $Message, $EventValue );
    }

=head2 Properties

Return the properties of this object as a hash reference, suitable for
serialising and storing.

=cut

    sub Properties {
        my $self = shift;
        return {
            'ConditionType' => $self->{'ConditionType'},
            'CustomField'   => $self->{'CustomField'},
            'Values'        => $self->{'Values'}
        };
    }

=head2 ConditionType

Return the condition type.

=cut

    sub ConditionType { return $_[0]->{'ConditionType'}; }

=head2 CustomField

Return the custom field ID associated with this condition.

=cut

    sub CustomField { return $_[0]->{'CustomField'}; }

=head2 Values

Return the value array associated with this condition.

=cut

    sub Values { return @{ $_[0]->{'Values'} || [] }; }

=head2 TriggerType

Return the trigger type of the event being tested against this condition.

=cut

    sub TriggerType { return $_[0]->{'TriggerType'}; }

=head2 From

Return the moving-from value of the event being tested against this
condition.

=cut

    sub From { return $_[0]->{'From'}; }

=head2 To

Return the moving-to value of the event being tested against this condition.

=cut

    sub To { return $_[0]->{'To'}; }

=head2 TicketQueue

Return the ticket queue ID associated with the ticket being tested, caching
it locally.

=cut

    sub TicketQueue {
        my $self = shift;
        return '' if ( not $self->{'Ticket'} );
        $self->{'Cache'}->{'TicketQueue'} = $self->{'Ticket'}->Queue
            if ( not exists $self->{'Cache'}->{'TicketQueue'} );
        return $self->{'Cache'}->{'TicketQueue'};
    }

=head2 TicketSubject

Return the ticket subject associated with the event being tested, caching it
locally.

=cut

    sub TicketSubject {
        my $self = shift;
        return '' if ( not $self->{'Ticket'} );
        $self->{'Cache'}->{'TicketSubject'} = $self->{'Ticket'}->Subject
            if ( not exists $self->{'Cache'}->{'TicketSubject'} );
        return $self->{'Cache'}->{'TicketSubject'};
    }

=head2 TicketPriority

Return the priority of the ticket associated with the event being tested,
caching it locally.

=cut

    sub TicketPriority {
        my $self = shift;
        return 0 if ( not $self->{'Ticket'} );
        $self->{'Cache'}->{'TicketPriority'} = $self->{'Ticket'}->Priority
            if ( not exists $self->{'Cache'}->{'TicketPriority'} );
        return $self->{'Cache'}->{'TicketPriority'};
    }

=head2 TicketStatus

Return the status of the ticket associated with the event being tested,
caching it locally.

=cut

    sub TicketStatus {
        my $self = shift;
        return 0 if ( not $self->{'Ticket'} );
        $self->{'Cache'}->{'TicketStatus'} = $self->{'Ticket'}->Status
            if ( not exists $self->{'Cache'}->{'TicketStatus'} );
        return $self->{'Cache'}->{'TicketStatus'};
    }

=head2 TicketCustomFieldValue CUSTOMFIELDID

Return the value of the custom field with the given ID attached to the
ticket associated with the event being tested, caching it locally.

=cut

    sub TicketCustomFieldValue {
        my ( $self, $CustomFieldId ) = @_;

        return '' if ( not $self->{'Ticket'} );
        return '' if ( not $CustomFieldId );
        my $CacheKey = 'TicketCustomFieldValue-' . $CustomFieldId;

        if ( not exists $self->{'Cache'}->{$CacheKey} ) {
            $self->{'Cache'}->{$CacheKey}
                = $self->{'Ticket'}->FirstCustomFieldValue($CustomFieldId);
            $self->{'Cache'}->{$CacheKey} = ''
                if ( not defined $self->{'Cache'}->{$CacheKey} );
        }

        return $self->{'Cache'}->{$CacheKey};
    }

=head2 TicketRequestorEmailAddresses

Return an array of the requestor email addresses of the event's ticket,
caching it locally.

=cut

    sub TicketRequestorEmailAddresses {
        my $self = shift;
        return () if ( not $self->{'Ticket'} );
        $self->{'Cache'}->{'TicketRequestorEmailAddresses'}
            = [ $self->{'Ticket'}->Requestors->MemberEmailAddresses ]
            if (
            not exists $self->{'Cache'}->{'TicketRequestorEmailAddresses'} );
        return @{ $self->{'Cache'}->{'TicketRequestorEmailAddresses'} };
    }

=head2 TicketRecipientEmailAddresses

Return an array of the recipient email addresses of the event's ticket,
caching it locally.

=cut

    sub TicketRecipientEmailAddresses {
        my $self = shift;

        return () if ( not $self->{'Ticket'} );

        if ( not exists $self->{'Cache'}->{'TicketRecipientEmailAddresses'} )
        {
            my ($Transactions, $FirstTransaction, $Attachments,
                $FirstMessage, $Addresses
               ) = ( undef, undef, undef, undef, undef );

            $Transactions = $self->{'Ticket'}->Transactions;
            $FirstTransaction = $Transactions->Next if ($Transactions);
            $Attachments = $FirstTransaction->Message if ($FirstTransaction);
            $FirstMessage = $Attachments->Next if ($Attachments);

            # NB we cannot use $FirstMessage->Addresses because it comes up
            # empty in RT 4.2.16.
            #

            $Addresses = {};
            if ($FirstMessage) {
                foreach ( grep {/^(From|To|Cc):/i}
                    $FirstMessage->SplitHeaders )
                {
                    next if ( !s/^(From|To|Cc):// );
                    $Addresses->{ ucfirst( lc($1) ) }
                        = [ Email::Address->parse($_) ];
                }
            }

            $Addresses = {} if ( not defined $Addresses );
            $self->{'Cache'}->{''} = [];
            foreach ( 'To', 'Cc' ) {
                foreach ( @{ $Addresses->{$_} || [] } ) {
                    push @{ $self->{'Cache'}
                            ->{'TicketRecipientEmailAddresses'} }, $_->address
                        if ( defined $_ );
                }
            }
        }

        return @{ $self->{'Cache'}->{'TicketRecipientEmailAddresses'} };
    }

=head2 TicketFirstCommentText

Return the first comment of the event's tickets, in text, caching it
locally.  If the first comment is in HTML, it is converted to plain text.

=cut

    sub TicketFirstCommentText {
        my $self = shift;

        return '' if ( not $self->{'Ticket'} );

        if ( not exists $self->{'Cache'}->{'TicketFirstCommentText'} ) {

            $self->{'Cache'}->{'TicketFirstCommentText'} = '';

            my $Transactions     = $self->{'Ticket'}->Transactions;
            my $FirstTransaction = undef;

            if ($Transactions) {
                $Transactions->OrderByCols(
                    { 'FIELD' => 'Created', 'ORDER' => 'ASC' },
                    { 'FIELD' => 'id',      'ORDER' => 'ASC' }
                );
                $Transactions->RowsPerPage(1);
                $FirstTransaction = $Transactions->Next;
            }

            if ( defined $FirstTransaction ) {
                my $FirstComment
                    = $FirstTransaction->Content( 'Type' => 'text/html' )
                    || '';
                $FirstComment =~ s/^<pre>//is;
                $FirstComment
                    = HTML::FormatText->format_string($FirstComment);

                if ( $FirstComment !~ /\S/ ) {
                    $FirstComment
                        = $FirstTransaction->Content( 'Type' => 'text/plain' )
                        || '';
                }

                $self->{'Cache'}->{'TicketFirstCommentText'} = $FirstComment;
            }
        }

        return $self->{'Cache'}->{'TicketFirstCommentText'};
    }

=head2 _All

Return the results of an "All" condition check.

=cut

    sub _All {
        my ( $self, %args ) = @_;
        return ( 1, $self->loc('Condition always matches'), '' );
    }

=head2 _InQueue

Return the results of an "InQueue" condition check.

=cut

    sub _InQueue {
        my ( $self, %args ) = @_;
        my $EventValue = $self->To || 'UNKNOWN';
        if ( $EventValue eq $args{'TargetValue'} ) {
            return ( 1, $self->loc('Queue matches'), $EventValue );
        }
        return (
            0,
            $self->loc(
                'Ticket queue [_1] is not [_2]', $EventValue,
                $args{'TargetValue'}
            ),
            $EventValue
        );
    }

=head2 _FromQueue

Return the results of a "FromQueue" condition check.

=cut

    sub _FromQueue {
        my ( $self, %args ) = @_;
        my $EventValue = $self->From || 'UNKNOWN';
        if ( $EventValue eq $args{'TargetValue'} ) {
            return ( 1, $self->loc('Original queue matches'), $EventValue );
        }
        return (
            0,
            $self->loc(
                'Original queue [_1] is not [_2]', $EventValue,
                $args{'TargetValue'}
            ),
            $EventValue
        );
    }

=head2 _ToQueue

Return the results of a "ToQueue" condition check.

=cut

    sub _ToQueue {
        my ( $self, %args ) = @_;
        my $EventValue = $self->To || 'UNKNOWN';
        $EventValue = 'UNKNOWN' if ( not defined $EventValue );
        if ( $EventValue eq $args{'TargetValue'} ) {
            return ( 1, $self->loc('Destination queue matches'),
                $EventValue );
        }
        return (
            0,
            $self->loc(
                'Destination queue [_1] is not [_2]', $EventValue,
                $args{'TargetValue'}
            ),
            $EventValue
        );
    }

=head2 _RequestorEmailIs

Return the results of a "RequestorEmailIs" condition check.

=cut

    sub _RequestorEmailIs {
        my ( $self, %args ) = @_;
        my @EventValues = $self->TicketRequestorEmailAddresses;

        push @EventValues, $self->loc('(no value)')
            if ( scalar @EventValues == 0 );

        foreach my $EventValue (@EventValues) {
            return ( 1, $self->loc('Requestor email address matches'),
                $EventValue )
                if ( lc($EventValue) eq lc( $args{'TargetValue'} ) );
        }

        return ( 0, $self->loc('Requestor email address does not match'),
            $EventValues[0] );
    }

=head2 _RequestorEmailDomainIs

Return the results of a "RequestorEmailDomainIs" condition check.

=cut

    sub _RequestorEmailDomainIs {
        my ( $self, %args ) = @_;
        my @EventValues
            = map { s/^.*\@//; $_ } $self->TicketRequestorEmailAddresses;

        push @EventValues, $self->loc('(no value)')
            if ( scalar @EventValues == 0 );

        foreach my $EventValue (@EventValues) {
            return ( 1, $self->loc('Requestor email domain matches'),
                $EventValue )
                if ( lc($EventValue) eq lc( $args{'TargetValue'} ) );
        }

        return ( 0, $self->loc('Requestor email domain does not match'),
            $EventValues[0] );
    }

=head2 _RecipientEmailIs

Return the results of a "RecipientEmailIs" condition check.

=cut

    sub _RecipientEmailIs {
        my ( $self, %args ) = @_;
        my @EventValues = $self->TicketRecipientEmailAddresses;

        push @EventValues, $self->loc('(no value)')
            if ( scalar @EventValues == 0 );

        foreach my $EventValue (@EventValues) {
            return ( 1, $self->loc('Recipient email address matches'),
                $EventValue )
                if ( lc($EventValue) eq lc( $args{'TargetValue'} ) );
        }

        return ( 0, $self->loc('Recipient email address does not match'),
            $EventValues[0] );
    }

=head2 _SubjectContains

Return the results of a "SubjectContains" condition check.

=cut

    sub _SubjectContains {
        my ( $self, %args ) = @_;

        my $EventValue = $self->TicketSubject;
        $EventValue = '' if ( not defined $EventValue );

        if ( index( lc($EventValue), lc( $args{'TargetValue'} ) ) >= 0 ) {
            return ( 1, $self->loc('Subject matches'), $EventValue );
        }

        return ( 0, $self->loc('Subject does not match'), $EventValue );
    }

=head2 _SubjectOrBodyContains

Return the results of a "SubjectOrBodyContains" condition check.

=cut

    sub _SubjectOrBodyContains {
        my ( $self, %args ) = @_;

        my $EventValue = $self->TicketSubject;
        $EventValue = '' if ( not defined $EventValue );

        if ( index( lc($EventValue), lc( $args{'TargetValue'} ) ) >= 0 ) {
            return ( 1, $self->loc('Subject matches'), $EventValue );
        }

        my $CheckedSubject = $EventValue;
        $EventValue = $self->TicketFirstCommentText;
        $EventValue = '' if ( not defined $EventValue );

        if ( index( lc($EventValue), lc( $args{'TargetValue'} ) ) >= 0 ) {
            return ( 1, $self->loc('Message body matches'), $EventValue );
        }

        return (
            0,
            $self->loc('Neither subject not message body match'),
            $CheckedSubject . "\n" . $EventValue
        );
    }

=head2 _BodyContains

Return the results of a "BodyContains" condition check.

=cut

    sub _BodyContains {
        my ( $self, %args ) = @_;

        my $EventValue = $self->TicketFirstCommentText;
        $EventValue = '' if ( not defined $EventValue );

        if ( index( lc($EventValue), lc( $args{'TargetValue'} ) ) >= 0 ) {
            return ( 1, $self->loc('Message body matches'), $EventValue );
        }

        return ( 0, $self->loc('Message body does not match'), $EventValue );
    }

=head2 _HasAttachment

Return the results of a "HasAttachment" condition check.

=cut

    sub _HasAttachment {
        my ( $self, %args ) = @_;

        return ( 0, $self->loc('Ticket has no attachment'), 0 )
            if ( not $self->{'Ticket'} );

        if ( not exists $self->{'Cache'}->{'TicketHasAttachment'} ) {
            my $AttachmentFound = 0;
            my $Attachments     = $self->{'Ticket'}->Attachments;
            while ( my $Attachment = $Attachments->Next() ) {
                next if ( not $Attachment->Filename );
                next if ( length $Attachment->Filename < 1 );
                $AttachmentFound = 1;
                last;
            }
            $self->{'Cache'}->{'TicketHasAttachment'} = $AttachmentFound;
        }

        if ( $self->{'Cache'}->{'TicketHasAttachment'} ) {
            return ( 1, $self->loc('Ticket has an attachment'), 1 );
        }

        return ( 0, $self->loc('Ticket has no attachment'), 0 );
    }

=head2 _PriorityIs

Return the results of a "PriorityIs" condition check.

=cut

    sub _PriorityIs {
        my ( $self, %args ) = @_;
        my $EventValue = $self->TicketPriority;
        return ( 1, $self->loc('Priority matches'), $EventValue )
            if ( $args{'TargetValue'} eq $EventValue );
        return ( 0, $self->loc('Priority does not match'), $EventValue );
    }

=head2 _PriorityUnder

Return the results of a "PriorityUnder" condition check.

=cut

    sub _PriorityUnder {
        my ( $self, %args ) = @_;
        my $EventValue = $self->TicketPriority;

        return ( 0, $self->loc('Priority is not numeric'), $EventValue )
            if ( $EventValue !~ /^\d+$/ );
        return ( 0, $self->loc('Priority to test against is not numeric'),
            $EventValue )
            if ( $args{'TargetValue'} !~ /^\d+$/ );

        return ( 1,
            $self->loc( 'Priority is under [_1]', $args{'TargetValue'} ),
            $EventValue )
            if ( $EventValue < $args{'TargetValue'} );

        return (
            0,
            $self->loc( 'Priority is not under [_1]', $args{'TargetValue'} ),
            $EventValue
        );
    }

=head2 _PriorityOver

Return the results of a "PriorityOver" condition check.

=cut

    sub _PriorityOver {
        my ( $self, %args ) = @_;
        my $EventValue = $self->TicketPriority;

        return ( 0, $self->loc('Priority is not numeric'), $EventValue )
            if ( $EventValue !~ /^\d+$/ );
        return ( 0, $self->loc('Priority to test against is not numeric'),
            $EventValue )
            if ( $args{'TargetValue'} !~ /^\d+$/ );

        return ( 1,
            $self->loc( 'Priority is over [_1]', $args{'TargetValue'} ),
            $EventValue )
            if ( $EventValue > $args{'TargetValue'} );

        return ( 0,
            $self->loc( 'Priority is not over [_1]', $args{'TargetValue'} ),
            $EventValue );
    }

=head2 _CustomFieldIs

Return the results of a "CustomFieldIs" condition check.

=cut

    sub _CustomFieldIs {
        my ( $self, %args ) = @_;

        my $EventValue
            = $self->TicketCustomFieldValue( $args{'CustomField'} );
        $EventValue = '' if ( not defined $EventValue );

        if ( lc($EventValue) eq lc( $args{'TargetValue'} ) ) {
            return (
                1,
                $self->loc(
                    'Custom field [_1] matches exactly',
                    $args{'CustomField'}
                ),
                $EventValue
            );
        }

        return (
            0,
            $self->loc(
                'Custom field [_1] does not match exactly',
                $args{'CustomField'}
            ),
            $EventValue
        );
    }

=head2 _CustomFieldContains

Return the results of a "CustomFieldContains" condition check.

=cut

    sub _CustomFieldContains {
        my ( $self, %args ) = @_;

        my $EventValue
            = $self->TicketCustomFieldValue( $args{'CustomField'} );
        $EventValue = '' if ( not defined $EventValue );

        if ( index( lc($EventValue), lc( $args{'TargetValue'} ) ) >= 0 ) {
            return (
                1,
                $self->loc(
                    'Custom field [_1] matches',
                    $args{'CustomField'}
                ),
                $EventValue
            );
        }

        return (
            0,
            $self->loc(
                'Custom field [_1] does not match',
                $args{'CustomField'}
            ),
            $EventValue
        );
    }

=head2 _StatusIs

Return the results of a "StatusIs" condition check.

=cut

    sub _StatusIs {
        my ( $self, %args ) = @_;
        my $EventValue = $self->TicketStatus;
        return ( 1, $self->loc('Status matches'), $EventValue )
            if ( lc( $args{'TargetValue'} ) eq lc($EventValue) );
        return ( 0, $self->loc('Status does not match'), $EventValue );
    }

}

{

=head1 Internal package RT::FilterRule::Action

This package provides the C<RT::FilterRule::Action> class, which describes
an action to perform on a ticket after matching a rule.

Objects of this class are not stored directly in the database, but are
encoded within attributes of C<RT::FilterRule> objects.

=cut

    package RT::FilterRule::Action;

    use base 'RT::Base';

=head1 RT::FilterRule::Action METHODS

This class inherits from C<RT::Base>.

=cut

=head2 new $UserObj[, PARAMS...]

Construct and return a new object, given an C<RT::CurrentUser> object.  Any
other parameters are passed to B<Set> below.

=cut

    sub new {
        my ( $proto, $UserObj, @args ) = @_;
        my ( $class, $self );

        $class = ref($proto) || $proto;

        $self = {
            'ActionType'  => 'All',
            'CustomField' => 0,
            'Value'       => '',
            'Notify'      => '',
            'Ticket'      => undef,
            'Cache'       => {},
        };

        bless( $self, $class );

        $self->CurrentUser($UserObj);

        $self->Set(@args);

        return $self;
    }

=head2 Set Key => VALUE, ...

Set parameters of this action object.  The following parameters define the
action itself:

=over 15

=item B<ActionType>

The type of action, such as I<SetSubject>, I<SetQueue>, and so on - see the
C<RT::Extension::FilterRules> method B<ActionTypes>.

=item B<CustomField>

The custom field ID associated with this action, if applicable (such as
which custom field to set the value of)

=item B<Value>

The value associated with this action, if applicable, such as the queue to
move to, or the contents of an email to send, or the email address or group
ID to add as a watcher

=item B<Notify>

The notification recipient associated with this action, if applicable, such
as a group ID or email address to send a message to

=back

The following parameters define the ticket being acted upon:

=over 

=item B<Ticket>

The C<RT::Ticket> object to perform the action on

=back

Finally, B<Cache> should be set to a hash reference, which should be
shared across all B<Test> or B<TestSingleValue> calls for this event;
lookups such as ticket subject, custom field ID to name mappings, and so on,
will be cached here so that they don't have to be done multiple times.

This method returns nothing.

=cut

    sub Set {
        my ( $self, %args ) = @_;

        foreach (
            'ActionType', 'CustomField', 'Value',
            'Notify',     'Ticket',      'Cache'
            )
        {
            $self->{$_} = $args{$_} if ( exists $args{$_} );
        }

        return 1;
    }

=head2 Perform FILTERRULE, TICKETOBJ

Perform the action described by this object's parameters, returning (
I<$ok>, I<$message> ), checking that the associated ticket has not recently
been touched by the same filter rule to avoid recursion.

=cut

    sub Perform {
        my ( $self, $FilterRule, $TicketObj ) = @_;

        $self->Set( 'Ticket' => $TicketObj );

        # Check that an action for this filter rule has not recently been
        # performed already.
        #
        my $AttributeName = 'FilterRules-' . $FilterRule->id;
        my $Attribute     = $self->Ticket->FirstAttribute($AttributeName);
        my $Epoch         = ( $Attribute ? $Attribute->Content : 0 ) || 0;

        if ( $Epoch > ( time - 60 ) ) {
            RT->Logger->warning(
                      'RT::Extension::FilterRule: Skipping action for rule #'
                    . $FilterRule->id
                    . ' on ticket '
                    . $self->{'Cache'}->{'Ticket'}->id
                    . ' - recently activated' );
            return (
                0,
                $self->loc(
                    'This rule has already been recently activated on this ticket'
                )
            );
        }

        # Map action types to their definitions.
        #
        if ( not $self->{'Cache'}->{'ActionTypes'} ) {
            $self->{'Cache'}->{'ActionTypes'} = {
                map { $_->{'ActionType'}, $_ }
                    RT::Extension::FilterRules->ActionTypes(
                    $self->CurrentUser
                    )
            };
        }

        my ( $Status, $Message ) = ( 0, '' );

        my $Method = '_' . $self->ActionType;
        if ( $self->can($Method) ) {
            ( $Status, $Message ) = $self->$Method();
        } elsif (
            defined $self->{'Cache'}->{'ActionTypes'}->{ $self->ActionType }
            ->{'Function'} )
        {
            ( $Status, $Message )
                = $self->{'Cache'}->{'ActionTypes'}->{ $self->ActionType }
                ->{'Function'}->( $self->CurrentUser, %$self );
        } else {
            $Message = $self->loc( 'Undefined action type: [_1]',
                $self->ActionType );
            RT->Logger->error(
                "RT::Extension::FilterRules - undefined action type: "
                    . $self->ActionType );
        }

        return ( $Status, $Message );
    }

=head2 IsNotification

Return true if this action is of a type which sends a notification, false
otherwise.  This is used when carrying out actions to ensure that all other
ticket actions are performed first.

=cut

    sub IsNotification {
        my $self = shift;
        return $self->ActionType =~ /^Notify/ ? 1 : 0;
    }

=head2 Properties

Return the properties of this object as a hash reference, suitable for
serialising and storing.

=cut

    sub Properties {
        my $self = shift;
        return {
            'ActionType'  => $self->{'ActionType'},
            'CustomField' => $self->{'CustomField'},
            'Value'       => $self->{'Value'},
            'Notify'      => $self->{'Notify'}
        };
    }

=head2 ActionType

Return the action type.

=cut

    sub ActionType { return $_[0]->{'ActionType'}; }

=head2 CustomField

Return the custom field ID associated with this action.

=cut

    sub CustomField { return $_[0]->{'CustomField'}; }

=head2 Value

Return the value associated with this action.

=cut

    sub Value { return $_[0]->{'Value'}; }

=head2 Notify

Return the notification email address or group ID associated with this
action.

=cut

    sub Notify { return $_[0]->{'Notify'}; }

=head2 Ticket

Return the ticket object that this action is being performed on.

=cut

    sub Ticket { return $_[0]->{'Ticket'}; }

=head2 _None

Return ( I<$ok>, I<$message> ) after performing the "None" action.

=cut

    sub _None {
        my $self = shift;
        return ( 1, $self->loc('No action taken') );
    }

=head2 _SubjectPrefix

Return ( I<$ok>, I<$message> ) after performing the "SubjectPrefix" action.

=cut

    sub _SubjectPrefix {
        my $self = shift;
        my ( $Prefix, $Subject, $NewSubject );

        $Prefix = $self->Value;
        $Prefix = '' if ( not defined $Prefix );
        $Prefix =~ s/^\s+//;
        return ( 1, $self->loc('No subject prefix to add') )
            if ( $Prefix !~ /\S/ );

        $Subject = $self->Ticket->Subject;
        $Subject = '' if ( not defined $Subject );
        $Subject =~ s/^\s+//;

        $NewSubject = $Prefix;
        $NewSubject .= ' ' . $Subject if ( $Subject =~ /\S/ );

        return $self->Ticket->SetSubject($NewSubject);
    }

=head2 _SubjectSuffix

Return ( I<$ok>, I<$message> ) after performing the "SubjectSuffix" action.

=cut

    sub _SubjectSuffix {
        my $self = shift;
        my ( $Suffix, $Subject, $NewSubject );

        $Suffix = $self->Value;
        $Suffix = '' if ( not defined $Suffix );
        $Suffix =~ s/\s+$//;
        return ( 1, $self->loc('No subject suffix to add') )
            if ( $Suffix !~ /\S/ );

        $Subject = $self->Ticket->Subject;
        $Subject = '' if ( not defined $Subject );
        $Subject =~ s/\s+$//;

        $NewSubject = '';
        $NewSubject = $Subject . ' ' if ( $Subject =~ /\S/ );
        $NewSubject .= $Suffix;

        return $self->Ticket->SetSubject($NewSubject);
    }

=head2 _SubjectRemoveMatch

Return ( I<$ok>, I<$message> ) after performing the "SubjectRemoveMatch" action.

=cut

    sub _SubjectRemoveMatch {
        my $self = shift;
        my ( $Match, $Subject, $NewSubject );

        $Match = $self->Value;
        $Match = '' if ( not defined $Match );
        return ( 1, $self->loc('No string to match') )
            if ( $Match eq '' );

        $Subject = $self->Ticket->Subject;
        $Subject = '' if ( not defined $Subject );

        $NewSubject = $Subject;
        $NewSubject =~ s/\Q$Match\E//i;

        return ( 1, $self->loc('Subject unchanged - match text not found') )
            if ( $NewSubject eq $Subject );

        return $self->Ticket->SetSubject($NewSubject);
    }

=head2 _SubjectSet

Return ( I<$ok>, I<$message> ) after performing the "SubjectSet" action.

=cut

    sub _SubjectSet {
        my $self = shift;
        my ( $NewSubject, $Subject );

        $NewSubject = $self->Value;
        $NewSubject = '' if ( not defined $NewSubject );

        $Subject = $self->Ticket->Subject;
        $Subject = '' if ( not defined $Subject );

        return ( 1, $self->loc('Subject unchanged') )
            if ( $NewSubject eq $Subject );

        return $self->Ticket->SetSubject($NewSubject);
    }

=head2 _PrioritySet

Return ( I<$ok>, I<$message> ) after performing the "PrioritySet" action.

=cut

    sub _PrioritySet {
        my $self = shift;
        my ( $NewPriority, $Priority );

        $NewPriority = $self->Value || 0;

        $Priority = $self->Ticket->Priority || 0;

        return ( 1, $self->loc('Priority unchanged') )
            if ( $NewPriority eq $Priority );

        return $self->Ticket->SetPriority($NewPriority);
    }

=head2 _PriorityAdd

Return ( I<$ok>, I<$message> ) after performing the "PriorityAdd" action.

=cut

    sub _PriorityAdd {
        my $self = shift;
        my ( $Offset, $NewPriority, $Priority );

        $Offset   = $self->Value            || 0;
        $Priority = $self->Ticket->Priority || 0;
        $NewPriority = $Priority + $Offset;

        return ( 1, $self->loc('Priority unchanged') )
            if ( $NewPriority eq $Priority );

        return $self->Ticket->SetPriority($NewPriority);
    }

=head2 _PrioritySubtract

Return ( I<$ok>, I<$message> ) after performing the "PrioritySubtract" action.

=cut

    sub _PrioritySubtract {
        my $self = shift;
        my ( $Offset, $NewPriority, $Priority );

        $Offset   = $self->Value            || 0;
        $Priority = $self->Ticket->Priority || 0;
        $NewPriority = $Priority - $Offset;

        return ( 1, $self->loc('Priority unchanged') )
            if ( $NewPriority eq $Priority );

        return $self->Ticket->SetPriority($NewPriority);
    }

=head2 _StatusSet

Return ( I<$ok>, I<$message> ) after performing the "StatusSet" action.

=cut

    sub _StatusSet {
        my $self = shift;
        my ( $NewStatus, $Status );

        $NewStatus = $self->Value;
        $NewStatus = '' if ( not defined $NewStatus );

        $Status = $self->Ticket->Status;
        $Status = '' if ( not defined $Status );

        return ( 1, $self->loc('Status unchanged') )
            if ( $NewStatus eq $Status );

        return $self->Ticket->SetStatus($NewStatus);
    }

=head2 _QueueSet

Return ( I<$ok>, I<$message> ) after performing the "QueueSet" action.

=cut

    sub _QueueSet {
        my $self = shift;
        my ( $NewQueue, $Queue );

        $NewQueue = $self->Value         || 0;
        $Queue    = $self->Ticket->Queue || 0;

        return ( 1, $self->loc('Queue unchanged') )
            if ( $NewQueue eq $Queue );

        return $self->Ticket->SetQueue($NewQueue);
    }

=head2 _CustomFieldSet

Return ( I<$ok>, I<$message> ) after performing the "CustomFieldSet" action.

=cut

    sub _CustomFieldSet {
        my $self = shift;
        my ( $NewValue, $CurrentValue );

        $NewValue = $self->Value;
        $NewValue = '' if ( not defined $NewValue );

        $CurrentValue
            = $self->Ticket->FirstCustomFieldValue( $self->CustomField );
        $CurrentValue = '' if ( not defined $CurrentValue );

        return ( 1, $self->loc('Custom field unchanged') )
            if ( $NewValue eq $CurrentValue );

        return $self->Ticket->AddCustomFieldValue(
            'Field' => $self->CustomField,
            'Value' => $NewValue
        );
    }

=head2 _RequestorAdd

Return ( I<$ok>, I<$message> ) after performing the "RequestorAdd" action.

=cut

    sub _RequestorAdd {
        my $self = shift;
        return $self->Ticket->AddWatcher(
            'Type'  => 'Requestor',
            'Email' => $self->Value
        );
    }

=head2 _RequestorRemove

Return ( I<$ok>, I<$message> ) after performing the "RequestorRemove" action.

=cut

    sub _RequestorRemove {
        my $self = shift;
        return $self->Ticket->DeleteWatcher(
            'Type'  => 'Requestor',
            'Email' => $self->Value
        );
    }

=head2 _CcAdd

Return ( I<$ok>, I<$message> ) after performing the "CcAdd" action.

=cut

    sub _CcAdd {
        my $self = shift;
        return $self->Ticket->AddWatcher(
            'Type'  => 'Cc',
            'Email' => $self->Value
        );
    }

=head2 _CcAddGroup

Return ( I<$ok>, I<$message> ) after performing the "CcAddGroup" action.

=cut

    sub _CcAddGroup {
        my $self = shift;
        return $self->Ticket->AddWatcher(
            'Type'        => 'Cc',
            'PrincipalId' => $self->Value
        );
    }

=head2 _CcRemove

Return ( I<$ok>, I<$message> ) after performing the "CcRemove" action.

=cut

    sub _CcRemove {
        my $self = shift;
        return $self->Ticket->DeleteWatcher(
            'Type'  => 'Cc',
            'Email' => $self->Value
        );
    }

=head2 _AdminCcAdd

Return ( I<$ok>, I<$message> ) after performing the "AdminCcAdd" action.

=cut

    sub _AdminCcAdd {
        my $self = shift;
        return $self->Ticket->AddWatcher(
            'Type'  => 'AdminCc',
            'Email' => $self->Value
        );
    }

=head2 _AdminCcAddGroup

Return ( I<$ok>, I<$message> ) after performing the "AdminCcAddGroup" action.

=cut

    sub _AdminCcAddGroup {
        my $self = shift;
        return $self->Ticket->AddWatcher(
            'Type'        => 'AdminCc',
            'PrincipalId' => $self->Value
        );
    }

=head2 _AdminCcRemove

Return ( I<$ok>, I<$message> ) after performing the "AdminCcRemove" action.

=cut

    sub _AdminCcRemove {
        my $self = shift;
        return $self->Ticket->DeleteWatcher(
            'Type'  => 'AdminCc',
            'Email' => $self->Value
        );
    }

=head2 _Reply

Return ( I<$ok>, I<$message> ) after performing the "Reply" action.

=cut

    sub _Reply {
        my $self = shift;

        # Bodged together from RT 4.2.16's
        # HTML::Mason::Commands::CreateTicket() and ProcessUpdateMessage()
        #

        my $MIMEObj = HTML::Mason::Commands::MakeMIMEEntity(
            'Subject'   => $self->Ticket->Subject,
            'Body'      => $self->Value,
            'Type'      => 'text/html',
            'Interface' => 'Web'
        );
        my $NewMessageId
            = RT::Interface::Email::GenMessageId( 'Ticket' => $self->Ticket );
        $MIMEObj->head->replace(
            'Message-ID' => Encode::encode( 'UTF-8', $NewMessageId ) );
        my ( $NTrans, $Nmsg, $NTransObj )
            = $self->Ticket->Correspond( 'MIMEObj' => $MIMEObj );

        return ( $NTrans, $Nmsg ) if ( not $NTrans );

        return ( 1, $self->loc('Reply sent') );
    }

=head2 _NotifyEmail

Return ( I<$ok>, I<$message> ) after performing the "NotifyEmail" action.

=cut

    sub _NotifyEmail {
        my $self = shift;

        # As _Reply() but we comment with a BCC instead of corresponding,
        # then delete our transaction so it's not in the history.

        # Normalise a comma or semicolon separated list of email addresses
        # into comma-and-space separated.
        #
        my $RecipientList = $self->Notify || '';
        $RecipientList
            = join( ', ', grep {/\S\@\S/} split qr/[,;]\s*/, $RecipientList );

        return ( 1, $self->loc('No recipients') )
            if ( $RecipientList !~ /\@/ );

        my $MIMEObj = HTML::Mason::Commands::MakeMIMEEntity(
            'Subject'   => $self->Ticket->Subject,
            'Body'      => $self->Value,
            'Type'      => 'text/html',
            'Interface' => 'Web'
        );
        my $NewMessageId
            = RT::Interface::Email::GenMessageId( 'Ticket' => $self->Ticket );
        $MIMEObj->head->replace(
            'Message-ID' => Encode::encode( 'UTF-8', $NewMessageId ) );
        my ( $NTrans, $Nmsg, $NTransObj ) = $self->Ticket->Comment(
            'MIMEObj' => $MIMEObj,
            'BccMessageTo', $RecipientList
        );

        return ( $NTrans, $Nmsg ) if ( not $NTrans );

        # Now delete the transaction.
        $NTransObj->Delete if ($NTransObj);

        return ( 1, $self->loc('Email sent') );
    }

=head2 _NotifyGroup

Return ( I<$ok>, I<$message> ) after performing the "NotifyGroup" action.

=cut

    sub _NotifyGroup {
        my $self = shift;

        # As _NotifyEmail() but we load a user-defined group and enumerate
        # its members to make a list of email addresses to BCC.

        my $GroupObj = RT::Group->new( RT->SystemUser );
        return ( 0, loc('Failed to load recipient group') )
            if ( not $GroupObj->LoadUserDefinedGroup( $self->Notify ) );
        return ( 0, loc('Failed to load recipient group') )
            if ( not $GroupObj->id );

        my $RecipientList = join( ', ',
            grep {/\S\@\S/} $GroupObj->MemberEmailAddressesAsString() );

        return ( 1, $self->loc('No recipients') )
            if ( $RecipientList !~ /\@/ );

        my $MIMEObj = HTML::Mason::Commands::MakeMIMEEntity(
            'Subject'   => $self->Ticket->Subject,
            'Body'      => $self->Value,
            'Type'      => 'text/html',
            'Interface' => 'Web'
        );
        my $NewMessageId
            = RT::Interface::Email::GenMessageId( 'Ticket' => $self->Ticket );
        $MIMEObj->head->replace(
            'Message-ID' => Encode::encode( 'UTF-8', $NewMessageId ) );
        my ( $NTrans, $Nmsg, $NTransObj ) = $self->Ticket->Comment(
            'MIMEObj' => $MIMEObj,
            'BccMessageTo', $RecipientList
        );

        return ( $NTrans, $Nmsg ) if ( not $NTrans );

        # Now delete the transaction.
        $NTransObj->Delete if ($NTransObj);

        return ( 1, $self->loc('Email sent') );
    }

}

{

=head1 Internal package RT::FilterRules

This package provides the C<RT::FilterRules> class, which describes a
collection of filter rules.

=cut

    package RT::FilterRules;

    use base 'RT::SearchBuilder';

    sub Table {'FilterRules'}

    sub _Init {
        my $self = shift;
        $self->OrderByCols( { FIELD => 'SortOrder', ORDER => 'ASC' } );
        return $self->SUPER::_Init(@_);
    }

    RT::Base->_ImportOverlays();
}

{

=head1 Internal package RT::FilterRuleMatch

This package provides the C<RT::FilterRuleMatch> class, which records when
a filter rule matched an event on a ticket.

The attributes of this class are:

=over 12

=item B<id>

The numeric ID of this event

=item B<FilterRule>

The numeric ID of the filter rule which matched (also presented as an
C<RT::FilterRule> object via B<FilterRuleObj>)

=item B<Ticket>

The numeric ID of the ticket whose event matched this rule (also presented
as an C<RT::Ticket> object via B<TicketObj>)

=item B<Created>

The date and time this event occurred (also presented as an C<RT::Date>
object via B<CreatedObj>)

=back

=cut

    package RT::FilterRuleMatch;
    use base 'RT::Record';

    sub Table {'FilterRuleMatches'}

=head1 RT::FilterRuleMatch METHODS

Note that additional methods will be available, inherited from
C<RT::Record>.

=cut

=head2 Create FilterRule => ID, Ticket => ID

Create a new filter rule match object with the supplied properties, as
described above.  The I<FilterRule> and I<Ticket> can be passed as integer
IDs or as C<RT::FilterRule> and C<RT::Ticket> objects.

Returns ( I<$id>, I<$message> ), where I<$id> is the ID of the new object,
which will be undefined if there was a problem.

=cut

    sub Create {
        my $self = shift;
        my %args = (
            'FilterRule' => 0,
            'Ticket'     => 0,
            @_
        );

        $args{'FilterRule'} = $args{'FilterRule'}->id
            if ( ( ref $args{'FilterRule'} )
            && UNIVERSAL::isa( $args{'FilterRule'}, 'RT::FilterRule' ) );
        $args{'Ticket'} = $args{'Ticket'}->id
            if ( ( ref $args{'Ticket'} )
            && UNIVERSAL::isa( $args{'Ticket'}, 'RT::Ticket' ) );

        $RT::Handle->BeginTransaction();
        my ( $id, $msg ) = $self->SUPER::Create(%args);
        unless ($id) {
            $RT::Handle->Rollback();
            return ( undef, $msg );
        }
        $RT::Handle->Commit();

        return ( $id,
            $self->loc( 'Filter rule match [_1] created', $self->id ) );
    }

=head2 FilterRuleObj

Return an C<RT::FilterRule> object containing this filter rule match's
matching filter rule.

=cut

    sub FilterRuleObj {
        my ($self) = @_;

        if (   !$self->{'_FilterRule_obj'}
            || !$self->{'_FilterRule_obj'}->id )
        {

            $self->{'_FilterRule_obj'}
                = RT::FilterRule->new( $self->CurrentUser );
            my ($result)
                = $self->{'_FilterRule_obj'}
                ->Load( $self->__Value('FilterRule') );
        }
        return ( $self->{'_FilterRule_obj'} );
    }

=head2 TicketObj

Return an C<RT::Ticket> object containing this filter rule match's matching
ticket.

=cut

    sub TicketObj {
        my ($self) = @_;

        if (   !$self->{'_Ticket_obj'}
            || !$self->{'_Ticket_obj'}->id )
        {

            $self->{'_Ticket_obj'} = RT::Ticket->new( $self->CurrentUser );
            my ($result)
                = $self->{'_Ticket_obj'}->Load( $self->__Value('Ticket') );
        }
        return ( $self->{'_Ticket_obj'} );
    }

=head2 _CoreAccessible

Return a hashref describing the attributes of the database table for the
C<RT::FilterRuleMatch> class.

=cut

    sub _CoreAccessible {
        return {

            'id' => {
                read       => 1,
                sql_type   => 4,
                length     => 11,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'int(11)',
                default    => ''
            },

            'FilterRule' => {
                read       => 1,
                write      => 1,
                sql_type   => 4,
                length     => 11,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'int(11)',
                default    => '0'
            },

            'Ticket' => {
                read       => 1,
                write      => 1,
                sql_type   => 4,
                length     => 11,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'int(11)',
                default    => '0'
            },

            'Created' => {
                read       => 1,
                auto       => 1,
                sql_type   => 11,
                length     => 0,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'datetime',
                default    => ''
            }
        };
    }

    RT::Base->_ImportOverlays();
}

{

=head1 Internal package RT::FilterRuleMatches

This package provides the C<RT::FilterRuleMatches> class, which describes a
collection of filter rule matches.

=cut

    package RT::FilterRuleMatches;

    use base 'RT::SearchBuilder';

    sub Table {'FilterRuleMatches'}

    RT::Base->_ImportOverlays();
}

=head1 AUTHOR

Andrew Wood

=for html <p>All bugs should be reported via email to <a
href="mailto:bug-RT-Extension-FilterRules@rt.cpan.org">bug-RT-Extension-FilterRules@rt.cpan.org</a>
or via the web at <a
href="http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-FilterRules">rt.cpan.org</a>.</p>

=for text
    All bugs should be reported via email to
        bug-RT-Extension-FilterRules@rt.cpan.org
    or via the web at
        http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-FilterRules

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Andrew Wood

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
