package RT::Extension::CommentOnCreate;

our $VERSION = '1.00';

use warnings;
use strict;
use Carp;


=head1 NAME

RT::Extension::CommentOnCreate - Adds an optional Comment box to Ticket Creation

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::CommentOnCreate');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::CommentOnCreate));

or add C<RT::Extension::CommentOnCreate> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

Optional configuration options to control the width and height of the
Comment textbox:

    Set($CommentOnCreateWidth, 80);
    Set($CommentOnCreateHeight, 190);

These only apply if you have C<MessageBoxRichText> enabled; otherwise it
will inherit the global C<MessageBoxRichTextHeight> attribute.

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-CommentOnCreate@rt.cpan.org|mailto:bug-RT-Extension-CommentOnCreate@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-CommentOnCreate>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2014 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
