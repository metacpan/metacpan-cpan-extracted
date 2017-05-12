package RT::Action::SetStatus;

our $VERSION = '0.01';

use warnings;
use strict;

use base qw(RT::Action);

sub Prepare { 
    my $self = shift;
    my $status = $self->Argument;
    my $queue = RT::Queue->new($RT::SystemUser);

    unless ($status && $queue->IsValidStatus($status)) {
        $RT::Logger->error("$status is unset or not a valid status");
        return;
    }
    return 1;
}

sub Commit  {
    my $self = shift;

    my $status = $self->Argument;
    my ($val, $msg) = $self->TicketObj->SetStatus($status);
    unless ($val) {
        $RT::Logger->error("Unable to set ticket to $status: $msg");
        return 0;
    }

    $RT::Logger->debug("Set ticket status to $status");
    return 1;

}


=head1 NAME

RT::Action::SetStatus - Simple status changing action, generates actions based on your config

=head1 INSTALLATION 

    How to install:

    1. perl Makefile.PL
    2. make
    3. make install (may need root permissions)
    4. Edit your /opt/rt3/etc/RT_SiteConfig.pm 
        Set(@Plugins, qw(RT::Action::SetStatus));
        or add RT::Action::SetStatus to your existing @Plugins line
    5. Clear your mason cache
         rm -rf /opt/rt3/var/mason_data/obj
    6. Restart your webserver
    7. Create new Scrip Actions by using sbin/rt-create-setstatus-actions
        /opt/rt3/local/plugins/RT-Action-SetStatus/sbin/rt-create-setstatus-actions
        read the actions it will create, see if they're sane, if so
        /opt/rt3/local/plugins/RT-Action-SetStatus/sbin/rt-create-setstatus-actions --create
        watch for errors

        If you add a new Status, you can rerun this script and it will generate only new ScripActions


=head1 AUTHOR

Kevin Falcone  C<< <falcone@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2011, Best Practical Solutions, LLC.  All rights reserved.

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

1;
