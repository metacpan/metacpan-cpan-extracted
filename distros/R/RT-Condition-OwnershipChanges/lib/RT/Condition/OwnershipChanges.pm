use strict;
use warnings;
package RT::Condition::OwnershipChanges;

our $VERSION = '0.01';

=head1 NAME

RT-Condition-OwnershipChanges - Checks for ownership changes

=head1 INSTALLATION 

=over

=item perl Makefile.PL

=item make

=item make install

May need root permissions

=item make initdb

Only do this during the intial install.  Running it twice will result
in duplicate Scrip Conditions.

=item Edit your /opt/rt4/etc/RT_SiteConfig.pm

Add this line:

    Set(@Plugins, qw(RT::Condition::OwnershipChanges));

or add C<RT::Condition::OwnershipChanges> to your existing C<@Plugins> line.

=item make initdb

Only do this on your first install

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Kevin Falcone <falcone@bestpractical.com>

=head1 BUGS

All bugs should be reported via
L<http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Condition-OwnershipChanges>
or L<bug-RT-Condition-OwnershipChanges@rt.cpan.org>.


=head1 LICENCE AND COPYRIGHT

This software is Copyright (c) 2011 by Best Practical Solutions.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
