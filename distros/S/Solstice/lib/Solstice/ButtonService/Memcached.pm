package Solstice::ButtonService::Memcached;

use strict;
use 5.006_000;
use warnings;

use base qw( Solstice::ButtonService );

use Carp qw(confess);
use Solstice::Session;
use Solstice::CGI;
use Solstice::Memcached;

use constant PREFIX => 'btn_'; #this exists in the ButtonService Superclass as well

sub _selectedButtonLookup {
    my $self = shift;
    my $selected_button_name = shift;

    my $memd = Solstice::Memcached->new('buttons');
    my $selected_button = $memd->get($selected_button_name);
   
    return defined $selected_button ? $selected_button: undef;
}



sub _storeButtonList {
    my $self = shift;
    my $button_array = shift;
    my $memd = Solstice::Memcached->new('buttons');

    for my $button (@$button_array) {
        next unless $self->_isButtonStorable($button);

        $button->{'_memcached_session_id'} = $self->getValue('session')->getSessionID();
        $button->setSubsessionID($self->getValue('session')->getSubsessionID());
        $button->{'_chain_id'} = $self->getValue('session')->getSubsessionID() ? $self->getValue('session')->getSubsessionChainID() : '';

        $memd->set($button->{'_name'}, $button);
    }

    return;
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

