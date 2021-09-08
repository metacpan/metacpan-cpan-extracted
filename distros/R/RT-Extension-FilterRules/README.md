# NAME

RT::Extension::FilterRules - Filter incoming tickets through rule sets

# DESCRIPTION

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

Filter rules are managed under _Tools_ - _Filter rules_.

# REQUIREMENTS

Requires `Email::Address` and `HTML::FormatText`.

# RT VERSION

Known to work with RT 4.2.16, 4.4.4, and 5.0.1.

# INSTALLATION

- `perl Makefile.PL`
- `make`
- `make install`

    May need root permissions.

- **Set up the database**

    After running `make install` for the first time, you will need to create
    the database tables for this extension.  Use `etc/schema-mysql.sql` for
    MySQL or MariaDB, or `etc/schema-postgresql.sql` for PostgreSQL.

- **Edit your** `/opt/rt4/etc/RT_SiteConfig.pm`

    Add this line:

        Plugin('RT::Extension::FilterRules');

- **Clear your Mason cache**

        rm -rf /opt/rt4/var/mason_data/obj

- **Restart your web server**
- **Add the processing scrip**

    Create a new global scrip under _Admin_ - _Global_ - _Scrips_:

    - Description:

        Filter rule processing

    - Condition:

        User Defined

    - Action:

        User Defined

    - Template:

        Blank

    - Stage:

        Normal

    - Custom condition:

            return 0 if (not $RT::Extension::FilterRules::VERSION);
            return RT::Extension::FilterRules->ScripIsApplicable($self);

    - Custom action preparation code:

            return 0 if (not $RT::Extension::FilterRules::VERSION);
            return RT::Extension::FilterRules->ScripPrepare($self);

    - Custom action commit code:

            return 0 if (not $RT::Extension::FilterRules::VERSION);
            return RT::Extension::FilterRules->ScripCommit($self);

    No filter rules will actually perform any actions until this scrip is
    created and enabled.

    Note that the `return 0` lines are only there to prevent errors if you
    later remove this extension without disabling the scrip.

- **Set up some filter rule groups**

    Rule groups are set up by the RT administrator under _Admin_ - _Filter
    rule groups_.

# TUTORIAL

For the purposes of this tutorial, we assume that you have these queues:

- **"General"** - for general queries;
- **"Technical"** - for more technical matters to be escalated to.

We also assume that you have these user-defined groups set up:

- **"Service desk"** - containing all first-line analysts;
- **"Service desk management"** - containing the leadership team for the service desk;
- **"Third line"** - containing all technical teams.

These are only examples for illustration, there is no need for your system
to be set up this way to use it with this extension.

## Create a new filter rule group

1. As a superuser, go to _Admin_ - _Filter rule groups_ - _Create_.
2. Provide a name for the new filter rule group, such as
_"General inbound message filtering"_, and click on the **Create** button.
3. Now that the filter rule group has been created, you can define the queues
and groups it can use.

    Next to _Queues to allow in match rules_, select your _General_ queue and
    click on the **Add queue** button.

4. You will see the _General_ queue is now listed next to _Queues to allow in
match rules_.  If you select it and click on the **Save Changes** button, the
queue will be removed from the list.

    If you tried that, add it back again before the next step.

5. Rules in this filter rule group need to be able to transfer tickets into the
_Technical_ queue, so next to _Queues to allow as transfer destinations_,
select your _Technical_ queue and click on the **Add queue** button.
6. Add the _Service desk_ and _Third line_ groups to
_Groups to allow in rule actions_ to be able to use them in filter rules,
such as sending notifications to members of those groups.

After saving your changes, go back to _Admin_ - _Filter rule groups_, and
you will see your new filter rule group and its settings.

Once you have more than one, you can move them up and down in the list to
control the order in which they are processed, using the _Up_ and _Down_
links at the right.

## Set the requirements for the filter rule group

A filter rule group will not process any messages unless its requirements
are met.  Each one starts off with no requirements, so will remain inactive
until you define some.

From _Admin_ - _Filter rule groups_, click on your new filter rule group,
and then choose _Requirements_ from the page menu at the top.

Click on the **Create new requirement rule** button to create a new
requirement rule for that filter rule group.

1. Give the requirement rule a name, such as _"Created in the General queue"_.
2. Set the trigger type.  This rule will be processed when an event of this
type occurs, and skipped over otherwise.  The available trigger types are
_"On ticket creation"_ and _"When a ticket moves between queues"_; for
this example, select _"On ticket creation"_.
3. Choose the conflict conditions.  If _any_ of these conditions are met, the
rule will _not_ match.  For this example, leave this empty.
4. Choose the requirement conditions.  _All_ of these conditions must be met
for the rule to match.  Click on the **Add condition** button, choose
_"In queue"_, and select the _"General"_ queue.

    For each condition, although all of the conditions must be met, you can
    specify multiple values for each condition using the **Add value** button for
    that condition.  This means that the condition will be met if any one of its
    values matches.

5. Click on the **Create** button to create the new requirement rule.

In the list of requirement rules, click on a rule's number or name to edit
it.

Add as many requirement rules as you need.  They can be switched off
temporarily by marking them as disabled.

## Delegate control of the filter rule group

In this example, the new filter rule group you created above, called
_General inbound message filtering_, is going to be managed by the
service desk management team.  This means that you want them to be able to
create, update, and delete filter rules within that group with no
assistance.

We will also allow the service desk team to view the filter rules, so that
they have visibility of what automated processing is being applied to
tickets they are receiving.

