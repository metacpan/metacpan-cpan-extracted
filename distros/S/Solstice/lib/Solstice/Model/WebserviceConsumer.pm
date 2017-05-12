package Solstice::Model::WebserviceConsumer;

use strict;
use warnings;
use 5.006_000;

use base qw( Solstice::Model );

use constant TRUE  => 1;
use constant FALSE => 0;

use Solstice::Database;
use Solstice::Application;
use Solstice::Factory::Person;

=over 4

=item new
takes input and returns false unless the consumer exists
=cut

sub new {
    my $obj = shift;
    my $input = shift;
    my $self = $obj->SUPER::new(@_);

    return undef unless $self->_initialize($input);

    return $self;
}

=item create
Takes no input, cannot pull from database - for creating a new consumer
=cut
sub create {
    my $obj = shift;
    my $self = $obj->SUPER::new(@_);

    return $self;
}

sub store {
    warn "unimplemented store in WebserviceConsumer";
}

sub hasAppAccessByNamespace {
    my $self = shift;
    my $namespace = shift;

    my $id = Solstice::Application->new($namespace)->getID();

    return $self->{'_apps_with_access'}{$id} ? TRUE : FALSE;
}

sub _initialize {
    my $self = shift;
    my $input = shift;

    return FALSE unless defined $input;

    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();

    my $sql = "SELECT * FROM $db_name.WebserviceConsumer WHERE ";

    if (defined $input->{'id'}) {
        $db->readQuery($sql. 'webservice_consumer_id = ?', $input->{'id'});

    } elsif (defined $input->{'public_id'}) {
        $db->readQuery($sql. 'public_id = ?', $input->{'public_id'});

    } elsif (defined $input->{'cert'}) {
        my $name = $input->{'cert'}->getCN();
        $db->readQuery($sql. 'cert_cname = ?', $name);
    }

    return FALSE unless $db->rowCount();

    return $self->_initByHash($db->fetchRow());
}

sub _initByHash {
    my $self = shift;
    my $input = shift;

    return FALSE unless $self->_isValidHashRef($input);

    $self->_setID($input->{'webservice_consumer_id'});
    $self->_setPerson(Solstice::Factory::Person->new()->createByID($input->{'person_id'}));
    $self->_setPrivateKey($input->{'private_key'});
    $self->_setCertCName($input->{'cert_cname'});
    $self->_setNotes($input->{'notes'});

    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();

    $db->readQuery("SELECT * FROM $db_name.WebserviceConsumerApplicationAccess WHERE webservice_consumer_id = ?", 
        $self->getID()
    );

    while( my $row = $db->fetchRow() ){
        $self->{'_apps_with_access'}{$row->{'application_id'}} = TRUE;
    }

    return TRUE;
}


sub _getAccessorDefinition {
    return [
    {
        name => 'Person',
        key  => '_person',
        type => 'Solstice::Person',
    },
    {
        name => 'PublicID',
        key  => '_public_id',
        type => 'String',
    },
    {
        name => 'PrivateKey',
        key  => '_private_key',
        type => 'String',
    },
    {
        name => 'CertCName',
        key  => '_cname',
        type => 'String',
    },
    {
        name => 'Notes',
        key  => '_notes',
        type => 'String',
    },
    ];
}


1;

=back

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
