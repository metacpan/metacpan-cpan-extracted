use 5.008003; use strict; use warnings;

package RT::Extension::RepliesToResolved;

our $VERSION = '1.04';

=head1 NAME

RT::Extension::RepliesToResolved - intercept replies to resolved tickets

=head1 RT VERSION

Works with RT 4.4, 5.0, 6.0

=head1 DESCRIPTION

Intercepts replies via email to resolved tickets, and creates a new
ticket rather than updating the resolved ticket.  There are a few
reasons to do this:

=over 4

=item "Thank you" messages re-open tickets and mess with statistics.

=item People keep sending new questions into old tickets.

=back

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

=item Edit your F</opt/rt6/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::RepliesToResolved');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::RepliesToResolved));

or add C<RT::Extension::RepliesToResolved> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt6/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

Configuration for this extension is defined in

    /opt/rt6/local/plugins/RT-Extension-RepliesToResolved/etc/RepliesToResolved_Config.pm

You can read about the options in that file and then set your own
options in your RT_SiteConfig.pm file.

By default, after 7 days, this module will intercept mail to resolved
tickets and force the creation of a new ticket. It then creates a
RefersTo link between the two tickets. Each of these (time, statuses,
link) is configurable.

=cut

sub RemoveSubjectTags {
    my $entity = shift;
    # Keep in mind that this string has gone through RT's MIME header
    # decoding already and then was encoded as UTF-8. You're getting a
    # string of UTF-8 octets without Perl's UTF8 flag. Be careful.
    my $subject = $entity->head->get('Subject');
    my $rtname = RT->Config->Get('rtname');
    my $test_name = RT->Config->Get('EmailSubjectTagRegex') || qr/\Q$rtname\E/i;
    
    if ( $subject !~ s/\[$test_name\s+\#\d+\s*\]//i ) {
        foreach my $tag ( RT->System->SubjectTag ) {
            next unless $subject =~ s/\[\Q$tag\E\s+\#\d+\s*\]//i;
            last;
        }
    }
    $entity->head->replace(Subject => $subject);
}

require RT::Interface::Email;
package RT::Interface::Email;

{
    my $orig = __PACKAGE__->can('ExtractTicketId')
        or die "It's not RT 4.0.7, you have to patch this RT."
            ." Read documentation for RT::Extension::RepliesToResolved";

    no warnings qw(redefine);

    *ExtractTicketId = sub {
        my $entity = shift;

        my $id = $orig->( $entity );
        return $id unless $id;

        my $ticket = RT::Ticket->new( RT->SystemUser );
        $ticket->Load($id);
        return $id unless $ticket->id;

        my $r2r_config = RT->Config->Get('RepliesToResolved');
        my $config = $r2r_config->{'default'};
        if (exists($r2r_config->{$ticket->QueueObj->Name})) {
            $config = $r2r_config->{$ticket->QueueObj->Name};
        }

        my %closed_statuses;
        @closed_statuses{@{$config->{'closed-status-list'}}} = ();

        return $id unless (exists($closed_statuses{$ticket->Status}));

        my $reopen_timelimit = $config->{'reopen-timelimit'};

        # If the timelimit is undef, follow normal RT behaviour
        return $id unless defined($reopen_timelimit);

        return $id if ($ticket->ResolvedObj->Diff()/-86400 < $reopen_timelimit);

        $RT::Logger->info("A reply to resolved ticket #". $ticket->id .", creating a new ticket");

        $entity->head->replace("X-RT-Was-Reply-To" => Encode::encode_utf8($ticket->id));
        &RT::Extension::RepliesToResolved::RemoveSubjectTags($entity);

        return undef;
    };
}

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-RepliesToResolved@rt.cpan.org|mailto:bug-RT-Extension-RepliesToResolved@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-RepliesToResolved>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2014-2025 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