1. From _Admin_ - _Filter rule groups_, click on your new filter rule group,
and then choose _Group Rights_ from the page menu at the top.
2. In the text box under _ADD GROUP_ at the bottom left, type
_"Service desk management"_ but do not hit Enter.
3. On the right side of the screen, under _Rights for Staff_, select all of
the rights so that the management team can fully control the filter rules in
this filter rule group.
4. Click on the **Save Changes** button at the bottom right to grant these
rights.
5. In the text box under _ADD GROUP_ at the bottom left, type
_"Service desk"_ but do not hit Enter.
6. On the right side of the screen, under _Rights for Staff_, select only the
_View filter rules_ right, so that the service desk analysts can only view
these filter rules, not edit them.
7. Click on the **Save Changes** button at the bottom right to grant these
rights.

Members of the _Service desk management_ group will now be able to manage
the filter rules of the _General inbound message filtering_ filter rule
group, under the _Tools_ - _Filter rules_ menu.

Members of the _Service desk_ group will be able to see those rules there
too, but will not be able to modify them.

## Creating filter rules

RT super users can edit filter rules by starting from _Admin_ - _Filter
rule groups_ - _Select_, choosing a filter rule group, and then choosing
_Filters_ from the page menu at the top.

Members of the groups you delegated access to in the steps above can edit
the filter rules by going to _Tools_ - _Filter rules_.  If they have
access to more than one filter rule group, they can then choose which one's
rules to edit from the list provided.

Click on the **Create new filter rule** button to create a new filter rule.

1. Give the filter rule a name, such as
_"Escalate desktop wallpaper requests"_.
2. Set the trigger type, as with the requirement rule above.  For this example,
select _"On ticket creation"_.
3. Choose the conflict conditions, as with the requirement rule above.  For
this example, click on the **Add condition** button, choose _"Subject or
message body contains"_, and type `paste` into the box next to it.
4. Choose the requirement conditions, as with the requirement rule above.  For
this example:
    - Click on the **Add condition** button, choose a _"In queue"_, and select the
    _"General"_ queue.
    - Click on the **Add condition** button again, choose  _"Subject or
    message body contains"_, and type `wallpaper` into the box next to it.
    - Click on the **Add value** button underneath the box containing `wallpaper`
    and type `background` into the box that appears.
    - Click on the **Add condition** button again, choose  _"Subject or
    message body contains"_, and type `desktop` into the box next to it.
5. Choose the actions to perform when this rule is matched.  For this example,
click on the **Add action** button, choose _"Move to queue"_, and select the
_"Technical"_ queue.
6. Choose whether to stop processing any further rules in this filter rule
group when this particular filter rule is matched.

    By default, this is set to _"No"_, which means that even if this rule
    matches, the rules after it will still be checked too.

    For this example, leave it set to _"No"_.

Click on the **Create** button to create the new filter rule.  You will see a
message something like `Filter rule 15 created`.  Click on the **Back**
button below that message to return to the list of filter rules.

Your new rule will be shown in the list.  The conflicts, requirements, and
actions are detailed in the list.  You will see that this new rule:

- Will never match, if the subject or message body contains the word `paste`.
- Will match otherwise, if the ticket was created in the _General_ queue, and
its subject or message body contains either of the words `wallpaper` or
`background`, _and_ its subject or message body contains the word
`desktop`.
- When the rule matches, it will move the ticket to the _Technical_ queue.

For example, if someone creates a ticket in the _General_ queue mentioning
`desktop wallpaper` or `desktop background`, the ticket will be moved to
the _Technical_ queue, but if they mention `desktop wallpaper paste`, the
ticket will not be moved because of the conflict condition about the word
`paste`.

Usually you would not actually move tickets based on keyword matches, this
is just an example - though you may want to send notification emails when
certain words appear, or set custom field values or priorities, for
instance.

Filter rules are processed in order.  In the list of filter rules, use the
_\[Up\]_ and _\[Down\]_ links to move filter rules up and down.

## Testing filter rules

Filter rules can be tested without having to really create new tickets or
move them between queues, but you will need an existing ticket to use as a
point of reference.

From either _Tools_ - _Filter rules_ or _Admin_ - _Filter rule groups_,
choose the _Test_ option from the page menu at the top right.

1. Choose a ticket to test against.  This is used in rules regarding ticket
subject, message body, and so on.
2. Choose which filter rule group to test against, or _"All"_ to run the test
against all filter rule groups you have access to.
3. Select the type of triggering event to simulate.
4. Choose the queue or queues involved in the simulation.  For instance, if you
are simulating ticket creation, choose which queue to pretend it is being
created in.
5. Choose whether to include disabled rules in the test.  This can be useful if
you would like to set up new filter rules and test them before using them -
you can create them but leave them disabled, then run this test with
disabled rules included.

Click on the **Test** button to run the test; the results will be shown in
the _Results_ section below the input form.

The test will not make any changes to tickets or to filter rules.

For each filter rule group, the **requirement rules** will be processed, and
a detailed breakdown of the steps involved will be displayed.

If any requirement rules matched, then a breakdown the **filter rules** will
be shown, followed by the **actions** which those filter rules would give
rise to.

The _Rule_, _Match type_, and _Outcome of test_ columns show the overall
outcome of each rule.  The _Conflict conditions_ and _Requirement
conditions_ columns give details of all of the individual conditions within
each rule.

Within the rule processing steps, the _Event value_ refers to the value
taken from the event - for instance, in a subject matching condition, this
would be the ticket's subject.  The _Target value_ refers to the value the
condition is looking for - that is, the values you entered into the form
when creating the filter rules.

# INTERNAL FUNCTIONS

These functions are used internally by this extension.  They should all be
called as methods, like this:

    return RT::Extension::FilterRules->ScripIsApplicable($self);

## ScripIsApplicable $Condition

The "is-applicable" condition of the scrip which applies filter rules to
tickets.  Returns true if it is appropriate for this extension to
investigate the action associated with this scrip.

## ScripPrepare $Action

The "prepare" action of the scrip which applies filter rules to tickets. 
Returns true on success.

## ScripCommit $Action

The "commit" action of the scrip which applies filter rules to tickets. 
Returns true on success.

