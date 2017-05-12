use strict;
use warnings;
package RT::Action::MoveQueueBySubject;
use base qw(RT::Action);

our $VERSION = '1.00';

=head1 NAME

RT-Action-MoveQueueBySubject - Move Tickets between queues based on Subject

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

    Plugin('RT::Action::MoveQueueBySubject');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Action::MoveQueueBySubject));

or add C<RT::Action::MoveQueueBySubject> to your existing C<@Plugins> line.

=item Restart your webserver

=back

=head1 CONFIGURATION

To configure this scrip, set the C<@MoveQueueBySubjectConditions> configuration option.

It is a list of regular expressions and queues. Each regular expression
will be check in order, if it matches the ticket will be moved to that
queue and processing will stop.

    Set(@MoveQueueBySubjectConditions,
        '^begin', 'Start',
        'end$', 'Finale',
    );

You can defined these as qr// if you prefer. The module does not apply
any flags to your regular expression, so if you want case insensitivity
or something else, be sure to use the (?i) operator which you can read
more about in L<perlre>.

=head1 USAGE

Once you've configured the action, set up a Scrip to use it. At the
Global or Queue level, define a Scrip with your preferred Condition (On
Create is typical), this Action and a Blank Template.

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Action-MoveQueueBySubject@rt.cpan.org|mailto:bug-RT-Action-MoveQueueBySubject@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Action-MoveQueueBySubject>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2011-2014 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

sub Prepare { return 1; }

sub Commit {
    my $self = shift;
    my @conditions = @{RT->Config->Get('MoveQueueBySubjectConditions')};

    my $subject = $self->TicketObj->Subject;
    while ( my ($regex, $queue) = splice(@conditions,0,2) ) {
        RT->Logger->debug("Comparing $regex to $subject for a move to $queue");
        if ( $subject =~ /$regex/ ) {
            RT->Logger->debug("Moving to queue $queue");
            my ($ok, $msg) = $self->TicketObj->SetQueue($queue);
            unless ($ok) {
                RT->Logger->error("Unable to move to queue $queue: $msg.  Aborting");
                return 0;
            }
            last;
        }
    }
    return 1;
}

1;
