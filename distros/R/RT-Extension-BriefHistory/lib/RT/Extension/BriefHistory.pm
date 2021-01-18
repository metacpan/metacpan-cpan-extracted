package RT::Extension::BriefHistory;

use 5.008003;
use strict;
use warnings;

our $VERSION = '3.00';

=head1 NAME

RT::Extension::BriefHistory - Filter history by type on ticket display page

=head1 DESCRIPTION

This plugin filter the history on the ticket display page by transaction types
that are defined in the configuration.
By default it shows only the transaction types create, correspond and comment.

The history page shows always the full history.

It was created after an article in the Best Practical wiki and
an discussion in the rt-user mailing list (look at SEE ALSO).

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::BriefHistory');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::BriefHistory));

or add C<RT::Extension::BriefHistory> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj/*

=item Restart your webserver

=back

=head1 AUTHOR

Christian Loos <cloos@netsandbox.de>

=head1 LICENCE AND COPYRIGHT

Copyright (C) 2010-2014, Christian Loos.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://bestpractical.com/rt/>

L<http://wiki.bestpractical.com/view/HideTransactions>

L<http://lists.bestpractical.com/pipermail/rt-users/2010-May/064720.html>

=cut

1;
