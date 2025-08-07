use strict;
use warnings;
package RT::Extension::ChangeManagement;

our $VERSION = '1.00';

=head1 NAME

RT-Extension-ChangeManagement - Change Management configuration for RT

=head1 RT VERSION

Works with RT 6. For previous versions of RT install the latest 0.* version.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt6/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::ChangeManagement');

=item C<make initdb>

Only run this the first time you install this module. If you run this twice,
you may end up with duplicate data in your database.

=item Clear your mason cache

    rm -rf /opt/rt6/var/mason_data/obj

=item Restart your webserver

=back

=head1 UPGRADING

To upgrade from an earlier version, see the instructions in the L<UPGRADING|UPGRADING.pod>
document.

=head1 DESCRIPTION

This extension provides the configuration to implement a change management
process in L<Request Tracker|https://bestpractical.com/request-tracker>.

Organizations working to standardize internal processes for ISO or
SOC compliance must have a standardized way to deploy and track changes to
software, hardware, infrastructure, etc. This extension implements a
change management system within RT, providing a framework for handling a
variety of change types. It uses all core RT features, so everything can be
modified as needed to align with your organization's practices and procedures.
As-is, it provides a simple, fully functional implementation of an ITIL-like
change management process.

To provide additional validation and required fields for different stages of
the process, you can install L<RT::Extension::MandatoryOnTransition>. An example
configuration is provided in the sample configuration file in C<etc/ChangeManagement_Config.pm>.

L<We've provided a walkthrough video|https://youtu.be/uQEEf7SGlkg> to demonstrate
some of the functionality available in the change management extension.

=head2 Change Management Queue

After installing, you'll see a new queue called B<Change Management> for tracking
all of the incoming change requests. You can change the name to anything you like
after installing. In a typical configuration, you will also want to assign an RT
email address, like I<changes@example.com> or I<crb@example.com> (Change Review Team)
to create tickets in this queue.

=head3 Rights

By default, Everyone can see the queue, create tickets, and view tickets. All
users can also set custom fields on create, but only then. You can grant more
rights if your change requestors need to update custom fields after the
ticket is created.

The Change Management group has more rights to work on change tickets including
taking ownership and approving or rejecting requests.

Some custom rights are available if you go to Admin > Queues, click on
Change Management, then click Group Rights. The "Status changes" tab has
specific rights to allow users to "Approve Requests" and "Implement Changes".
By default, the Change Reviewer role can "Approve Requests" and the
Change Implementor role can "Implement Changes". If this is too restrictive
for your workflow, you can grant these to more users, possibly via a group.

=head2 Custom Roles

The roles below are allow you to assign different users to parts of the change
management process. In addition to clearly identifying who is responsible for
parts of the process, these roles can be used to manage rights and notifications
like email.

=over

=item Change Reviewer

Person who reviews incoming change requests, and is responsible for approving or
denying a change request.

=item Change Implementor

Person who is responsible for implementing a change request.

=back

=head2 Groups

Groups are included to make it easy to add users quickly and give
them sufficient rights to interact with the Change Management queue.

The Change Management group gives a set of rights appropriate for staff who
will work with chagne management tickets. It allows them to take tickets,
comment, change custom fields, etc. You can refine all of these after you
install the extension.

=head2 Change Management Lifecycle

The Change Management lifecycle provides a set of common statuses. You can update
this as needed to add or remove statuses and transitions.

=over

=item Requested

Status given to a new change request. Indicates than a change has been requested and is
awaiting approval.

=item Approved

For changes that are approved but not yet implemented.

=item In Progress

An approved change that is in the process of being deployed.

=item Partially Deployed

The change has been partially deployed; it is either taking an unusually long time
to complete, or part of the deployment succeeded while another part failed. Reasons
as to why should be detailed in a comment.

=item Deployed

The change has been deployed successfully.

=item Failed

The change failed to deploy. Reasons should be detailed in a comment.

=item Cancelled

This change was cancelled. Reasoning should be provided in a comment.

=item Rejected

The change was rejected by the review team. Reasoning should be provided in a
comment on the ticket.

=back

=head2 Custom Fields

Some common custom fields are provided to track additional information about
changes. The provided custom fields can be modified as needed, to add or remove
available values in dropdowns, for example.

You can also add more custom fields as needed. A C<%CustomFieldGroupings> configuration
is provided to group custom fields in a Change Management portlet. You can add
new custom fields to this configuration to include them in this section.

=head3 Change Category

Specifies the kind of change that is to be performed.

=head3 Change Type

One of the three types of changes. The initial values are those
outlined in ITIL:

=over

=item Standard

A low risk, pre-authorized change that follows a repeatable process. This is the
default for new tickets in the Change Management queue.

=item Emergency

A change that must be performed ASAP, potentially bypassing approval steps.

=item Normal

Any change that doesn't fall into the other types.

=back

=head3 Rollback Plan

A description of the steps necessary to perform a rollback of the proposed
changes in the event that the deployment process is unsuccessful.

=head3 Change Started

Date that the change was started. This is B<not> the same as the normal Started
date on the ticket. Started is set when the ticket is moved to an open status
(such as approved); Change Started is when someone actually started implementing
the change.

A scrip is provided to automatically set this when status changes to
in progress or partially deployed.

=head3 Change Complete

Date that the change was successfully deployed. A scrip is provided to automatically
set this when status changes to deployed.

=head2 Change Management Dashboard

A Change Management dashboard is installed with two saved searches included,
one for upcoming changes and one for recently completed changes. These are
useful for tracking change tickets and are also good examples of the types of
saved searches and dashboards you can create for different participants in the
change process.

=head1 CUSTOMIZING AND EXTENDING

Since this extension uses core RT features, it's easy for an RT administrator
to customize various parts. Below are some ideas.

=head2 Additional Custom Fields

Some ideas of fields that could be added to the change management process might include:

=over

=item Change Origin

Customer, Vendor, Internal. Dropdown.

=item Location

Datacenter, customer site, etc. Text.

=item Implementation Steps

Steps needed to implement proposed change. Text.

=item Validation Steps

Process for validating a change was deployed successfully. Text.

=item Impact Assessment

A description of what potential side effects of a proposed change might be, what
could happen if the change goes awry, etc. Text.

=back

=head3 Making Custom Fields Required

Using L<RT::Extension::MandatoryOnTransition>, any of the above fields can be made
required upon a status change. For example, you may wish to make Implementation Steps,
Validation Steps, and Impact Assessment required fields before a change request can
be approved. See F<etc/ChangeManagement_Config.pm> for a ready-to-use example with
the out of the box configuration.

=head3 Default Values for Custom Fields

As an RT admin, you can go to Admin > Queues > Change Management, then click on
Default Values in the submenu. From that page, you can set or change the default
values for assigned custom fields.

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=for html <p>All bugs should be reported via email to <a
href="mailto:bug-RT-Extension-ChangeManagement@rt.cpan.org">bug-RT-Extension-ChangeManagement@rt.cpan.org</a>
or via the web at <a
href="http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-ChangeManagement">rt.cpan.org</a>.</p>

=for text
    All bugs should be reported via email to
        bug-RT-Extension-ChangeManagement@rt.cpan.org
    or via the web at
        http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-ChangeManagement

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Best Practical Solutions, LLC.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
