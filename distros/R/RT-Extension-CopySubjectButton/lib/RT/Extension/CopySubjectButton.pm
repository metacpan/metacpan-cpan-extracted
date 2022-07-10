use strict;
use warnings;
package RT::Extension::CopySubjectButton;

our $VERSION = '0.01';

=head1 NAME

RT-Extension-CopySubjectButton - Button that copies the subject in proper format for mail client reply

=head1 DESCRIPTION

Adds a button next to the subject header, of a ticket, that copies the subject in proper format to reply using a mail client. Just paste it in the subject line of your mail reply.

=head1 RT VERSION

Works with RT 5.0.2

[Make sure to use requires_rt and rt_too_new in Makefile.PL]

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt5/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::CopySubjectButton');

=item Clear your mason cache

    rm -rf /opt/rt5/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Averkios Averkiadis E<lt>aaverkios at outlook dot comE<gt>

=for html <p>All bugs should be reported via email to <a
href="mailto:bug-RT-Extension-CopySubjectButton@rt.cpan.org">bug-RT-Extension-CopySubjectButton@rt.cpan.org</a>
or via the web at <a
href="http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-CopySubjectButton">rt.cpan.org</a>.</p>

=for text
    All bugs should be reported via email to
        bug-RT-Extension-CopySubjectButton@rt.cpan.org
    or via the web at
        http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-CopySubjectButton

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Averkios Averkiadis

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
