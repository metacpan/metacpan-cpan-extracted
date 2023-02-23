use strict;
use warnings;
package RT::Extension::7zDownload;

our $VERSION = '1.2';

=head1 NAME

RT-Extension-7zDownload - Download attachment as encrypted 7z file

=head1 DESCRIPTION

Sometimes, especially when using RTIR for CSIRT work, attachments
of tickets might contain malware. 

It is unwise to download such files directly to the user's workstation.
The usual convention is to zip the potentially malicious file into
a password-protected zip / 7z file with the well-known password
"infected".

=head1 RT VERSION

Tested with RT 5.0.3. 

As this extension replaces a Mason component, it is pretty version-
dependent.

Check the lines after "RT-Extension-7zDownload Starts here" in
html/Ticket/Elements/ShowAttachments, it should be easy to 
make the same changes to other versions of RT.

=head1 INSTALLATION

This module needs Archive::SevenZip and the 7z binary.

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

For RT Versions other than 5.0.3, replace the supplied ShowAttachments
file with a patched version of the local RT installation.

=item Edit your F</opt/rt5/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::7zDownload');

=item Clear your mason cache

    rm -rf /opt/rt5/var/mason_data/obj

    (and make sure the permissions are ok afterwards)

=item Restart your webserver

=back

=head1 AUTHOR

Otmar Lendl <lt>lendl@cert.at<gt>

Please report bugs directly to the author.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by CERT.at GmbH

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

# This module is empty, the code is under /html

1;