## ConditionTypes $UserObj

Return an array of all available condition types, with the names localised
for the given user.

Each array entry is a hash reference containing these keys:

- **ConditionType**

    The internal name for this condition type; this should follow the naming
    convention for variables - start with a letter, no spaces, and so on - and
    it must be unique

- **Name**

    Localised name, to be displayed to the operator

- **TriggerTypes**

    Array reference listing the trigger actions with which this condition can be
    used (as listed under the _TriggerType_ attribute of the `RT::FilterRule`
    class below), or an empty array reference (or undef) if this condition type
    can be used with all trigger types

- **ValueType**

    Which type of value the condition expects as a parameter - one of
    _None_, _String_, _Integer_, _Email_, _Queue_, or _Status_

- **Function**

    If present, this is a code reference which will be called to check this
    condition; this code reference will be passed an `RT::CurrentUser` object
    and a hash of the parameters from inside an `RT::FilterRule::Condition`
    object (including _TargetValue_), as it will be called from the
    **TestSingleValue** method of `RT::FilterRule::Condition` - like
    **TestSingleValue**, it should return ( _$matched_, _$message_,
    _$eventvalue_ ).

If _Function_ is not present, the **TestSingleValue** method of
`RT::FilterRule::Condition` will attempt to call an
`RT::FilterRule::Condition` method of the same name as _ConditionType_
with `_` prepended, returning a failed match (and logging an error) if such
a method does not exist.

Note that if _ConditionType_ contains the string `CustomField`, then the
condition will require the person creating the condition to select an
applicable custom field.

## ActionTypes $UserObj

Return an array of all available action types, with the names localised for
the given user.

Each array entry is a hash reference containing these keys:

- **ActionType**

    The internal name for this action type; this should follow the naming
    convention for variables - start with a letter, no spaces, and so on - and
    it must be unique

- **Name**

    Localised name, to be displayed to the operator

- **ValueType**

    Which type of value the action expects as a parameter - one of _None_,
    _String_, _Integer_, _Email_, _Group_, _Queue_, _Status_, or _HTML_

- **Function**

    If present, this is a code reference which will be called to perform this
    action; this code reference will be passed an `RT::CurrentUser` object and
    a hash of the parameters from inside an `RT::FilterRule::Action` object, as
    it will be called from the **Perform** method of `RT::FilterRule::Action` -
    it should return ( _$ok_, _$message_ )

If _Function_ is not present, the **Perform** method of
`RT::FilterRule::Action` will attempt to call an `RT::FilterRule::Action`
method of the same name as _ActionType_ with `_` prepended, returning a
failed action (and logging an error) if such a method does not exist.

Note that:

- If _ActionType_ contains the string `CustomField`, then a custom field
must be selected by the person creating the action, separately to the value,
and this will populate the `RT::FilterRule::Action`'s _CustomField_
attribute;
- If _ActionType_ contains the string `NotifyEmail`, then an email address
must be entered by the person creating the action, separately to the value,
and this will populate the `RT::FilterRule::Action`'s _Notify_ attribute;
- If _ActionType_ contains the string `NotifyGroup`, then an RT group must
be selected by the person creating the action, separately to the value, and
this will populate the `RT::FilterRule::Action`'s _Notify_ attribute.

## AddConditionProvider CODEREF

Add a condition provider, which is a function accepting an
`RT::CurrentUser` object and returning an array of the same form as the
**ConditionTypes** method.

The **ConditionTypes** method will call the provided code reference and
append its returned values to the array it returns.

Other extensions can call this method to add their own filter condition
types.

## AddActionProvider CODEREF

Add an action provider, which is a function accepting an
`RT::CurrentUser` object and returning an array of the same form as the
**ActionTypes** method.

The **ActionTypes** method will call the provided code reference and append
its returned values to the array it returns.

Other extensions can call this method to add their own filter action types.

# Internal package RT::FilterRuleGroup

This package provides the `RT::FilterRuleGroup` class, which describes a
group of filter rules through which a ticket will be passed if it meets the
basic requirements of the group.

The attributes of this class are:

- **id**

    The numeric ID of this filter rule group

- **SortOrder**

    The order of processing - filter rule groups with a lower sort order are
    processed first

- **Name**

    The displayed name of this filter rule group

- **CanMatchQueues**

    The queues which rules in this rule group are allowed to use in their
    conditions, as a comma-separated list of queue IDs (also presented as an
    `RT::Queues` object via **CanMatchQueuesObj**)

- **CanTransferQueues**

    The queues which rules in this rule group are allowed to use as transfer
    destinations in their actions, as a comma-separated list of queue IDs (also
    presented as an `RT::Queues` object via **CanTransferQueuesObj**)

- **CanUseGroups**

    The groups which rules in this rule group are allowed to use in match
    conditions and actions, as a comma-separated list of group IDs (also
    presented as an `RT::Groups` object via **CanUseGroupsObj**)

- **Creator**

    The numeric ID of the creator of this filter rule group (also presented as
    an `RT::User` object via **CreatorObj**)

- **Created**

    The date and time this filter rule group was created (also presented as an
    `RT::Date` object via **CreatedObj**)

- **LastUpdatedBy**

    The numeric ID of the user who last updated the properties of this filter
    rule group (also presented as an `RT::User` object via **LastUpdatedByObj**)

- **LastUpdated**

    The date and time this filter rule group's properties were last updated
    (also presented as an `RT::Date` object via **LastUpdatedObj**)

- **Disabled**

    Whether this filter rule group is disabled; the filter rule group is active
    unless this property is true

The basic requirements of the filter rule group are defined by its
**GroupRequirements**, which is a collection of `RT::FilterRule` objects
whose **IsGroupRequirement** attribute is true.  If _any_ of these rules
match, the ticket is eligible to be passed through the filter rules for this
group.

