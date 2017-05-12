use strict;
use warnings;
package RT::Extension::LocalDateHeader;

our $VERSION = '1.00';

=head1 NAME

RT-Extension-LocalDateHeader - Display local date for attachment Date header

=head1 DESCRIPTION

The Date: header included in emails received by RT will often be in the
sender's timezone (or possibly forced to UTC by the remote mail server).
This extension will rewrite the Date: header to the user's timezone
while also displaying the original Date: next to it. This reduces
confusion when RT lists "Correspondence added" in the user's
timezone but the Date header looks totally different. Most non-
technical users don't know how to interpret the -0000 or -0400
syntax of mail Date: headers.

=for html <p><img src="https://raw.github.com/bestpractical/rt-extension-localdateheader/master/doc/images/extension.png" alt="History Preview in Search Results" /></p>

=head1 RT VERSION

Compatible with RT 4.0 and 4.2.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::LocalDateHeader');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::LocalDateHeader));

or add C<RT::Extension::LocalDateHeader> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-LocalDateHeader@rt.cpan.org|mailto:bug-RT-Extension-LocalDateHeader@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-LocalDateHeader>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2014 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
