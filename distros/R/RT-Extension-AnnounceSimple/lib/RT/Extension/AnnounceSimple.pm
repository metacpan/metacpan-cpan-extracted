package RT::Extension::AnnounceSimple;

use 5.10.1;
use strict;
use warnings;

our $VERSION = '1.01';

=head1 NAME

RT::Extension::AnnounceSimple - Display simple announcements as a banner on RT pages.

=head1 DESCRIPTION

This plugin displays simple announcements as a banner on RT pages.
The global announce is displayed on all pages.
The queue announce is displayed only on the Ticket Display page.

An RT Admin can set the global announce text under Admin > Tools > Announce.
An RT Queue Admin can set the queue announce text under Admin > Queues > Announce.

If you want more than a simple text then have a look at
L<RT::Extension::Announce|https://metacpan.org/pod/RT::Extension::Announce>.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::AnnounceSimple');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::AnnounceSimple));

or add C<RT::Extension::AnnounceSimple> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Christian Loos <cloos@netsandbox.de>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (C) 2015, Christian Loos.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=head1 SEE ALSO

=over

=item L<http://bestpractical.com/rt/>

=item L<RT::Extension::Announce|https://metacpan.org/pod/RT::Extension::Announce>

=back

=cut

1;