The filter rules for this group are presented via **FilterRules**, which is a
collection of `RT::FilterRule` objects.

Filter rule groups themselves can only be created, modified, and deleted by
users with the _SuperUser_ right.

The following rights can be assigned to individual filter rule groups to
delegate control of the filter rules within them:

- **SeeFilterRule**

    View the filter rules in this filter rule group

- **ModifyFilterRule**

    Modify existing filter rules in this filter rule group

- **CreateFilterRule**

    Create new filter rules in this filter rule group

- **DeleteFilterRule**

    Delete filter rules from this filter rule group

These are assigned using the rights pages of the filter rule group, under
_Admin_ - _Filter rule groups_.

# RT::FilterRuleGroup METHODS

Note that additional methods will be available, inherited from
`RT::Record`.

## Create Name => Name, ...

Create a new filter rule group with the supplied properties, as described
above.  The sort order will be set to 1 more than the highest current value
so that the new item appears at the end of the list.

Returns ( _$id_, _$message_ ), where _$id_ is the ID of the new object,
which will be undefined if there was a problem.

## CanMatchQueues

Return the queues which rules in this rule group are allowed to use in their
conditions, as a comma-separated list of queue IDs in a scalar context, or
as an array of queue IDs in a list context.

## CanMatchQueuesObj

Return the same as **CanMatchQueues**, but as an `RT::Queues` object, i.e. a
collection of `RT::Queue` objects.

## CanTransferQueues

Return the queues which rules in this rule group are allowed to use as
transfer destinations in their actions, as a comma-separated list of queue
IDs in a scalar context, or as an array of queue IDs in a list context.

## CanTransferQueuesObj

Return the same as **CanTransferQueues**, but as an `RT::Queues` object,
i.e. a collection of `RT::Queue` objects.

## CanUseGroups

Return the groups which rules in this rule group are allowed to use in match
conditions and actions, as a comma-separated list of group IDs in a scalar
context, or as an array of group IDs in a list context.

## CanUseGroupsObj

Return the same as **CanUseGroups**, but as an `RT::Groups` object, i.e. a
collection of `RT::Group` objects.

## SetCanMatchQueues id, id, ...

Set the queues which rules in this rule group are allowed to use in their
conditions, either as a comma-separated list of queue IDs, an array of queue
IDs, an array of `RT::Queue` objects, or an `RT::Queues` collection.

Returns ( _$ok_, _$message_ ).

## SetCanTransferQueues id, id, ...

Set the queues which rules in this filter rule group are allowed to use as
transfer destinations in their actions, either as a comma-separated list of
queue IDs, an array of queue IDs, an array of `RT::Queue` objects, or an
`RT::Queues` collection.

Returns ( _$ok_, _$message_ ).

## SetCanUseGroups id, id, ...

Set the groups which rules in this rule group are allowed to use in match
conditions and actions, either as a comma-separated list of group IDs, an
array of group IDs, an array of `RT::Group` objects, or an `RT::Groups`
collection.

Returns ( _$ok_, _$message_ ).

## GroupRequirements

Return an `RT::FilterRules` collection object containing the requirements
of this filter rule group - if an event matches any of these requirement
rules, then the caller should process the event through the **FilterRules**
for this group.

## AddGroupRequirement Name => NAME, ...

Add a requirement rule to this filter rule group; calls the
`RT::FilterRule` **Create** method, overriding the _FilterRuleGroup_ and
_IsGroupRequirement_ parameters, and returns its output.

## FilterRules

Return an `RT::FilterRules` collection object containing the filter rules
for this rule group.

## AddFilterRule Name => NAME, ...

Add a filter rule to this filter rule group; calls the `RT::FilterRule`
**Create** method, overriding the _FilterRuleGroup_ and _IsGroupRequirement_
parameters, and returns its output.

## Delete

Delete this filter rule group, and all of its filter rules.  Returns
( _$ok_, _$message_ ).

## CheckGroupRequirements RuleChecks => \[\], TriggerType => ...,

For the given event, append details of checked group requirements to the
_RuleChecks_ array reference.

A _Ticket_ should be supplied, either as an ID or as an `RT::Ticket` object.

Returns ( _$Matched_, _$Message_, _$EventValue_, _$TargetValue_ ), where
_$Matched_ will be true if there were any requirement rule matches (meaning
that the caller should pass the event through this filter rule group's
**FilterRules**), false if there were no matches.  The other returned values
will relate to the last requirements rule matched.

If _IncludeDisabled_ is true, then even rules marked as disabled will be
checked.  The default is false.

If _DescribeAll_ is true, then all conditions for all requirement rules
will be added to _RuleChecks_ regardless of whether they influenced the
outcome; this can be used to present the operator with details of how an
event would be processed.

If _RecordMatch_ is true, then the fact that a rule is matched will be
recorded in the database (see `RT::FilterRuleMatch`).  The default is not
to record the match.

A _Cache_ should be provided, pointing to a hash reference to store
information in while processing this event, which the caller should share
with the **CheckFilterRules** method and other instances of this class, for
the same event.

See the `RT::FilterRule` **TestRule** method for more details of these
return values, for the structure of the _RuleChecks_ and _Actions_ array
entries, and for the event structure.

## CheckFilterRules RuleChecks => \[\], Actions => \[\], TriggerType => ...,

For the given event, append details of matching filter rules to the
_RuleChecks_ array reference, and append details of the actions which should
be performed due to those matches to the _Actions_ array reference.

A _Ticket_ should be supplied, either as an ID or as an `RT::Ticket` object.

If _IncludeDisabled_ is true, then even rules marked as disabled will be
checked.  The default is false.

If _DescribeAll_ is true, then all conditions for all filter rules will be
added to _RuleChecks_ regardless of whether they influenced the outcome;
this can be used to present the operator with details of how an event would
be processed.

