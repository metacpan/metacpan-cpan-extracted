package Solstice::Factory::Resource::File::BlackBox;

=head1 NAME

Solstice::Factory::Resource::File::BlackBox -

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Factory);

use Solstice::Resource::File::BlackBox; 
use Solstice::List;
use Solstice::Database;
use Solstice::Encryption;
use Solstice::Factory::Person;

=head2 Export

None by default.

=head2 Methods

=over 4

=cut

=item createByIDs(\@list)

=cut

sub createByIDs {
    my ($self, $ids) = @_;

    return Solstice::List->new() unless @$ids;
    
    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();
    
    my $placeholder = join(',', map({'?'} @$ids));
    
    $db->readQuery('SELECT *, file_id AS id FROM '.$db_name.'.File
        WHERE file_id IN('.$placeholder.') ORDER BY file_id', @$ids);
    
    return $self->_createFromDBReturn($db);
}

=item createByEncryptedIDs(\@list)

=cut

sub createByEncryptedIDs {
    my ($self, $enc_ids) = @_;
    
    my $decryptor = Solstice::Encryption->new();
    
    my @ids = ();
    for my $enc_id (@$enc_ids) {
        my $id = $decryptor->decrypt($enc_id);
        if (defined $id && $id =~ /^\w+_([0-9]+)$/) {
            push @ids, $1;
        }
    }
    return $self->createByIDs(\@ids);
}

=item createByEncryptedID($id)

=cut

sub createByEncryptedID {
    my $self = shift;
    my $id = shift;
    return $self->createByEncryptedIDs([$id])->shift();
}

=item createByOwner($person)

=cut

sub createByOwner {
    my $self = shift;
    my $person = shift;

    return Solstice::List->new() unless
        (defined $person and $person->getID());

    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();
    
    $db->readQuery('SELECT *, file_id AS id FROM '.$db_name.'.File
        WHERE person_id = ? ORDER BY file_id', $person->getID());

    return $self->_createFromDBReturn($db);
}

=item _createFromDBReturn($db)

=cut

sub _createFromDBReturn {
    my $self = shift;
    my $db = shift;

    my $list = Solstice::List->new();
   
    my @db_data = ();
    my @person_ids = ();
    my @file_ids = ();
    while( my $row = $db->fetchRow() ){
        push @db_data, $row;
        push @file_ids, $row->{'id'};
        push @person_ids, $row->{'person_id'};
    }

    return $list unless scalar @file_ids;

    # File attributes
    my $db_name = $self->getConfigService()->getDBName();
    
    my $placeholders = join(',', map({'?'} @file_ids));
    $db->readQuery('SELECT file_id, attribute, value
        FROM '.$db_name.'.FileAttribute
        WHERE file_id IN('.$placeholders.')', @file_ids);

    my %attributes = ();
    while (my $data = $db->fetchRow()) {
        my $hashref = $attributes{$data->{'file_id'}} || {};
        $hashref->{$data->{'attribute'}} = $data->{'value'};
        $attributes{$data->{'file_id'}} = $hashref;
    }
   
    my $people = Solstice::Factory::Person->new()->createHashByIDs(\@person_ids);
    
    for my $row (@db_data) {
        $row->{'owner'} = $people->{$row->{'person_id'}};
        $row->{'attributes'} = $attributes{$row->{'id'}};
        my $file = $self->_createFile($row);
        $list->push($file) if defined $file;
    }
    return $list;
}

=item _createFile($data)

=cut

sub _createFile {
    my $self = shift;
    my $data = shift;
    return Solstice::Resource::File::BlackBox->new($data);
}

1;

__END__

=back

=head1 AUTHOR

Educational Technology Development Group E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 1345 $

=head1 SEE ALSO

L<Solstice::Database|Solstice::Database>,

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
