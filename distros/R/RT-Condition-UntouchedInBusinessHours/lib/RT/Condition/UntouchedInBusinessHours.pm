package RT::Condition::UntouchedInBusinessHours;

our $VERSION = '0.03';

use warnings;
use strict;

=head1 NAME

RT::Condition::UntouchedInBusinessHours - Checks if a Ticket has been updated in the given business hours

=head1 SYNOPSIS

This Condition is meant to be used with the rt-crontool, so to escalate the priority
of tickets in a given queue that haven't been updated in 3 hours, you would do

 bin/rt-crontool \
    --search RT::Search::ActiveTicketsInQueue --search-arg general \
    --condition RT::Condition::UntouchedInBusinessHours --condition-arg 3 \
    --action RT::Action::EscalatePriority

or to generate mail

 bin/rt-crontool \
    --search RT::Search::ActiveTicketsInQueue --search-arg general \
    --condition RT::Condition::UntouchedInBusinessHours --condition-arg 3 \
    --action RT::Action::Notify \
    --template 7


=head1 INSTALLATION

=over

=item perl Makefile.PL

=item make

=item make install

May need root permissions

=item Edit your /opt/rt4/etc/RT_SiteConfig.pm

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Condition::UntouchedInBusinessHours');

For earlier releases of RT 4, add this line:

    Set(@Plugins, qw(RT::Condition::UntouchedInBusinessHours));

or add C<RT::Condition::UntouchedInBusinessHours> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

Reads from the C<%ServiceBusinessHours> as used by L<RT::Extension::SLA>.

At this time, reads only from the Default setting. Could learn to read
from other configurations with minimal Argument changing.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-rt-condition-untouchedinbusinesshours@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Kevin Falcone  C<< <falcone@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008-2014, Best Practical Solutions, LLC.  All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the terms of version 2 of the GNU General Public License.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

use base 'RT::Condition';

sub IsApplicable {
    my $self = shift;
    my $bhours = $self->BusinessHours;
    my $ticket = $self->TicketObj;
    my $overdue = $bhours->add_seconds( $ticket->LastUpdatedObj->Unix,
                                        ($self->Argument*60*60) );
    $RT::Logger->debug("Looking at ticket ".$ticket->Id." last updated ".$ticket->LastUpdatedObj->Unix." overdue: $overdue now ".time());
    if ( time() > $overdue ) {
        return 1
    } else {
        return 0;
    }
}

sub BusinessHours {
    my $self = shift;
    my $name = shift || 'Default';

    require Business::Hours;
    my $res = Business::Hours->new;
    $res->business_hours( %{ $RT::ServiceBusinessHours{ $name } } )
        if $RT::ServiceBusinessHours{ $name };
    return $res;
}


1;
