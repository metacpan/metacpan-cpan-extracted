use strict;
use warnings;
package RT::Extension::QuoteSelection;

our $VERSION = '1.01';

RT->AddJavaScript("RTx-QuoteSelection.js");

=encoding utf8

=head1 NAME

RT-Extension-QuoteSelection - Quotes selected text, if any, when replying/commenting to tickets

=head1 RT VERSION

Works with RT 4.0, 4.2 and 4.4.

=head1 WHAT'S THIS DO?

Highlight a snippet of text on the ticket display page and click a Reply or
Comment link.  I<Voilà!>  Your highlighted text (and B<only> your highlighted
text) is quoted in the message box.

Both the per-transaction Reply/Comment links and the Reply/Comment links under
the Actions menu will use the selected text, if any.

=head1 CAVEATS

User signatures aren't inserted when highlighted text is quoted.

The per-transaction Reply/Comment links will consider your update a response to
the transaction even if you quote from an entirely different transaction.  This
doesn't matter to most people, and only affects email threading.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::QuoteSelection');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::QuoteSelection));

or add C<RT::Extension::QuoteSelection> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-QuoteSelection@rt.cpan.org|mailto:bug-RT-Extension-QuoteSelection@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-QuoteSelection>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2012-2014 by Best Practical Solutions, LLC

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
