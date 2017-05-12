use warnings;
use strict;

package RT::Extension::AttachmentWarning;

our $VERSION = "0.02";



1;
__END__

=head1 NAME

RT::Extension::AttachmentWarning - Warn if the attachments in the session aren't what the user expects

=head1 DESCRIPTION

Browsing to other tickets or starting other replies/comments while in the
middle of another reply with already uploaded attachments can lead to
surprising results due to how attachments are handled in the user's session.

This extension catches when these unexpected leaks of attachments in and out of
the reply/comment happen and prevents the ticket update with a warning to the
user.  While not solving the problem, it at least prevents replies going out
with no attachments, or worse, the wrong, completely unrelated, attachments.

The underlying problem will be solved in RT 4.2, making this extension
unnecessary.

=head1 INSTALLATION 

=over

=item perl Makefile.PL

=item make

=item make install

May need root permissions

=item Edit your /opt/rt4/etc/RT_SiteConfig.pm

Add this line:

    Set(@Plugins, qw(RT::Extension::AttachmentWarning));

or add C<RT::Extension::AttachmentWarning> to your existing C<@Plugins> line.

This extension performs sanity checking on attachments, so it needs to be in
the C<@Plugins> list B<before> any other extensions which massage the session
attachments.  If it's placed after any such extensions, you'll see false
positive warnings.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

sunnavy, <sunnavy at bestpractical.com>

Thomas Sibley, <trs@bestpractical.com>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2012 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

