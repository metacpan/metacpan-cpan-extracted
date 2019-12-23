use strict;
use warnings;
package RT::Extension::GenerateTickets;
use 5.10.1;

our $VERSION = '0.01';

use RT::Action::GenerateTickets;

=head1 NAME

RT-Extension-GenerateTickets

=head1 DESCRIPTION

Generate multiple tickets dependent of each other

=head1 RT VERSION

Works with RT 4.4 and above

=head1 INSTALLATION

Add this line:

    Plugin('RT::Extension::GenerateTickets');

= Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

= Restart your webserver

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=for html <p>All bugs should be reported via email to <a
href="mailto:bug-RT-Extension-GenerateTickets@rt.cpan.org">bug-RT-Extension-GenerateTickets@rt.cpan.org</a>
or via the web at <a
href="http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-GenerateTickets">rt.cpan.org</a>.</p>

=for text
    All bugs should be reported via email to
        bug-RT-Extension-GenerateTickets@rt.cpan.org
    or via the web at
        http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-GenerateTickets

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by fazekas.balint@mithrandir.hu

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut



1;