If _RecordMatch_ is true, then the fact that a rule is matched will be
recorded in the database (see `RT::FilterRuleMatch`).  The default is not
to record the match.

A _Cache_ should be provided, pointing to a hash reference to store
information in while processing this event, which the caller should share
with the **CheckGroupRequirements** method and other instances of this class,
for the same event.

Returns ( _$Matched_, _$Message_, _$EventValue_, _$TargetValue_ ), where
_$Matched_ will be true if there were any filter rule matches, false
otherwise, and the other parameters will be related to the last rule
matched.

See the `RT::FilterRule` **TestRule** method for more details of these
return values, for the structure of the _RuleChecks_ and _Actions_ array
entries, and for the event structure.

## MoveUp

Move this filter rule group up in the sort order so it is processed earlier. 
Returns ( _$ok_, _$message_ ).

## MoveDown

Move this filter rule group down in the sort order so it is processed later. 
Returns ( _$ok_, _$message_ ).

## Move OFFSET

Change this filter rule group's sort order by the given _OFFSET_.

## \_Set Field => FIELD, Value => VALUE

Set the value of a field, recording a transaction in the process if
appropriate.  Returns ( _$ok_, _$message_ ).

## CurrentUserCanSee

Return true if the current user has permission to see this object.

## \_CoreAccessible

Return a hashref describing the attributes of the database table for the
`RT::FilterRuleGroup` class.

# Internal package RT::FilterRuleGroups

This package provides the `RT::FilterRuleGroups` class, which describes a
collection of filter rule groups.

# Internal package RT::FilterRule

This package provides the `RT::FilterRule` class, which describes a filter
rule - the conditions it must meet, the conditions it must _not_ meet, and
the actions to perform on the ticket if the rule matches.

The attributes of this class are:

- **id**

    The numeric ID of this filter rule

- **FilterRuleGroup**

    The numeric ID of the filter rule group to which this filter rule belongs
    (also presented as an `RT::FilterRuleGroup` object via
    **FilterRuleGroupObj**)

- **IsGroupRequirement**

    Whether this is a filter rule which describes requirements for the filter
    rule group as a whole to be applicable (true), or a filter rule for
    processing an event through and performing actions if matched (false).

    This is true for requirement rules under a rule group's
    **GroupRequirements**, and false for filter rules under a rule group's
    **FilterRules**.

    This attribute is set automatically when a `RT::FilterRule` object is
    created via the **AddGroupRequirement** and **AddFilterRule** methods of
    `RT::FilterRuleGroup`.

- **SortOrder**

    The order of processing - filter rules with a lower sort order are processed
    first

- **Name**

    The displayed name of this filter rule

- **TriggerType**

    The type of action which triggers this filter rule - one of:

    - _Create_

        Consider this rule on ticket creation

    - _QueueMove_

        Consider this rule when the ticket moves between queues

- **StopIfMatched**

    If this is true, then processing of the remaining rules in this filter rule
    group should be skipped if this rule matches (this field is unused for
    filter rule group requirement rules, i.e. where **IsGroupRequirement** is 1)

- **Conflicts**

    Conditions which, if _any_ are met, mean this rule cannot match; this is
    presented as an array of `RT::FilterRule::Condition` objects, and stored as
    a Base64-encoded string encoding an array ref containing hash refs.

- **Requirements**

    Conditions which, if _all_ are met, mean this rule matches, so long as none
    of the conflict conditions above have matched; this is also presented as an
    array of `RT::FilterRule::Condition` objects, and stored in the same way as
    above.

- **Actions**

    Actions to carry out on the ticket if the rule matches (this field is unused
    for filter rule group requirement rules, i.e. where **IsGroupRequirement**
    is 1); it is presented as an array of `RT::FilterRule::Action` objects, and
    stored as a Base64-encoded string encoding an array ref containing hash
    refs.

- **Creator**

    The numeric ID of the creator of this filter rule (also presented as an
    `RT::User` object via **CreatorObj**)

- **Created**

    The date and time this filter rule was created (also presented as an
    `RT::Date` object via **CreatedObj**)

- **LastUpdatedBy**

    The numeric ID of the user who last updated the properties of this filter
    rule (also presented as an `RT::User` object via **LastUpdatedByObj**)

- **LastUpdated**

    The date and time this filter rule's properties were last updated (also
    presented as an `RT::Date` object via **LastUpdatedObj**)

- **Disabled**

    Whether this filter rule is disabled; the filter rule is active unless this
    property is true

# RT::FilterRule METHODS

Note that additional methods will be available, inherited from
`RT::Record`.

## Create Name => Name, ...

Create a new filter rule with the supplied properties, as described above. 
The sort order will be set to 1 more than the highest current value so that
the new item appears at the end of the list.

Returns ( _$id_, _$message_ ), where _$id_ is the ID of the new object,
which will be undefined if there was a problem.

## FilterRuleGroupObj

Return an `RT::FilterRuleGroup` object containing this filter rule's filter
rule group.

## Conflicts

Return an array of `RT::FilterRule::Condition` objects describing the
conditions which, if _any_ are met, mean this rule cannot match.

## SetConflicts CONDITION, CONDITION, ...

Set the conditions which, if _any_ are met, mean this rule cannot match. 
Expects an array of `RT::FilterRule::Condition` objects.

## DescribeConflicts

Return HTML, localised to the current user, describing the conflict
conditions.  Uses **DescribeConditions**.

## Requirements

Return an array of `RT::FilterRule::Condition` objects describing the
conditions which, if _all_ are met, mean this rule matches, so long as none
of the conflict conditions above have matched.

## SetRequirements CONDITION, CONDITION, ...

Set the conditions which, if _all_ are met, mean this rule matches, so long
as none of the conflict conditions above have matched.  Expects an array of
`RT::FilterRule::Condition` objects.

## DescribeRequirements

