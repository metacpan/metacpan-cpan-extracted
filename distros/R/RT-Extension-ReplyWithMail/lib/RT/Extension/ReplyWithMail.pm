use strict;
use warnings;
package RT::Extension::ReplyWithMail;

our $VERSION = '0.01';

=head1 NAME

RT-Extension-ReplyWithMail - Reply to the ticker using your default mail client

=head1 DESCRIPTION

This extension adds an extra action in your actions menu, named "ReplyWithMail". This action uses the mailto: HTML tag to generate a base mail structure, so that you can reply using your native email client instead of RT's WebUI

=head1 RT VERSION

Works with RT 5.0.2

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::ReplyWithMail');

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Averkios Averkiadis E<lt>averkios at outlook dot comE<gt>

=for html <p>All bugs should be reported via email to <a
href="mailto:bug-RT-Extension-ReplyWithMail@rt.cpan.org">bug-RT-Extension-ReplyWithMail@rt.cpan.org</a>
or via the web at <a
href="http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-ReplyWithMail">rt.cpan.org</a>.</p>

=for text
    All bugs should be reported via email to
        bug-RT-Extension-ReplyWithMail@rt.cpan.org
    or via the web at
        http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-ReplyWithMail

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Averkios Averkiadis

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
