package Solstice::Resource::File;

# $Id: File.pm 924 2006-03-03 00:13:09Z jlaney $

=head1 NAME

Solstice::Resource::File - A model representing a file 

=head1 SYNOPSIS

  package Solstice::Resource::File;

  use Solstice::Resource::File;

=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Resource);

use Solstice::Resource::File::Thumbnail;
use Solstice::Model::FileTicket;
use File::MMagic;
use Digest::MD5 qw(md5_hex);
use Carp qw(cluck confess);

use constant TRUE  => 1;
use constant FALSE => 0;

use constant MAX_THUMBNAIL_SIZE => 1024 * 1024 * 15; # 15 Mb
use constant THUMBNAIL_ROOT     => 'solstice/thumbnails';

our ($VERSION) = ('$Revision: 924 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::Resource|Solstice::Resource>.

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

=item getContentTypeDescription()

Return a string containing a description of this resource.

=cut
    
sub getContentTypeDescription {
    my $self = shift;
    return $self->getContentTypeService()->getContentDescriptionByContentType($self->getContentType());
}

=item getTicket()

=cut

sub getTicket {
    my $self = shift;
    return Solstice::Model::FileTicket->new({file => $self});
}

=item getTicketURL()

=cut

sub getTicketURL {
    my $self = shift;
    my $ticket = $self->getTicket();

    return unless defined $ticket;
    
    return $self->getBaseURL().'file_download.cgi?'.$ticket->getParamName().'='.$ticket->getKey();
}

=item getThumbnailURL([$max_size])

Return a ticketed URL for generating a thumbnail download.

=cut

sub getThumbnailURL {
    my $self = shift;
    my $size = shift;
    
    return unless $self->getContentTypeService()->isImageType($self->getContentType());
    
    my $ticket = $self->getTicket();
    return unless defined $ticket;

    my $url = $self->getBaseURL().'file_thumbnail.cgi?'.$ticket->getParamName().'='.$ticket->getKey();

    if ($size) {
        $url .= '&s='.$size;
    }
    return $url;
}

=item put($filehandle)

=cut

sub put {
    my $self = shift;
    my $filehandle = shift;

    return FALSE unless defined $filehandle;

    my $handle_type = ref $filehandle;

    if ('Solstice::CGI::Upload' eq $handle_type) {
        return $self->_putUploadFilehandle($filehandle);
    }
    elsif ('GLOB' eq $handle_type || 'Fh' eq $handle_type) {
        return $self->_putFilehandle($filehandle);
    }
    else {
        die "Unable to put file of type $handle_type";
    }
}

=item get($filehandle)

Print the contents of the file to the passed filehandle.

=cut

sub get {
    my $self = shift;
    my $filehandle = shift;

    return FALSE unless defined $filehandle;
    
    my $read_handle = $self->_getPerlFilehandle();
    if (!defined $read_handle) {
        $read_handle = $self->_getFilehandle();
    }

    if (!defined $read_handle) {
        warn "Filehandle not defined for reading\n";
        return FALSE;
    }

    while ( <$read_handle> ) {
        print $filehandle $_;
    }
        
    # Return to the begining of the file, to avoid side effects.
    seek($read_handle, 0, 0);

    return TRUE;
}

=item clone()

Returns a clone of the resource, with the name stripped and a 
source path added.

=cut

sub clone {
    my $self = shift;

    my $clone = $self->SUPER::clone();
    $clone->_setContentType($self->getContentType());

    return $clone;
}
    
=item toStandardOut()

=cut

sub toStandardOut {
    my $self = shift;
    return $self->get(*STDOUT);
}

=item makeThumbnail([$size])

=cut

sub makeThumbnail {
    my $self = shift;
    my $size = shift;
    
    my $content_type = $self->getContentType();
   
    # File content-type must be a recognized image type
    return unless $self->getContentTypeService()->isImageType($self->getContentType()); 
    # File content-length must be under a set limit
    return if $self->getSize() > MAX_THUMBNAIL_SIZE;

    my $owner = $self->getOwner();
    my $id    = $self->getID();

    my $image_cached = FALSE;
    my $file_path;
    my $cache_name;
    if (defined $owner && defined $id && defined $size) {
        # Thumbnail might already be cached
        $id =~ s/\//_/g;
        $cache_name = $self->getClassName().'_'.$id.'_'.$size;
        
        $file_path = $self->_generateThumbnailPath().$cache_name;
 
        if (-f $file_path) {
            my ($cache_mtime) = (stat($file_path))[9];
            my $file_mtime = $self->getModificationDate();
        
            my $cache_time = Solstice::DateTime->new($cache_mtime);
            if (defined $file_mtime && $file_mtime->getTimeApart($cache_time) >0) {
                $image_cached = TRUE;
            }
        }
    }
  
    unless ($image_cached) {
        # Create a temporary file path to open the file for thumbnailing
        $file_path = $self->getTempFileService()->getFilePath();

        open(my $FILE, '>', $file_path) or return;
        if (defined $id) {
            return unless $self->get($FILE);
        } else {
            my $filehandle = $self->_getFilehandle();
            if (!defined $filehandle) {
                $filehandle = $self->_getPerlFilehandle();
            }
            return unless defined $filehandle;
            while (my $content = <$filehandle>) {
                print $FILE $content;
            }
        }
        close($FILE);
    }
    
    my $thumbnail = Solstice::Resource::File::Thumbnail->new({
        name         => $self->getName(),
        owner        => $owner,
        path         => $file_path,
        content_type => $content_type,
        max_length   => $size,
        is_cached    => $image_cached,
        cache_name   => $cache_name,
    });
    return $thumbnail;
}

=item addChild()

=cut

sub addChild {
    my $self = shift;
    cluck ref($self) . '->addChild(): Not allowed';
    return FALSE;
}

=back

=head2 Private Methods

=over 4

=item _initFromHash(\%params)

=cut

sub _initFromHash {
    my $self = shift;
    my $params = shift;

    return FALSE unless defined $params;
    
    $self->_setContentType($params->{'content_type'});

    return $self->SUPER::_initFromHash($params);
}

=item _putUploadFilehandle($upload)

=cut

sub _putUploadFilehandle {
    my $self = shift;
    my $upload = shift;

    return FALSE unless defined $upload;

    my $filehandle = $upload->getFileHandle();

    return FALSE unless defined $filehandle;
    
    my $ct_service = $self->getContentTypeService();

    # We like File::MMagic for getting a content-type, but there
    # are a few types better handled by the upload obj.
    # 1st try... magic numbers
    my $type = $ct_service->getContentTypeByFilehandle($filehandle);

    # 2nd try... upload obj
    if (!defined $type || $ct_service->isVagueType($type)) {
        $type = $upload->getContentType();

        # 3rd try... file extension 
        if (!defined $type || $ct_service->isVagueType($type)) {
            my $ext_type = $ct_service->getContentTypeByFilename($self->getName());
            $type = $ext_type if defined $ext_type; # undef if no file extension 
        }
    }

    $self->_setPerlFilehandle(undef);
    $self->_setFilehandle($filehandle);
    $self->_setContentType($type);
    $self->_setSize((stat $filehandle)[7]);
    $self->_taint();

    return TRUE;
}

=item _putFilehandle($filehandle)

Like put, but for normal filehandles

=cut

sub _putFilehandle {
    my $self = shift;
    my $filehandle = shift;

    return FALSE unless defined $filehandle;

    my $type = $self->getContentTypeService()->getContentTypeByFilehandle($filehandle);

    $self->_setPerlFilehandle($filehandle);
    $self->_setFilehandle(undef);
    $self->_setContentType($type);
    $self->_setSize((stat $filehandle)[7]);
    $self->_taint();

    return TRUE;
}

=item _generateThumbnailPath() 

=cut

sub _generateThumbnailPath {
    my $self = shift;
    my $owner = $self->getOwner();

    return unless defined $owner;
    
    my $bucket = substr(md5_hex($owner->getID()), 0, 3);

    return $self->getConfigService()->getDataRoot() . '/' .
        THUMBNAIL_ROOT . '/' . $bucket . '/' . $owner->getID() . '/';
}

=item _getAccessorDefinition()

=cut

sub _getAccessorDefinition {
    return [
        {
            name => 'ContentType',
            key  => '_content_type',
            type => 'String',
            private_set => TRUE,
        },
        {
            name => 'Filehandle',
            key  => '_file_handle',
            type => 'GLOB',
            private_set => TRUE,
            private_get => TRUE,
        },
        {
            name => 'PerlFilehandle',
            key  => '_perl_file_handle',
            type => 'GLOB',
            private_set => TRUE,
            private_get => TRUE,
        },

    ];
}

1;
__END__

=back

=head2 Modules Used

L<Solstice::Resource|Solstice::Resource>.

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