Return HTML, localised to the current user, describing the requirement
conditions.  Uses **DescribeConditions**.

## DescribeConditions AGGREGATOR, CONDITION, ...

Return HTML, localised to the current user, describing the given conditions,
with the given aggregator word (such as "or" or "and") between each one.

This is called by **DescribeConflicts** and **DescribeRequirements**.

Uses `$HTML::Mason::Commands::m`'s **notes** method for caching, as this is
only expected to be called from user-facing components.

## Actions

Return an array of `RT::FilterRule::Action` objects describing the actions
to carry out on the ticket if the rule matches.

## SetActions ACTION, ACTION, ...

Set the actions to carry out on the ticket if the rule matches; this field
is unused for filter rule group requirement rules (where
**IsGroupRequirement** is 1).  Expects an array of `RT::FilterRule::Action`
objects.

## DescribeActions

Return HTML, localised to the current user, describing this filter rule's
actions.

Uses `$HTML::Mason::Commands::m`'s **notes** method for caching, as this is
only expected to be called from user-facing components.

## Delete

Delete this filter rule, and all of its history.  Returns ( _$ok_,
_$message_ ).

## MatchHistory

Return an `RT::FilterRuleMatches` collection containing all of the times
this filter rule matched an event.

## TestRule RuleChecks => \[\], Actions => \[\], TriggerType => TYPE, From => FROM, To => TO, DescribeAll => 0

Test the event described in the parameters against the conditions in this
filter rule, returning ( _$Matched_, _$Message_, _$EventValue_,
_$TargetValue_ ), where _$Matched_ is true if the rule matched,
_$Message_ describes the match, _$EventValue_ is the value from the event
that led to the result, and _$TargetValue_ is the value the event was
checked against which let to the result.

Details of this rule and the checked conditions will be appended to the
_RuleChecks_ array reference, and the actions this rule contains will be
appended to the _Actions_ array reference.

The _TriggerType_ should be one of the valid _TriggerType_ attribute
values listed above in the `RT::FilterRule` class attributes documentation.

For a _TriggerType_ of **Create**, indicating a ticket creation event, the
_To_ parameter should be the ID of the queue the ticket was created in.

For a _TriggerType_ of **QueueMove**, indicating a ticket moving from one
queue to another, the _From_ parameter should be the ID of the queue the
ticket was in before the move, and the _To_ parameter should be the ID of
the queue the ticket moved into.

If _DescribeAll_ is true, then all conditions for this filter rule will be
added to _RuleChecks_ regardless of whether they influenced the outcome;
this can be used to present the operator with details of how an event would
be processed.

For instance, when _DescribeAll_ is false, if the rule did not match
because of a conflict condition, then only the conflict conditions up to and
including the first match will be included.

A _Cache_ should be provided, pointing to a hash reference shared with
other calls to this method for the same event.

One entry will be added to the _RuleChecks_ array reference, consisting of
a hash reference with these keys:

- **Matched**

    Whether the whole rule matched

- **Message**

    Description associated with the whole rule match status

- **EventValue**

    The value from the event which led to the whole rule match status

- **TargetValue**

    The value, in the final condition which led to the whole rule match status,
    which was tested against the _EventValue_

- **FilterRule**

    This `RT::FilterRule` object

- **MatchType**

    The type of condition which caused this rule to match - blank if the rule
    did not match, or either `Conflict` or `Requirement` (see the
    _Conditions_ **MatchType** description beolow)

- **Conflicts**

    An array reference containing one entry for each condition checked from this
    filter rule's **Conflicts**, each of which is a hash reference of condition
    checks as described below.

- **Requirements**

    An array reference containing one entry for each condition checked from this
    filter rule's **Requirements**, each of which is a hash reference of
    condition checks as described below.

The conditions check hash reference provided in each entry of the
_Conflicts_ and _Requirements_ array references contain the following
keys:

- **Condition**

    The `RT::FilterRule::Condition` object describing this condition

- **Matched**

    Whether this condition matched (see the note about _DescribeAll_ above)

- **Checks**

    An array reference containing one entry for each value checked in the
    condition (since conditions can have multiple OR values), stopping at the
    first match unless _DescribeAll_ is true; each entry is a hash reference
    containing the following keys:

    - **Matched**

        Whether this check succeeded

    - **Message**

        Description associated with this check's match status

    - **EventValue**

        The value from the event which led to this check's match status

    - **TargetValue**

        The target value that the event was checked against

Each entry added to the _Actions_ array reference will be a hash reference
with these keys:

- **FilterRule**

    This `RT::FilterRule` object

- **Action**

    The `RT::FilterRule::Action` object describing this action

## RecordMatch Ticket => ID

Record the fact that an event relating to the given ticket matched this
filter rule.

## MatchCount HOURS

Return the number of times this rule has matched in the past _HOURS_ hours,
or the number of times it has ever matched if _HOURS_ is zero.

## MoveUp

Move this filter rule up in the sort order so it is processed earlier. 
Returns ( _$ok_, _$message_ ).

## MoveDown

Move this filter rule down in the sort order so it is processed later. 
Returns ( _$ok_, _$message_ ).

## Move OFFSET

Change this filter rule's sort order by the given _OFFSET_.

## \_Set Field => FIELD, Value => VALUE

Set the value of a field, recording a transaction in the process if
appropriate.  Returns ( _$ok_, _$message_ ).

## CurrentUserCanSee

Return true if the current user has permission to see this object.

## \_CoreAccessible

Return a hashref describing the attributes of the database table for the
`RT::FilterRule` class.

# Internal package RT::FilterRule::Condition

This package provides the `RT::FilterRule::Condition` class, which
describes a condition in a filter rule and provides methods to match an
event on a ticket against that condition.

Objects of this class are not stored directly in the database, but are
encoded within attributes of `RT::FilterRule` objects.

# RT::FilterRule::Condition METHODS

