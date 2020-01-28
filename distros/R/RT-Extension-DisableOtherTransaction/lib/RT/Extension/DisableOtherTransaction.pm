use strict;
use warnings;
package RT::Extension::DisableOtherTransaction;

our $VERSION = '0.01';

RT->AddJavaScript('disableothertransaction.js');
RT->AddStyleSheets('disableothertransaction.css');

=head1 NAME

RT-Extension-DisableOtherTransaction - Disables other transaction messages

=head1 DESCRIPTION

Hides the status messages like message sent, and ticket owner changed

=head1 RT VERSION

Works with RT [What versions of RT is this known to work with?]

[Make sure to use requires_rt and rt_too_new in Makefile.PL]

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::DisableOtherTransaction');

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=for html <p>All bugs should be reported via email to <a
href="mailto:bug-RT-Extension-DisableOtherTransaction@rt.cpan.org">bug-RT-Extension-DisableOtherTransaction@rt.cpan.org</a>
or via the web at <a
href="http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-DisableOtherTransaction">rt.cpan.org</a>.</p>

=for text
    All bugs should be reported via email to
        bug-RT-Extension-DisableOtherTransaction@rt.cpan.org
    or via the web at
        http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-DisableOtherTransaction

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by fazekas.balint@mithrandir.hu

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
