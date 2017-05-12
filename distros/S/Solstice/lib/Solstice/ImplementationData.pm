package Solstice::ImplementationData;

=head1 NAME

Solstice::ImplementationData - Tracks data for one implementation of a tool.

=head1 SYNOPSIS
=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Model);

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

sub new {
    my $obj = shift;
    my $input = shift;
    
    my $self = $obj->SUPER::new();

    if ($self->isValidHashRef($input)) {
        $self->_initFromHash($input);
    }
    $self->setDataHash({}) unless defined $self->getDataHash();


    return $self;
}


=item _initFromHash(\%input)

=cut

sub _initFromHash {
    my $self = shift;
    my $input = shift;

    $self->setOwner($input->{'owner'});
    $self->setImplementationName($input->{'implementation_name'});
    $self->setImplementationID($input->{'implementation_id'});
    $self->setDateCreated($input->{'date_created'});
    $self->setDateModified($input->{'date_modified'});
    $self->setApplicationName($input->{'application_name'});
    $self->setApplicationID($input->{'application_id'});    
    $self->setParticipantURL($input->{'participant_url'});
    $self->setDataHash($input->{'data_hash'});

    return;
}

=item _getAccessorDefinition()
=cut

sub _getAccessorDefinition {
    return [
    {
        name => 'Owner',
        key  => '_owner',
        type => 'Person',
    },
    {
        name => 'ImplementationName',
        key  => '_implementation_name',
        type => 'String',
    },
    {
        name => 'ImplementationID',
        key  => '_implementation_id',
        type => 'Integer',
    },
    {
        name => 'ParticipantURL',
        key  => '_participant_url',
        type => 'String',
    },
    {
        name => 'DateCreated',
        key  => '_date_created',
        type => 'DateTime',
    },
    {
        name => 'DateModified',
        key  => '_date_modified',
        type => 'DateTime',
    },
    {
        name => 'ApplicationName',
        key  => '_application_name',
        type => 'String',
    },
    {
        name => 'ApplicationID',
        key  => '_application_id',
        type => 'Integer',
    },
    {
        name => 'DataHash',
        key  => '_data_hash',
        type => 'HashRef',
    }
    ];
}

1;

__END__

=back

=head2 Modules Used

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 2579 $ 



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
