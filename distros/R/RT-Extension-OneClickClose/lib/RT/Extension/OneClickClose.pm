use strict;
use warnings;
package RT::Extension::OneClickClose;

our $VERSION = '0.02';

=head1 NAME

RT-Extension-OneClickClose - sets status of a given Ticket to resolved and returns to the previous Search/Results page

=head1 DESCRIPTION

Sometimes it is cumbersome to go through several pages and to close a ticket, OnClickClose resolves a ticket and returns 
to the previous Search Page. Just add AfterSubmit=1 to the "Close" Link

=head1 RT VERSION

Works with RT 4.2


=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::OneClickClose');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::OneClickClose));

or add C<RT::Extension::OneClickClose> to your existing C<@Plugins> line.

to use it use an URL like this

'<B><A HREF="__WebPath__/Ticket/Update.html?Status=resolved&SubmitTicket=1&id=__id__&AfterSubmitReturn=1">OneClickClose</a></B>/TITLE:OneClickClose'

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Mark Hofstertter University of Vienna  E<lt>mark.hofstetter@univie.ac.atE<gt>

=head1 BUGS

All bugs should be reported via web to

    L<https://github.com/MarkHofstetter/RT-Extension-OneClickClose/issues>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2015 by Mark Hofstetter

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
