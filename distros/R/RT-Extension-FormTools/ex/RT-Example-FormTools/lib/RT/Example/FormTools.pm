use strict;
use warnings;
package RT::Example::FormTools;

our $VERSION = '0.01';

=head1 NAME

RT-Example-FormTools - Example of a FormTools form

=head1 INSTALLATION

This module requires RT::Extension::FormTools to also be installed.

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item C<make initdb>

Only run this the first time you install this module.

If you run this twice, you may end up with duplicate data
in your database.

If you are upgrading this module, check for upgrading instructions
in case changes need to be made to your database.

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Example::FormTools');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Example::FormTools));

or add C<RT::Example::FormTools> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 LICENCE AND COPYRIGHT

This software is Copyright (c) 2011-2014 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