This class inherits from `RT::Base`.

## new $UserObj\[, PARAMS...\]

Construct and return a new object, given an `RT::CurrentUser` object.  Any
other parameters are passed to **Set** below.

## Set Key => VALUE, ...

Set parameters of this condition object.  The following parameters define
the condition itself:

- **ConditionType**

    The type of condition, such as _InQueue_, _FromQueue_, _SubjectContains_,
    and so on - see the `RT::Extension::FilterRules` method **ConditionTypes**.

- **CustomField**

    The custom field ID associated with this condition, if applicable

- **Values**

    Array reference containing the list of values to match against, any one of
    which will mean this condition has matched

The following parameters define the event being matched against:

- **TriggerType**

    The action which triggered this check, such as _Create_ or _QueueMove_

- **From**

    The value the ticket is changing from

- **To**

    The value the ticket is changing to (the same as _From_ on ticket creation)

- **Ticket**

    The `RT::Ticket` object to match the condition against

Finally, **Cache** should be set to a hash reference, which should be
shared across all **Test** or **TestSingleValue** calls for this event;
lookups such as ticket subject, custom field ID to name mappings, and so on,
will be cached here so that they don't have to be done multiple times.

This method returns nothing.

## TestCondition \[PARAMS, Checks => ARRAYREF, DescribeAll => 1\]

Test the event described in the parameters against this condition, returning
( _$Matched_, _$Message_, _$EventValue_, _$TargetValue_ ), where
_$Matched_ is true if the condition matched, _$Message_ describes the
match, _$EventValue_ is the value from the event that led to the result,
and _$TargetValue_ is the value the event was checked against which let to
the result.

Appends details of the checks performed to the _Checks_ array reference,
where each addition is a hash reference of _Matched_, _Message_,
_EventValue_, _TargetValue_, as described above and in the
`RT::FilterRule` **TestRule** method.

If additional parameters are supplied, they are run through **Set** above
before the test is performed.

The _DescribeAll_ parameter, and the contents of the _Checks_ array
reference, are described in the documentation of the `RT::FilterRule`
**TestRule** method.

## TestSingleValue PARAMS, TargetValue => VALUE

Test the event described in the parameters against this condition, returning
( _$matched_, _$message_, _$eventvalue_ ), where only the specific
_VALUE_ is tested against the event's _From_/_To_/_Ticket_ - the
specific event value tested against is returned in _$eventvalue_.

This is called internally by the **Test** method for each of the value checks
in the condition.

## Properties

Return the properties of this object as a hash reference, suitable for
serialising and storing.

## ConditionType

Return the condition type.

## CustomField

Return the custom field ID associated with this condition.

## Values

Return the value array associated with this condition.

## TriggerType

Return the trigger type of the event being tested against this condition.

## From

Return the moving-from value of the event being tested against this
condition.

## To

Return the moving-to value of the event being tested against this condition.

## TicketQueue

Return the ticket queue ID associated with the ticket being tested, caching
it locally.

## TicketSubject

Return the ticket subject associated with the event being tested, caching it
locally.

## TicketPriority

Return the priority of the ticket associated with the event being tested,
caching it locally.

## TicketStatus

Return the status of the ticket associated with the event being tested,
caching it locally.

## TicketCustomFieldValue CUSTOMFIELDID

Return the value of the custom field with the given ID attached to the
ticket associated with the event being tested, caching it locally.

## TicketRequestorEmailAddresses

Return an array of the requestor email addresses of the event's ticket,
caching it locally.

## TicketRecipientEmailAddresses

Return an array of the recipient email addresses of the event's ticket,
caching it locally.

## TicketFirstCommentText

Return the first comment of the event's tickets, in text, caching it
locally.  If the first comment is in HTML, it is converted to plain text.

## \_All

Return the results of an "All" condition check.

## \_InQueue

Return the results of an "InQueue" condition check.

## \_FromQueue

Return the results of a "FromQueue" condition check.

## \_ToQueue

Return the results of a "ToQueue" condition check.

## \_RequestorEmailIs

Return the results of a "RequestorEmailIs" condition check.

## \_RequestorEmailDomainIs

Return the results of a "RequestorEmailDomainIs" condition check.

## \_RecipientEmailIs

Return the results of a "RecipientEmailIs" condition check.

## \_SubjectContains

Return the results of a "SubjectContains" condition check.

## \_SubjectOrBodyContains

Return the results of a "SubjectOrBodyContains" condition check.

## \_BodyContains

Return the results of a "BodyContains" condition check.

## \_HasAttachment

Return the results of a "HasAttachment" condition check.

## \_PriorityIs

Return the results of a "PriorityIs" condition check.

## \_PriorityUnder

Return the results of a "PriorityUnder" condition check.

## \_PriorityOver

Return the results of a "PriorityOver" condition check.

## \_CustomFieldIs

Return the results of a "CustomFieldIs" condition check.

## \_CustomFieldContains

Return the results of a "CustomFieldContains" condition check.

## \_StatusIs

Return the results of a "StatusIs" condition check.

# Internal package RT::FilterRule::Action

This package provides the `RT::FilterRule::Action` class, which describes
an action to perform on a ticket after matching a rule.

Objects of this class are not stored directly in the database, but are
encoded within attributes of `RT::FilterRule` objects.

# RT::FilterRule::Action METHODS

This class inherits from `RT::Base`.

## new $UserObj\[, PARAMS...\]

Construct and return a new object, given an `RT::CurrentUser` object.  Any
other parameters are passed to **Set** below.

## Set Key => VALUE, ...

Set parameters of this action object.  The following parameters define the
action itself:

- **ActionType**

    The type of action, such as _SetSubject_, _SetQueue_, and so on - see the
    `RT::Extension::FilterRules` method **ActionTypes**.

- **CustomField**

    The custom field ID associated with this action, if applicable (such as
    which custom field to set the value of)

