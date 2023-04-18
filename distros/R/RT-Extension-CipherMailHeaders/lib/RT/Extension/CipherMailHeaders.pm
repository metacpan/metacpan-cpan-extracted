use strict;
use warnings;
package RT::Extension::CipherMailHeaders;

our $VERSION = '1.00';

=head1 NAME

RT-Extension-CipherMailHeaders - Show CipherMail Information in Ticket History

=head1 DESCRIPTION

RT includes its own handling of PGP and S/MIME encryption and contains
code to display the signing/encryption status of incoming mails.

If the cryptography is outsourced to a CipherMail installation, then
different headers - added by CipherMail - indicate whether an incoming
email was signed or encrypted.

This extension displays that information in similar way as the
RT-builtin crypto results would be shown.

=head1 RT VERSION

This module was developed and tested with RT version 5.0.3, but as the code is pretty basic, it is likely 
to work with older (and hopefully future) versions as well.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt5/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::CipherMailHeaders');

=item Clear your mason cache

    rm -rf /opt/rt5/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Otmar Lendl E<lt>lendl@cert.atE<gt>

Please report bugs by email.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by CERT.at GmbH

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
