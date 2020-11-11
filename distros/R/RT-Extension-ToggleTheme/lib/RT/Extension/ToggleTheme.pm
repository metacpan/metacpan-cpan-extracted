use strict;
use warnings;
package RT::Extension::ToggleTheme;

RT->AddJavaScript('themes.js');
RT->AddJavaScript('fontawesome-icons.js');

our $VERSION = '0.02';

=head1 NAME

RT-Extension-ToggleTheme - Toggle elevator light and dark theme.

=head1 DESCRIPTION

To save your eyes in the dark.

=head1 RT VERSION

Works with RT 5

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt5/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::ToggleTheme');

=item Clear your mason cache

    rm -rf /opt/rt5/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Craig Kaiser E<lt>modules@ceal.devE<gt>

=cut

1;
