package Solstice::Resource::File::BlackBox;

# $Id: BlackBox.pm 924 2006-03-03 00:13:09Z jlaney $

=head1 NAME

Solstice::Resource::File::BlackBox - A file implementation 

=head1 SYNOPSIS

  package Solstice::Resource::File::BlackBox;

  use Solstice::Resource::File::BlackBox;

=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Resource::File);

use Solstice::Database;
use Solstice::DateTime;
use Solstice::Encryption;

use Image::Magick;
use Digest::MD5 qw(md5_hex);

use constant TRUE  => 1;
use constant FALSE => 0;

use constant FILE_ROOT => 'solstice/files';

our ($VERSION) = ('$Revision: 924 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::Resource::File|Solstice::Resource::File>.

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

=item setAttribute($key, $value)

=cut

sub setAttribute {
    my $self = shift;
    my $key  = shift;
    return FALSE unless $key;
    $self->_getAttributes()->{$key} = shift;
    $self->_taint();
    return TRUE;    
}

=item getAttribute($key)

Returns the value of the attribute identified by $key.

=cut

sub getAttribute {
    my $self = shift;
    my $key  = shift;
    return $self->_getAttributes()->{$key};
}

=item setName($name)

Sets the name of the resource.

=cut

sub setName {
    my $self = shift;
    my $name = shift;
    $self->_taint();
    return $self->_setName($name);
}

=item getPath()

Returns the actual path to the file.

=cut

sub getPath {
    my $self = shift;
    return unless $self->getID();
    return $self->_generateFilePath().$self->getID();
}

=item get($filehandle)

Print the contents of the file to the passed filehandle.

=cut

sub get {
    my $self = shift;
    my $filehandle = shift;

    return FALSE unless defined $filehandle;
    
    my $FILE = $self->getFilehandle() or return FALSE;
    while ( <$FILE> ) { print $filehandle $_; }
    close($FILE);
    
    return TRUE;
}

=item getFilehandle()

=cut

sub getFilehandle {
    my $self = shift;

    my $file_path = $self->getPath();
    
    return unless $file_path;

    my $FILE;
    unless (open($FILE, '<', $file_path)) {
        warn "Cannot open file $file_path for reading\n";
        return;
    }
    return $FILE;
}

=item getPermanentTicketURL()

=cut

sub getPermanentTicketURL {
    my $self = shift;

    return undef unless $self->getID();
    my $ptkt = Solstice::Encryption->new()->encryptHex('permanent_ticket_id_'.$self->getID());
    return $self->getBaseURL()."file_download.cgi?ptkt=$ptkt";
}

=item clone()

=cut

sub clone {
    my $self = shift;

    my $clone = Solstice::Resource::File::BlackBox->new();
    $clone->_setOwner($self->getOwner());
    $clone->_setName($self->getName());
    $clone->_setSize($self->getSize());
    $clone->_setContentType($self->getContentType());
    $clone->_setAttributes($self->_getAttributes());
    $clone->_setPerlFilehandle($self->getFilehandle());
    $clone->_taint();
    
    return $clone;
}

=item getClassName()
    
Return a string containing the package name, avoiding a ref
        
=cut

sub getClassName {
    return 'Solstice::Resource::File::BlackBox';
}

=back

=head2 Private Methods

=over 4

=item _store()

Adds/modifies an entry in the solstice database for the file.

=cut

sub _store {
    my $self = shift;
    
    my $owner = $self->getOwner();
    
    return FALSE unless defined $owner;
  
    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();
  
    if (defined $self->getID()) {
        $self->_setModificationDate(Solstice::DateTime->new(time));

        $db->writeQuery('UPDATE '.$db_name.'.File
            SET name = ?, modification_date = ?
            WHERE file_id = ?',
            $self->getName(),
            $self->getModificationDate()->toSQL(),
            $self->getID() );
        
    } else {
        my $filehandle = $self->_getFilehandle();
        if (!defined $filehandle) {
            $filehandle = $self->_getPerlFilehandle();
        }
    
        return FALSE unless defined $filehandle;
    
        $self->_setModificationDate(Solstice::DateTime->new(time));
        $self->_setCreationDate(Solstice::DateTime->new(time));

        $db->writeQuery('INSERT INTO '.$db_name.'.File (
                person_id, name, creation_date, modification_date,
                content_type, content_length
            ) VALUES (?,?,?,?,?,?)',
            $owner->getID(),
            $self->getName(),
            $self->getCreationDate()->toSQL(),
            $self->getModificationDate()->toSQL(),
            $self->getContentType(),
            $self->getSize() );
    
        $self->_setID($db->getLastInsertID());

        # Write the file content to disk
        my $file_path = $self->_generateFilePath(); 
        $self->_dirCheck($file_path);
        $file_path .= $self->getID();
        
        open(my $FILE, '>', $file_path) or die "Cannot open file $file_path for writing\n";
    
        binmode($FILE);
        while (my $content = <$filehandle>) {
            print $FILE $content;
        }
        close($FILE);
   
        $self->_setFilehandle(undef);
        $self->_setPerlFilehandle(undef);
        
        my $ct_service = $self->getContentTypeService();
        if ($ct_service->isKnownType($self->getContentType())) {
            # Images only: get width and height attributes once
            if ($ct_service->isImageType($self->getContentType())) {
                my $image = Image::Magick->new();
                my $msg = $image->Read(filename => $file_path);
                unless ($msg && $msg !~ /^Exception (415|420)/) {
                    $self->setAttribute('width', $image->Get('width'));
                    $self->setAttribute('height', $image->Get('height'));
                }
            }
        } else {
            # Log the unknown content types
            $self->getLogService()->log({
                log_file => 'unknown_content_types',
                model_id => $self->getID(),
                content  => $self->getContentType(),
            });
        }
    }
    $self->_storeAttributes();
    $self->_untaint();
    
    return TRUE;
}

