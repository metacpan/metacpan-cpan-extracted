use utf8;
use strict;
use warnings;
no warnings qw(redefine);
package RT::Extension::InlineAudioVideoAttachments;

our $VERSION = '0.07';

=encoding utf8

=head1 NAME

RT-Extension-InlineAudioVideoAttachments - Display audio/video attachments inline

=head1 DESCRIPTION

Displays audio and/or video attachments with HTML audio/video player. 

=head1 RT VERSION

Works with RT 4.4 or greater

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt5/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::InlineAudioVideoAttachments');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::InlineAudioVideoAttachments));

or add C<RT::Extension::InlineAudioVideoAttachments> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt5/var/mason_data/obj

=item Restart your webserver

=back

=cut

=head1 AUTHOR

Gérald Sédrati E<lt>gibus@easter-eggs.comE<gt>

=head1 REPOSITORY

L<https://github.com/gibus/RT-Extension-InlineAudioVideoAttachments>

=head1 BUGS

All bugs should be reported via email to

L<bug-RT-Extension-InlineAudioVideoAttachments@rt.cpan.org|mailto:bug-RT-Extension-InlineAudioVideoAttachments@rt.cpan.org>

or via the web at

L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-InlineAudioVideoAttachments>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2018-2022 by Gérald Sédrati, Easter-Eggs

This is free software, licensed under:

The GNU General Public License, Version 3, June 2007

=cut

1;
