use 5.008003;
use strict;
use warnings;

package RT::Extension::ACNS;

our $VERSION = '1.00';

=head1 NAME

RT::Extension::ACNS - parse ACNS messages and extract info into custom fields

=head1 DESCRIPTION

ACNS stands for Automated Copyright Notice System. It's an open source,
royalty free system that universities, ISP's, or anyone that handles
large volumes of copyright notices can implement on their network to
increase the efficiency and reduce the costs of responding to the
notices...  See L<http://mpto.unistudios.com/xml/> for more details.

This extension for RT is a configurable scrip that parses ACNS XML from
incomming messages and stores it in custom fields.

=head1 RT VERSION

Works with RT 4.0 and RT 4.2.

=head1 INSTALLATION

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

    Plugin('RT::Extension::ACNS');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::ACNS));

or add C<RT::Extension::ACNS> to your existing C<@Plugins> line.

=item Configure ACNS

The scrip is configured through the C<%ACNS> config option, as described
in F<etc/RT_ACNSConfig.pm>.

=item Restart your webserver

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-ACNS@rt.cpan.org|mailto:bug-RT-Extension-ACNS@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-ACNS>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2014 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
