package RTx::TicketlistTransactions;

our $VERSION = '1.00';

=head1 NAME

RTx::TicketlistTransactions - Adds LastTransactionContent as a search display column

=head1 RT VERSION

Works with RT 4.0 and 4.2

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RTx::TicketlistTransactions');

For RT 4.0, add this line:

    Set(@Plugins, qw(RTx::TicketlistTransactions));

or add C<RTx::TicketlistTransactions> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 TIPS

This display column tends to work best when given its own row and a
multi-column span, something like this advanced format:

    '   <b><a href="__WebPath__/Ticket/Display.html?id=__id__">__id__</a></b>/TITLE:#',
    '<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__Subject__</a></b>/TITLE:Subject',
    '__Status__',
    '__QueueName__',
    '__LastUpdatedBy__',
    '__NEWLINE__',
    '',
    '__LastTransactionContent__/SPAN:4'

=head1 CAVEATS

Only textual content is displayed, any formatting will be stripped.

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RTx-TicketlistTransactions@rt.cpan.org|mailto:bug-RTx-TicketlistTransactions@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RTx-TicketlistTransactions>.

=head1 LICENCE AND COPYRIGHT

This software is copyright (c) 2011-2014 by Best Practical Solutions, LLC

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
