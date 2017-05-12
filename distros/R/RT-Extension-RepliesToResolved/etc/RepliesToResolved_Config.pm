=head1 RT::Extension::RepliesToResolved configuration

Copy the default settings to your RT_SiteConfig.pm, and edit them
there.  Do not edit the settings in this file.

=over 4

=item C<%RepliesToResolved>

C<%RepliesToResolved> contains default and optional per-queue
parameters.  The top level keys of the hash are either B<default>
or the name of a queue.  Within each of these items, there are the
following configuration options:

=over 4

=item closed-status-list

The list of statuses which the extension will respond to; the default
is just the 'resolved' status.

=item reopen-timelimit

The time limit, in days, during which mail replies to tickets will
cause the ticket to reopen.  Setting this to 0 means that resolved
tickets will never be reopened, but a new ticket will always be created
instead.  Setting this to undef restores the normal behaviour of RT,
where replies will reopen the ticket.

=item link-type

This sets the type of link that the extension will make between the
original ticket and the new ticket.  The default is B<RefersTo>.  See
L<RT::Ticket> for details of available link types.  Setting this to
undef stops the link from being created.

=back

=back

=cut

Set(%RepliesToResolved,
   default => {
     'closed-status-list' => [ qw(resolved) ],
     'reopen-timelimit' => 7,
     'link-type' => 'RefersTo',
   },
);

1;
