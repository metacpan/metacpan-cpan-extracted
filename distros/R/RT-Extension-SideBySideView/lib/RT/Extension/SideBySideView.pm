package RT::Extension::SideBySideView;

use 5.10.1;
use strict;
use warnings;

our $VERSION = '2.00';

$RT::Config::META{'SideBySideView'} = {
    Section         => 'Ticket display',
    Overridable     => 1,
    Widget          => '/Widgets/Form/Boolean',
    WidgetArguments => {
        Description => 'Display History besides Metadata', # loc
        Hints       => '(' . __PACKAGE__ . ')',
    },
};

=head1 NAME

RT::Extension::SideBySideView - SideBySide Ticket View for RT

=head1 DESCRIPTION

Based on an original Idea from Steve Turner (MIT) and Markus Dirr (GreenCircle)
and the ground work of Thomas Sibley (BestPractical) and some Ideas from BPS
Wiki this AddOn will give you the option to change the Ticket View from
original BPS View to a so called SideBySide Ticket View (known from wiki).

RT users will find a new "Display History besides Metadata" option within the
"Ticket display" section of their Preferences.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::SideBySideView');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::SideBySideView));

or add C<RT::Extension::SideBySideView> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 UPGRADING

If you are upgrading from 0.03 or earlier, you must remove the old version
of this extension before installing the new version by running:

    rm -rf /opt/rt4/local/plugins/RT-Extension-SideBySideView/

=head1 AUTHORS

Torsten Brumm http://technik.picturepunxx.de/ <technik@picturepunxx.de>

Christian Loos <cloos@netsandbox.de>

=head1 LICENCE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 THANKS

=over

=item Steve Turner (MIT)

=item Markus Dirr (GC)

=item Thomas Sibley (BPS)

=item Christian Loos (NetCologne)

=back

=cut

1;