=item _delete()
    
=cut 

sub _delete {
    my $self = shift;

    return FALSE unless $self->getID();

    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();
    
    $db->writeQuery('DELETE FROM '.$db_name.'.File
        WHERE file_id = ?', $self->getID());

    $db->writeQuery('DELETE FROM '.$db_name.'.FileAttribute
        WHERE file_id = ?', $self->getID());
    
    unlink($self->getPath());
    
    return TRUE;
}

=item _initFromID($int)

Loads the File from the DB by id.

=cut

sub _initFromID {
    my $self = shift;
    my $id   = shift;

    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();

    $db->readQuery('SELECT f.file_id AS id, f.* 
        FROM '.$db_name.'.File AS f 
        WHERE f.file_id = ?', $id
    );

    my $params = $db->fetchRow();

    return FALSE unless $self->_initFromHash($params);
    return FALSE unless (-f $self->getPath()); 
    return $self->_initFileAttributes();
}

=item _initFromHash(\%params)

=cut

sub _initFromHash {
    my $self = shift;
    my $params = shift;

    return FALSE unless defined $params;

    # Implementation-specific attributes
    $self->_setAttributes($params->{'attributes'} || {});
    
    return $self->SUPER::_initFromHash($params);
}
    
=item _initEmpty()

=cut

sub _initEmpty {
    my $self = shift;

    $self->_setOwner($self->getUserService()->getUser());
    $self->_setAttributes({});

    return TRUE;
}

=item _initFileAttributes()

=cut

sub _initFileAttributes {
    my $self = shift;

    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();
    
    $db->readQuery('SELECT attribute, value
        FROM FileAttribute WHERE file_id = ?', $self->getID());
    
    my %attributes = ();
    while (my $data = $db->fetchRow()) {
        $attributes{$data->{'attribute'}} = $data->{'value'};
    }
    $self->_setAttributes(\%attributes);

    return TRUE;
}

=item _generateFilePath() 

=cut

sub _generateFilePath {
    my $self = shift;
    my $bucket = substr(md5_hex($self->getOwner()->getID()), 0, 3);

    return $self->getConfigService()->getDataRoot() . '/' . FILE_ROOT .
        '/' . $bucket . '/' .$self->getOwner()->getID() . '/';
}

=item _storeAttributes()

=cut

sub _storeAttributes {
    my $self = shift;

    my $attributes = $self->_getAttributes();

    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();

    $db->writeQuery('DELETE FROM '.$db_name.'.FileAttribute
        WHERE file_id = ?', $self->getID());

    my @attribute_data = ();
    for my $key (keys %$attributes) {
        push @attribute_data, ($self->getID(), $key, $attributes->{$key});
    }
    my $placeholder = join(',', map {'(?,?,?)'} keys %$attributes);
   
    return TRUE unless @attribute_data;
    
    $db->writeQuery('INSERT INTO '.$db_name.'.FileAttribute
            (file_id, attribute, value)
        VALUES '.$placeholder, @attribute_data);

    return TRUE;
}

=item _getAccessorDefinition()

=cut

sub _getAccessorDefinition {
    return [
        {
            name  => 'Attributes',
            key   => '_attributes',
            type  => 'HashRef',
            private_set => TRUE,
            private_get => TRUE,
        },
    ];
}


1;
__END__

=back

=head2 Modules Used

L<Solstice::Database|Solstice::Database>,
L<Solstice::Resource::File|Solstice::Resource::File>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 924 $ 

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
