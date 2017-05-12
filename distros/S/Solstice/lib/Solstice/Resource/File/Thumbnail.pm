package Solstice::Resource::File::Thumbnail;

# $Id: Thumbnail.pm 924 2006-03-03 00:13:09Z jlaney $

=head1 NAME

Solstice::Resource::File::Thumbnail - 

=head1 SYNOPSIS

  package Solstice::Resource::File::Thumbnail;

  use Solstice::Resource::File::Thumbnail;

=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Resource::File);

use Image::Magick;
use Time::HiRes qw(time);

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_LENGTH   => 32;
use constant WIDTH_MULTIPLIER => 1.6;

our ($VERSION) = ('$Revision: 924 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::Resource::File|Solstice::Resource::File>.

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

=item get($filehandle)

Print the contents of the file to the passed filehandle.

=cut

sub get {
    my $self = shift;
    my $filehandle = shift;

    return FALSE unless defined $filehandle;
   
    my $FILE;
    open($FILE, '<', $self->getPath()) or return FALSE;
    while ( <$FILE> ) { print $filehandle $_; }
    close($FILE);

    # If the file wasn't cached, remove it
    unless ($self->getIsCached()) {
        unlink($self->getPath());
    }

    return TRUE;
}

=item delete()

=cut

sub delete {
    my $self = shift;
    return FALSE unless defined $self->getPath();
    
    unlink($self->getPath());
    
    return TRUE;
}

=item getPath()

=cut

sub getPath {
    my $self = shift;
    return $self->_getPath();
}

=back

=head2 Private Methods

=over 4

=item _initFromHash(\%params)

=cut

sub _initFromHash {
    my $self = shift;
    my $params = shift;

    $self->_setName($params->{'name'});
    $self->_setOwner($params->{'owner'});
    $self->_setContentType($params->{'content_type'});
    $self->_setPath($params->{'path'});
    $self->_setMaxLength($params->{'max_length'});
    $self->_setIsCached($params->{'is_cached'});
    $self->_setCacheName($params->{'cache_name'});
   
    unless ($self->getIsCached()) {
        return $self->_createThumbnail();
    }
    
    return TRUE;
}

=item _initEmpty()

=cut

sub _initEmpty {
    return FALSE;
}

=item _createThumbnail()

=cut

sub _createThumbnail {
    my $self = shift;
    my $path = $self->getPath();
 
    return FALSE unless (defined $path && -f $path);
    
    my $max_length = $self->getMaxLength() || DEFAULT_LENGTH;
    
    # Create a cache path if possible
    my $cache_path;
    if (defined $self->getOwner() && defined $self->_getCacheName()) {
        $cache_path = $self->_generateThumbnailPath();
        
        $self->_dirCheck($cache_path);
        
        $cache_path .= $self->_getCacheName();
    }
    
    # Read the file from a filehandle
    my $image = Image::Magick->new();
    my $msg = $image->Read(filename => $path);
    if ($msg) {
        warn "Image::Magick was unable to read filehandle: $msg" unless $msg =~ /^Exception (415|420)/;
        return FALSE;
    }

    # This pulls out the first frame of animated gifs
    # TODO: accessor to control this?
    # $image = $image->[0] if $image->[0];
    
    my ($width, $height) = $image->Get('width', 'height');

    # Resize if needed
    if ($height > $max_length || $width > $max_length) {
        # Create as large a thumbnail as possible, without height exceeding 
        # $max_length
        if ($height > $max_length) {
            ($width = int($width / $height * $max_length) || 1, $height = $max_length);
        }

        # But not TOO wide...
        if ($width > $max_length) {
            ($height = int($height / $width * $max_length) || 1, $width = $max_length);
        }

        $image->Resize(width => $width, height => $height);
    }
    
    $msg = $image->Write($cache_path || $path);
    #if ($msg) {
    #    warn "Image::Magick was unable to write to ".($cache_path || $path).": $msg";
    #    return FALSE;
    #}
    
    if (defined $cache_path) {
        $self->_setPath($cache_path);
        $self->_setIsCached(TRUE);
        unlink($path);
    }
    
    return TRUE;
}

=item _getAccessorDefinition()

=cut

sub _getAccessorDefinition {
    return [
        {
            name => 'MaxLength',
            key  => '_max_length',
            type => 'Integer',
        },
        {
            name => 'CacheName',
            key  => '_cache_name',
            type => 'String',
            private_set => TRUE,
            private_get => TRUE,
        },
        {
            name => 'IsCached',
            key  => '_is_cached',
            type => 'Boolean',
            private_set => TRUE,
        },
    ];
}

1;
__END__

=back

=head2 Modules Used

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
