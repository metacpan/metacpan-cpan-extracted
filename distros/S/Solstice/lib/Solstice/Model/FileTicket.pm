package Solstice::Model::FileTicket;

=head1 NAME

Solstice::Model::FileTicket - An interface for fetching one time use tickets for files.

=head1 SYNOPSIS

  # Create a new ticket for a file
  my $ticket = Solstice::Model::FileTicket->new({ file => $file });

  # Get a nice, encrypted id
  my $key    = $ticket->getKey();

  # Create a ticket based on a key
  # If it's not valid, $ticket will be undefined.
  my $ticket = Solstice::Model::FileTicket->new({ key => $key });

  # Get the file id back out of the ticket.
  # Should we add a getFile() method?
  my $file_id = $ticket->getFileID();

  # Expire the ticket
  $ticket->expire();

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice::Model);

use constant TRUE   => 1;
use constant FALSE  => 0;
use constant PARAM_NAME => 'tkt';

use Solstice::Database;
use Solstice::Configure;
use Solstice::Encryption;

=head2 Export

None by default.

=head2 Methods

=over 4


=item new()

Constructor.

=cut

sub new {
    my $class = shift;
    my $input = shift;
    my $self  = $class->SUPER::new(@_);

    return unless defined $input && $self->isValidHashRef($input);

    if (defined $input->{'key'}) {
        return unless $self->_initByKey($input->{'key'});
    }
    elsif (defined $input->{'file'}) {
        return unless $self->_initByFile($input->{'file'});
    }
    else {
        return;
    }
    return $self;
}

=item expire()

Removes the ticket.

=cut

sub expire {
    my $self = shift;

    my $id = $self->getID();

    return FALSE unless defined $id;

    my $db = Solstice::Database->new();
    my $config = Solstice::Configure->new();
    my $db_name = $config->getDBName();

    $db->writeQuery('DELETE FROM FileTicket WHERE file_ticket_id = ?', $id);

    return TRUE;
}

=item getParamName()

=cut

sub getParamName {
    return PARAM_NAME;
}

=back

=head2 Private Methods

=over 4

=cut

=item _initByKey($key)

Loads the ticket for the given key.

=cut

sub _initByKey {
    my $self = shift;
    my $key  = shift;

    return FALSE unless defined $key;
    my $encryption = Solstice::Encryption->new();

    my $decrypted = $encryption->decryptHex($key);

    return FALSE unless defined $decrypted;

    if ($decrypted =~ /^ticket_([0-9]+)$/) {
        my $ticket_id = $1;

        my $db = Solstice::Database->new();
        my $config = Solstice::Configure->new();
        my $db_name = $config->getDBName();

        $db->readQuery("SELECT * FROM $db_name.FileTicket WHERE file_ticket_id = ?", $ticket_id);

        my $data = $db->fetchRow();

        return FALSE unless defined $data;

        my $file_id = $data->{'file_id'};
        my $id      = $data->{'file_ticket_id'};

        return FALSE unless defined $file_id;

        $self->setFileID($file_id);
        $self->setFileClass($data->{'file_class'});
        $self->_setID($id);

        return TRUE;
    }
    return FALSE;
}

=item _initByFile($file)

Creates and stores a new ticket for the given file.  The file must be stored.

=cut

sub _initByFile {
    my $self = shift;
    my $file = shift;
    return FALSE unless defined $file;
    
    my $file_id = $file->getID();
    return FALSE unless defined $file_id;
    
    my $file_class = $file->getClassName();
    
    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();

    $db->writeQuery("INSERT INTO $db_name.FileTicket
        (file_id, file_class) VALUES (?, ?)", $file_id, $file_class);

    my $ticket_id = $db->getLastInsertID();

    my $encryption = Solstice::Encryption->new();
    my $key = $encryption->encryptHex('ticket_'.$ticket_id);

    $self->_setID($ticket_id);
    $self->setKey($key);
    $self->setFileID($file_id);
    $self->setFileClass($file_class);

    return TRUE;
}

=item _getAccessorDefinition()

=cut

sub _getAccessorDefinition {
    return [
        {
            name        => 'FileID',
            key         => '_file_id',
            type        => 'String',
        },
        {
            name        => 'FileClass',
            key         => '_file_class',
            type        => 'String',
        },
        {
            name        => 'Key',
            key         => '_key',
            type        => 'String',
        },
    ];
}

1;
__END__

=back

=head1 AUTHOR

Catalyst Research & Development Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: $

=head1 SEE ALSO

L<Solstice::Model>,
L<perl>.

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
