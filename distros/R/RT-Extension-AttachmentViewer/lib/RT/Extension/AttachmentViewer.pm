package RT::Extension::AttachmentViewer;

use utf8;
use strict;
use warnings;

our $VERSION = '0.04';

=encoding utf8

=head1 NAME

RT::Extension::AttachmentViewer - View full size attachments from the dropzone

=head1 DESCRIPTION

By default, when attachments are to be uploaded in RT, the dropzone where they are added shows a thubmbnail. This extension enhances the attachment dropzone in RT by allowing users to click on a file preview to display it in a modal viewer. It supports images, PDFs, audio, HTML, and text files. Other file types are opened using the browser's default behavior.


=head1 RT VERSION

Works with RT 5 and RT 6.

=head1 INSTALLATION

=over

=item export C<$RTHOME=/home/of/your/RT/installation/lib>

This is needed if your C<RT> installation directory is not C</opt/rt6/> for RT 6 nor C/opt/rt5/> for RT 5.

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F<RT_SiteConfig.pm> (usually located in /opt/rt5/etc or /opt/rt6/etc)

Add this line:

    Plugin('RT::Extension::AttachmentViewer');

or add C<RT::Extension::AttachmentViewer> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt6/var/mason_data/obj

=item Restart your webserver

=back

=cut

=head1 AUTHOR

Gérald Sédrati E<lt>gibus@easter-eggs.comE<gt>

=head1 REPOSITORY

L<https://github.com/gibus/RT-Extension-AttachmentViewer>

=head1 BUGS

All bugs should be reported via email to

L<bug-RT-Extension-AttachmentViewer@rt.cpan.org|mailto:bug-RT-Extension-AttachmentViewer@rt.cpan.org>

or via the web at

L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-AttachmentViewer>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by Gérald Sédrati, Easter-Eggs

This is free software, licensed under:

The GNU General Public License, Version 3, June 2007

=cut

1;
