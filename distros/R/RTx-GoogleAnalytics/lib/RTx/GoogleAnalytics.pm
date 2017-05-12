use strict;
use warnings;
package RTx::GoogleAnalytics;

our $VERSION = '0.01';

require RT::Config;
$RT::Config::META{'GoogleAnalytics'} = { Type => 'HASH' };

=head1 NAME

RTx-GoogleAnalytics - Easy configuration of a Google Analytics tracking code for your RT

=head1 INSTALLATION 

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Set(@Plugins, qw(RTx::GoogleAnalytics));

or add C<RTx::GoogleAnalytics> to your existing C<@Plugins> line.

Then set your Google-supplied tracking ID like so:

    Set(%GoogleAnalytics,
        TrackingID  => 'UA-XXXXXXX-N',
        Method      => 'classic',   # may also be 'universal'
    );

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Thomas Sibley <trs@bestpractical.com>

=head1 BUGS

All bugs should be reported via email to
L<bug-RTx-GoogleAnalytics@rt.cpan.org|mailto:bug-RTx-GoogleAnalytics@rt.cpan.org>
or via the web at
L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RTx-GoogleAnalytics>.


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2013 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
