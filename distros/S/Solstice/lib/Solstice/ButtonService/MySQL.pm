package Solstice::ButtonService::MySQL;

use strict;
use 5.006_000;
use warnings;

use base qw( Solstice::ButtonService );

use Carp qw(confess);
use Solstice::Database;
use Solstice::Session;
use Solstice::CGI;

use constant PREFIX => 'btn_'; #this exists in the ButtonService Superclass as well

sub _selectedButtonLookup {
    my $self = shift;
    my $selected_button_name = shift;

    my $db = Solstice::Database->new();
    my $config = Solstice::Configure->new();
    my $db_name = $config->getSessionDB();

    $db->readQuery('SELECT button_id, name, action, preference_key, 
        preference_value, subsession_id, subsession_chain_id
        FROM '.$db_name.'.Button 
        WHERE name = ?', $selected_button_name);

    my $data_ref = $db->fetchRow();
    my $button_id = $data_ref->{'button_id'};

    return undef unless defined $button_id;

    my $button = Solstice::Button->new({
            name             => $data_ref->{'name'},
            action           => $data_ref->{'action'},
            preference_key   => $data_ref->{'preference_key'},
            preference_value => $data_ref->{'preference_value'},
            subsession_id    => $data_ref->{'subsession_id'},
            chain_id         => $data_ref->{'subsession_chain_id'},
        });

    $db->readQuery('SELECT name, value
        FROM '.$db_name.'.ButtonAttribute 
        WHERE button_id = ?', $button_id);

    my %button_attributes = ();
    while (my $attribute = $db->fetchRow()) {
        $button_attributes{$attribute->{'name'}} = $attribute->{'value'};
    }
    $button->{'_attributes'} = \%button_attributes;

    return $button;
}



sub _storeButtonList {
    my $self = shift;
    my $button_array = shift;
    my $button_commit_id = shift;

    my $button_insert = '';
    my @button_values = ();
    my %attributes = ();
    for my $button (@$button_array) {
        next unless $self->_isButtonStorable($button);

        $button_insert .= '(?, ?, ?, ?, ?, ?, ?, ?),';
        push @button_values, (
            $button_commit_id, 
            $button->{'_name'}, 
            $button->{'_action'}, 
            $button->{'_preference_key'}, 
            $button->{'_preference_value'},
            $self->getValue('session')->getSessionID(),
            $self->getValue('session')->getSubsessionID() || '',
            $self->getValue('session')->getSubsessionID() ? $self->getValue('session')->getSubsessionChainID() : '',
        );
        $attributes{$button->{'_name'}} = $button->{'_attributes'};
    }
    chop $button_insert; #,

    return $self->_clear() unless $button_insert;

    my $db = Solstice::Database->new();
    my $config = Solstice::Configure->new();
    my $db_name = $config->getSessionDB();
    my $sol_db_name = $config->getDBName();

    $db->writeQuery("use $db_name");
    $db->writeQuery('INSERT INTO Button
        (button_commit_id, name, action, preference_key, 
        preference_value, session_id, subsession_id, subsession_chain_id)
        VALUES '.$button_insert, @button_values);

    $db->readQuery('SELECT button_id, name FROM '.$db_name.'.Button
        WHERE button_commit_id = ?', $button_commit_id);

    my $attribute_insert = '';
    my @attribute_values = ();
    while (my $button = $db->fetchRow()) {
        next unless defined $attributes{$button->{'name'}};

        for my $key (keys %{$attributes{$button->{'name'}}}) {
            $attribute_insert .= '(?, ?, ?),';
            push @attribute_values, ($button->{'button_id'}, $key, $attributes{$button->{'name'}}->{$key});
        }
    }
    chop $attribute_insert; #,

    if ($attribute_insert) {
        $db->writeQuery('INSERT INTO '.$db_name.'.ButtonAttribute
            (button_id, name, value)
            VALUES '.$attribute_insert, @attribute_values);
    }
    $db->writeQuery("use $sol_db_name");

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

