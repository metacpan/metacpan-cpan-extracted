use strict;
use warnings;
package RT::Extension::NotifyBasedOnOwnership;

our $VERSION = '0.01';

=head1 NAME

RT-Extension-NotifyBasedOnOwnership - Adds scrip conditions and actions useful
for suppressing notifications to queue watchers when a ticket becomes owned

=head1 SYNOPSIS

Adds the following conditions to RT:

=over

=item On Create and Unowned

=item On Create and Owned

=item On Correspond and Unowned

=item On Correspond and Owned

=item On Comment and Unowned

=item On Comment and Owned

=back

Adds the following actions to RT:

=over

=item Notify Requestors and Ticket Ccs

=item Notify Owner and Ticket AdminCcs

=item Notify Requestors and Ticket Ccs as Comment

=item Notify Owner and Ticket AdminCcs as Comment

=back

=head1 DESCRIPTION

A typical use of these conditions and actions is to add scrips like the
following:

    On Correspond and Unowned Notify AdminCcs
    On Correspond and Unowned Notify Requestors and Ccs

    On Correspond and Owned Notify Owner and Ticket AdminCcs
    On Correspond and Owned Notify Requestors and Ticket Ccs

    On Comment and Unowned Notify AdminCcs as Comment
    On Comment and Owned Notify Owner and Ticket AdminCcs as Comment

If you add the above, you'll want to replace or disable the stock On Correspond
and On Comment scrips targetting Requestors, Owners, Ccs, and AdminCcs.
Otherwise, RT will send multiple notifications.

Be sure to leave the standard scrips in place which notify "Other Recipients"
so that "One-time Ccs" and "One-time BCcs" still work correctly.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item C<make initdb>

Only run this the first time you install this module.

If you run this twice, you may end up with duplicate data
in your database.

If you are upgrading this module, check for upgrading instructions
in case changes need to be made to your database.

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Set(@Plugins, qw(RT::Extension::NotifyBasedOnOwnership));

or add C<RT::Extension::NotifyBasedOnOwnership> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Thomas Sibley <trs@bestpractical.com>

=head1 BUGS

All bugs should be reported via email to
L<bug-RT-Extension-NotifyBasedOnOwnership@rt.cpan.org|mailto:bug-RT-Extension-NotifyBasedOnOwnership@rt.cpan.org>
or via the web at
L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-NotifyBasedOnOwnership>.


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2013 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
