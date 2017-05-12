package Solstice::Controller::Remote::SubsessionCheck;

=head1 NAME

Solstice::Controller::Remote::SubsessionCheck - Checks whether a given page is expired.

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice::Controller::Remote);

use Solstice::Session;
use Solstice::Database;
use Solstice::Configure;
use Solstice::ButtonService;

sub runRemote {
    my $self = shift;

    return unless defined $self->getModel();

    my $subsession_id = $self->getModel()->{'subsession'};
    my $chain_id      = $self->getModel()->{'chain_id'};

    my $subsession_pkg = 'Solstice::Subsession::' .$self->getConfigService()->getSessionBackend();
    Solstice->loadModule($subsession_pkg);

    unless( $subsession_pkg->isSubsessionLegal($subsession_id)){

        #some of the calls ehre are explicit rather than $self->getX() calls to avoid
        #triggering the remote's initStatefulAPI() method, which does more rigorous checking
        #than we want for this quick back-button checker

        my $subsession = $subsession_pkg->getFallbackSubsession($chain_id);

        if (defined $subsession) {
            my $session = Solstice::Session->new();
            $session->_setSubsession($subsession);
        }

        my $button_service = Solstice::ButtonService->new();
        my $button = $button_service->makeButton({ 
                action => '__bad_back_button__',
            });
        my $button_name = $button->getName();

        $self->addAction("Solstice.Button.bounceForward('$button_name');");
    }
}


1;

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
