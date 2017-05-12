package RT::Extension::SpawnLinkedTicketInQueue;

our $VERSION = '1.01';

use 5.008003;
use warnings;
use strict;

=head1 NAME

RT::Extension::SpawnLinkedTicketInQueue - quickly spawn linked tickets in different queues

=head1 DESCRIPTION

After installing this extension, on ticket's page in the Links block
you should see new controls.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::SpawnLinkedTicketInQueue');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::SpawnLinkedTicketInQueue));

or add C<RT::Extension::SpawnLinkedTicketInQueue> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-SpawnLinkedTicketInQueue@rt.cpan.org|mailto:bug-RT-Extension-SpawnLinkedTicketInQueue@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-SpawnLinkedTicketInQueue>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2014 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
