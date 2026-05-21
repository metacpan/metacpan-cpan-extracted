use strict;
use warnings;
package RT::Extension::ToggleTheme;

RT->AddJavaScript('themes.js');

our $VERSION = '1.03';

=head1 NAME

RT-Extension-ToggleTheme - Toggle light and dark theme.

=head1 DESCRIPTION

Adds a light/dark mode toggle button to the RT 6 navigation bar. Works with
any Bootstrap 5 theme. The toggle button displays for users who have the
ModifySelf right and appears in both the privileged and self-service
interfaces.

=head1 RT VERSION

Works with RT 6

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt6/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::ToggleTheme');

=item Clear your mason cache

    rm -rf /opt/rt6/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Craig Kaiser E<lt>modules@ceal.devE<gt>

=cut

1;
