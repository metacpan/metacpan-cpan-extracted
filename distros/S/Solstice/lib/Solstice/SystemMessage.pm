package Solstice::SystemMessage;

# $Id: generated_model.tmpl 110 2005-09-02 16:28:22Z mcrawfor $

=head1 NAME

Solstice::SystemMessage - Models a message set by administrators to show all users.

=head1 SYNOPSIS

  use Solstice::SystemMessage;

  my $model = Solstice::SystemMessage->new();

=head1 DESCRIPTION

Represents a system message
=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Model);

use Solstice::DateTime;
use Solstice::Database;
use Solstice::Configure;

our ($VERSION) = ('$Revision: 110 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export

None by default.

=head2 Methods

=over 4

=item new()

Constructor.

=cut

sub new {
    my $obj = shift;
    my $id = shift;

    my $self = $obj->SUPER::new(@_);

    $self->_init($id) if $id;

    return $self;
}

sub _init {
    my ($self, $id) = @_;

    my $db = Solstice::Database->new();
    my $config = Solstice::Configure->new();
    my $solstice_db = $config->getDBName();

    $db->readQuery('SELECT 
        system_message_id, show_on_all_tools, start_date, end_date, message 
        FROM '.$solstice_db.'.SystemMessage 
        WHERE system_message_id = ?', $id);

    my $data = $db->fetchRow();

    $self->_setID($data->{'system_message_id'});
    $self->setShowOnAllTools($data->{'show_on_all_tools'}); 
    $self->setStartDate(Solstice::DateTime->new($data->{'start_date'})); 
    $self->setEndDate(Solstice::DateTime->new($data->{'end_date'}));
    $self->setMessage($data->{'message'});
}

sub store {
    my $self = shift;
    my $db = Solstice::Database->new();

    my $config = Solstice::Configure->new();
    my $solstice_db = $config->getDBName();
    
    my $test_id;
    if (defined $self->getID()){
        $db->readQuery('SELECT system_message_id 
        FROM '.$solstice_db.'.SystemMessage
        WHERE system_message_id = ?', $self->getID());
        my $data = $db->fetchRow();
        $test_id = $data->{'system_message_id'};
    }

    if(defined $test_id){
        $db->writeQuery('UPDATE '.$solstice_db.'.SystemMessage
        SET show_on_all_tools = ?,
        start_date = ?,
        end_date = ?,
        message = ?
        WHERE system_message_id = ?', 
        $self->getShowOnAllTools(), $self->getStartDate()->toSQL(), $self->getEndDate()->toSQL(), $self->getMessage(), $self->getID());
    }else{
        $db->writeQuery('INSERT INTO '.$solstice_db.'.SystemMessage
        (show_on_all_tools, start_date, end_date, message)
        VALUES 
        (?, ?, ?, ?)', 
        $self->getShowOnAllTools(), $self->getStartDate()->toSQL(), $self->getEndDate()->toSQL(), $self->getMessage());

        my $id = $db->getLastInsertID();

        $self->_setID($id);

    }
}

sub delete {
    my $self = shift;

    my $db = Solstice::Database->new();
    return unless $self->getID();

    my $config = Solstice::Configure->new();
    my $solstice_db = $config->getDBName();

    $db->writeQuery('DELETE FROM '.$solstice_db.'.SystemMessage WHERE system_message_id = ?', $self->getID());
}

sub _getAccessorDefinition {
    return [
    {
        name  => 'ShowOnAllTools',
        key   => '_show_on_tools',
        type  => 'Boolean',
    },
    {
        name        => 'StartDate',
        key         => '_start_date',
        type        => 'Solstice::DateTime',
    },
    {
        name        => 'EndDate',
        key         => '_end_date',
        type        => 'Solstice::DateTime',
    },
    {       name        => 'Message',
        key         => '_message',
        type        => 'String',
    },
    ];
}



1;

__END__

=back

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 110 $



=cut

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