- **Value**

    The value associated with this action, if applicable, such as the queue to
    move to, or the contents of an email to send, or the email address or group
    ID to add as a watcher

- **Notify**

    The notification recipient associated with this action, if applicable, such
    as a group ID or email address to send a message to

The following parameters define the ticket being acted upon:

- **Ticket**

    The `RT::Ticket` object to perform the action on

Finally, **Cache** should be set to a hash reference, which should be
shared across all **Test** or **TestSingleValue** calls for this event;
lookups such as ticket subject, custom field ID to name mappings, and so on,
will be cached here so that they don't have to be done multiple times.

This method returns nothing.

## Perform FILTERRULE, TICKETOBJ

Perform the action described by this object's parameters, returning (
_$ok_, _$message_ ), checking that the associated ticket has not recently
been touched by the same filter rule to avoid recursion.

## IsNotification

Return true if this action is of a type which sends a notification, false
otherwise.  This is used when carrying out actions to ensure that all other
ticket actions are performed first.

## Properties

Return the properties of this object as a hash reference, suitable for
serialising and storing.

## ActionType

Return the action type.

## CustomField

Return the custom field ID associated with this action.

## Value

Return the value associated with this action.

## Notify

Return the notification email address or group ID associated with this
action.

## Ticket

Return the ticket object that this action is being performed on.

## \_None

Return ( _$ok_, _$message_ ) after performing the "None" action.

## \_SubjectPrefix

Return ( _$ok_, _$message_ ) after performing the "SubjectPrefix" action.

## \_SubjectSuffix

Return ( _$ok_, _$message_ ) after performing the "SubjectSuffix" action.

## \_SubjectRemoveMatch

Return ( _$ok_, _$message_ ) after performing the "SubjectRemoveMatch" action.

## \_SubjectSet

Return ( _$ok_, _$message_ ) after performing the "SubjectSet" action.

## \_PrioritySet

Return ( _$ok_, _$message_ ) after performing the "PrioritySet" action.

## \_PriorityAdd

Return ( _$ok_, _$message_ ) after performing the "PriorityAdd" action.

## \_PrioritySubtract

Return ( _$ok_, _$message_ ) after performing the "PrioritySubtract" action.

## \_StatusSet

Return ( _$ok_, _$message_ ) after performing the "StatusSet" action.

## \_QueueSet

Return ( _$ok_, _$message_ ) after performing the "QueueSet" action.

## \_CustomFieldSet

Return ( _$ok_, _$message_ ) after performing the "CustomFieldSet" action.

## \_RequestorAdd

Return ( _$ok_, _$message_ ) after performing the "RequestorAdd" action.

## \_RequestorRemove

Return ( _$ok_, _$message_ ) after performing the "RequestorRemove" action.

## \_CcAdd

Return ( _$ok_, _$message_ ) after performing the "CcAdd" action.

## \_CcAddGroup

Return ( _$ok_, _$message_ ) after performing the "CcAddGroup" action.

## \_CcRemove

Return ( _$ok_, _$message_ ) after performing the "CcRemove" action.

## \_AdminCcAdd

Return ( _$ok_, _$message_ ) after performing the "AdminCcAdd" action.

## \_AdminCcAddGroup

Return ( _$ok_, _$message_ ) after performing the "AdminCcAddGroup" action.

## \_AdminCcRemove

Return ( _$ok_, _$message_ ) after performing the "AdminCcRemove" action.

## \_Reply

Return ( _$ok_, _$message_ ) after performing the "Reply" action.

## \_NotifyEmail

Return ( _$ok_, _$message_ ) after performing the "NotifyEmail" action.

## \_NotifyGroup

Return ( _$ok_, _$message_ ) after performing the "NotifyGroup" action.

# Internal package RT::FilterRules

This package provides the `RT::FilterRules` class, which describes a
collection of filter rules.

# Internal package RT::FilterRuleMatch

This package provides the `RT::FilterRuleMatch` class, which records when
a filter rule matched an event on a ticket.

The attributes of this class are:

- **id**

    The numeric ID of this event

- **FilterRule**

    The numeric ID of the filter rule which matched (also presented as an
    `RT::FilterRule` object via **FilterRuleObj**)

- **Ticket**

    The numeric ID of the ticket whose event matched this rule (also presented
    as an `RT::Ticket` object via **TicketObj**)

- **Created**

    The date and time this event occurred (also presented as an `RT::Date`
    object via **CreatedObj**)

# RT::FilterRuleMatch METHODS

Note that additional methods will be available, inherited from
`RT::Record`.

## Create FilterRule => ID, Ticket => ID

Create a new filter rule match object with the supplied properties, as
described above.  The _FilterRule_ and _Ticket_ can be passed as integer
IDs or as `RT::FilterRule` and `RT::Ticket` objects.

Returns ( _$id_, _$message_ ), where _$id_ is the ID of the new object,
which will be undefined if there was a problem.

## FilterRuleObj

Return an `RT::FilterRule` object containing this filter rule match's
matching filter rule.

## TicketObj

Return an `RT::Ticket` object containing this filter rule match's matching
ticket.

## \_CoreAccessible

Return a hashref describing the attributes of the database table for the
`RT::FilterRuleMatch` class.

# Internal package RT::FilterRuleMatches

This package provides the `RT::FilterRuleMatches` class, which describes a
collection of filter rule matches.

# AUTHOR

Andrew Wood

<div>
    <p>All bugs should be reported via email to <a
    href="mailto:bug-RT-Extension-FilterRules@rt.cpan.org">bug-RT-Extension-FilterRules@rt.cpan.org</a>
    or via the web at <a
    href="http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-FilterRules">rt.cpan.org</a>.</p>
</div>

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Andrew Wood

This is free software, licensed under:

    The GNU General Public License, Version 2, June 1991
