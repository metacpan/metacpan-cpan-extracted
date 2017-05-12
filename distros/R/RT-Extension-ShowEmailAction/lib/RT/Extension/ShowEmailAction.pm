use strict;
use warnings;

package RT::Extension::ShowEmailAction;

our $VERSION = '1.00';


1;
__END__

=head1 NAME

RT::Extension::ShowEmailAction - add a show source link to correspondence

=head1 DESCRIPTION

Adds a "Show Source" link to the actions of Correspond and Comment transactions
using the same page as the existing "Show" link on outgoing email transactions.

=head1 RT VERSION

Works with RT 4.0.0 and newer.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::ShowEmailAction');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::ShowEmailAction));

or add C<RT::Extension::ShowEmailAction> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Sam Hanes E<lt>sam@maltera.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-ShowEmailAction@rt.cpan.org|mailto:bug-RT-Extension-ShowEmailAction@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-ShowEmailAction>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright 2016 Sam Hanes

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
