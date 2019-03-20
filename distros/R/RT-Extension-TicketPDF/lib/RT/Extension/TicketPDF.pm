package RT::Extension::TicketPDF;

use 5.006;
use strict;
use warnings;

=head1 NAME

RT::Extension::TicketPDF - make pdfs from tickets.

=cut

our $VERSION = '0.1.3';

=head1 SYNOPSIS

Use wkhtmltopdf to display a Ticket as a pdf.

    https://support.example.com/rt/Ticket/PDF/Display.pdf?id=1

=head1 INSTALL

    Requires: included wkhtmltopdf, IPC::Cmd

    perl Makefile.PL
    make
    make install

    # Enable this plugin in your RT_SiteConfig.pm:
    Plugin('RT::Extension::TicketPDF');

    # For pre-RT 4.4.5, patch RT
    patch -p1 -d /opt/rt4 < patches/show-history.patch

This extension provides a legacy version of C<wkhtmltopdf> which works
on Linux systems. Newer versions of the utility have issues importing
local CSS and JS resources and currently do not work with this extension.

=head1 SUPPORT

Please report any bugs at either:

    L<http://search.cpan.org/dist/RT-Extension-TicketPDF/>
    L<https://github.com/coffeemonster/rt-extension-ticketpdf>

wkhtmltopdf known-issues:

    images render blank - This is a limitation with v10. Use JPG's for all images.
    QPixmap > Seg-fault - A bug with v11rc1 use v10rc2


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alister West, C<< <alister at alisterwest.com> >>

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=head1 CHANGES

0.1.3  2019-02-27
    - Updates for RT 4.4
    - Update converter path to find the default install location

0.1.2  2012-12-20
    - Use binary in local $RT::LocalPath/bin/wkhtmltopdf instead of /usr/bin/..
    - Including wkhtmltopdf v10.0rc2 to avoid QPixmap Seg-fault bug in v11.0rc1
    - GeneratePDF menu item added.
    - Simple Template added.

0.1.1  2012-12-19
    - Inital Release

=cut


1;
__END__
