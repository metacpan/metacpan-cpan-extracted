package Solstice::ContentTypeService;

# $Id: ContentTypeService.pm 2257 2005-05-19 17:31:38Z jlaney $

=head1 NAME

Solstice::ContentTypeService - Provides mappings between content-types and icons, MIMEExtensions, etc.

=head1 SYNOPSIS

    use Solstice::ContentTypeService;
    
    my $filename = 'filename.txt';

    my $service = Solstice::ContentTypeService->new();
 
    my $content_type = $service->getContentTypeByFilename($filename);
    # returns 'text/plain';
 
    my $description = $service->getContentDescriptionByContentType($content_type);
    # returns 'Plain text file'
 
    my $extension = $service->getExtensionByContentType($content_type);
    # returns 'txt'
 
=head1 DESCRIPTION

    Solstice::ContentTypeService is a service for identifying and
    depicting a file's content-type in various ways.

    How is this service useful? Let's say that you have identified a 
    file's content type as 'text/plain'. A view might wish to display an 
    appropriate icon for this content type (see Solstice::IconService), 
    as well as a 'human-readable' description, both of which can be 
    returned by this service.

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Service::Memory);

use File::MMagic;
use XML::LibXML;

use constant TRUE  => 1;
use constant FALSE => 0;
use constant ELEMENT_TYPE => 1;
use constant DEFAULT_CONTENT_TYPE => 'application/octet-stream';

# A hash of content types returned by File::MMagic::checktype_contents(),
# but that Apache can usually identify with greater precision.
my %VAGUE_CONTENT_TYPES = (
    'text/plain'                   => 1,
    'application/msword'           => 1,
    'application/x-zip'            => 1,
    'application/x-zip-compressed' => 1,
);

our ($VERSION) = ('$Revision: 2257 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::Service::Memory|Solstice::Service::Memory>

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut


=item new()

Creates a new Solstice::ContentTypeService object.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->_initialize();
    
    return $self;
}

=item getContentTypeByFilehandle($handle)

Returns a content-type for the passed filehandle, based on magic numbers.

=cut

sub getContentTypeByFilehandle {
    my $self = shift;
    my $handle = shift;

    return unless defined $handle;

    # Read the first 5k for content-type checking, then reset the pointer
    read($handle, my $temp, (1024*5));
    seek($handle, 0, 0);

    return $self->get('file_mmagic')->checktype_contents($temp);
}

=item getContentTypeByFilename($str)

Returns a content-type for the passed filename, or undef if a file extension cannot be discerned.

=cut

sub getContentTypeByFilename {
    my $self = shift;
    my $name = shift;

    return unless defined $name;

    my @parts = split(/\./, $name);
    return unless scalar(@parts) > 1;

    my $ext = pop(@parts);
    return unless defined $ext;

    $ext = lc $ext;
    return $self->get('file_extensions')->{$ext} || DEFAULT_CONTENT_TYPE;
}

=item getContentDescriptionByContentType($str)

=cut

sub getContentDescriptionByContentType {
    my $self = shift;
    my $type = _sanitize(shift);
    return $self->_getDataForType($type)->{'description'} ||
        $self->getLangService()->getString('unknown_content_type');
}
    
=item getExtensionByContentType($str)

=cut

sub getExtensionByContentType {
    my $self = shift;
    my $type = _sanitize(shift);
    return $self->_getDataForType($type)->{'default_extension'};
}

=item getIconByContentType($str)

=cut

sub getIconByContentType {
    my $self = shift;
    my $type = _sanitize(shift);
    return $self->_getDataForType($type)->{'icon'} || '0.gif';
}

=item getSynonymsForContentType($str)

Returns an array ref of content-type synonyms for the passed type.
The list includes the passed type.

=cut

sub getSynonymsForContentType {
    my $self = shift;
    my $type = _sanitize(shift);
   
    my @synonyms = ();
    if (my $parent = $self->getValue('content_types')->{$type}) {
        push @synonyms, $parent,
            @{$self->getValue('content_type_data')->{$parent}->{'synonyms'}};
    } else {
        push @synonyms, $type; # Unknown type
    }
    return \@synonyms;
}

=item getDownloadContentType($str)

Returns a content-type suitable for placing into a download header.
If the passed $type is a synonym, its parent type is returned.

=cut

sub getDownloadContentType {
    my $self = shift;
    my $type = _sanitize(shift);

    if (my $parent = $self->getValue('content_types')->{$type}) {
        return $parent;
    }
    return 'application/x-download'; 
}

=item isKnownType($str)

=cut

sub isKnownType {
    my $self = shift;
    my $type = _sanitize(shift);
    return exists $self->getValue('content_types')->{$type} ? TRUE : FALSE;
}

=item isVagueType($str)

Returns TRUE if the passed $type is a vague content type as returned 
by File::MMagic::checktype_contents().

=cut

sub isVagueType {
    my $self = shift;
    my $type = _sanitize(shift);

    return TRUE if exists $VAGUE_CONTENT_TYPES{$type};

    # Synonyms of DEFAULT_CONTENT_TYPE are also considered 'vague'.
    if (my $parent = $self->getValue('content_types')->{$type}) {
        return TRUE if DEFAULT_CONTENT_TYPE eq $parent;
    }
    return FALSE;
}

=item isTextType($str)

Returns TRUE if the passed $type is a web-viewable text type
or synonym, FALSE otherwise.

=cut

sub isTextType {
    my $self = shift;
    my $type = _sanitize(shift);

    if (my $parent = $self->getValue('content_types')->{$type}) {
        return ($parent =~ /^text\/(?:css|csv|html|javascript|plain|tsv|xml)$/) ? TRUE : FALSE;
    }
    return FALSE;
}

=item includesCharset($str)

checks if the type passed includes a charset declaration

=cut

sub includesCharset {
    my $self = shift;
    my $type = shift;

    return FALSE unless $type;

    return ($type =~ /;\s*charset\s*=\s*[\S]+$/) ? TRUE : FALSE;
}


=item isImageType($str)

Returns TRUE if the passed $type is a web-viewable image type
or synonym, FALSE otherwise.

=cut

sub isImageType {
    my $self = shift;
    my $type = _sanitize(shift);

    if (my $parent = $self->getValue('content_types')->{$type}) {
        return ($parent =~ /^image\/(?:gif|jpeg|png)$/) ? TRUE : FALSE;
    }
    return FALSE;
}

=back

=head2 Private Methods

=over 4

=cut

=item _initialize()

=cut

sub _initialize {
    my $self = shift;
    return TRUE if $self->getValue('initialized');
   
    my $conf_file = $self->getConfigService()->getRoot().'/conf/content_types.xml';
    my $ct_data = $self->_readXML($self->_parseXMLFile($conf_file));
    
    $self->setValue('content_type_data', $ct_data);
    $self->setValue('file_mmagic', File::MMagic->new());
    $self->setValue('initialized', TRUE);
    
    return TRUE;
}

=item _getDataForType($str)

=cut

sub _getDataForType {
    my $self = shift;
    my $type = shift;

    # Normalize content-type synonyms
    if (my $parent = $self->getValue('content_types')->{$type}) {
        return $self->getValue('content_type_data')->{$parent};
    }
    return {};
}

=item _validateXML($doc)

=cut

sub _validateXML {
    my $self = shift;
    my $doc = shift;

    my $schema_path = $self->getConfigService()->getRoot() .
        '/conf/schemas/content_types.xsd';

    my $schema = XML::LibXML::Schema->new(location => $schema_path);

    eval { $schema->validate($doc) };
    if ($@) {
        $self->{'_errstr'} = $@;
        return FALSE;
    }
    return TRUE;
}

=item _readXML($doc)

=cut

sub _readXML {
    my $self = shift;
    my $doc  = shift;
    my %ct_data   = ();
    my %all_exts  = ();
    my %all_types = ();

    for my $node ($doc->getDocumentElement()->childNodes()) {
        next unless (ELEMENT_TYPE == $node->nodeType() && 'content_type' eq $node->nodeName());
        
        my $content_type = $node->getAttribute('name');

        $ct_data{$content_type} = {
            description => $node->getAttribute('description'),
            icon        => $node->getAttribute('icon'),
        }; 
   
        my $extensions = [];
        my $synonyms   = [];
        for my $child ($node->childNodes()) {
            next unless ELEMENT_TYPE == $child->nodeType();
            if ('extensions' eq $child->nodeName()) {
                for my $ext_node ($child->getChildrenByTagName('extension')) {
                    my $extension = $ext_node->textContent();
                    $all_exts{lc $extension} = $content_type;
                    
                    push @$extensions, $extension;
                    
                    # Set the default extension for this content type
                    if ($ext_node->getAttribute('default')) {
                        $ct_data{$content_type}->{'default_extension'} = $extension;
                    }
                }
            } elsif ('synonyms' eq $child->nodeName()) {
                for my $syn_node ($child->getChildrenByTagName('synonym')) {
                    my $synonym = $syn_node->textContent();
                    $all_types{lc $synonym} = $content_type;

                    push @$synonyms, $synonym;
                }
            } 
        }

        $all_types{lc $content_type} = $content_type;
        $ct_data{$content_type}->{'extensions'} = $extensions;
        $ct_data{$content_type}->{'synonyms'} = $synonyms;
    }

    $self->setValue('file_extensions', \%all_exts);
    $self->setValue('content_types', \%all_types);

    return \%ct_data;
}

=item _parseXMLFile($path)

=cut

sub _parseXMLFile {
    my $self = shift;
    my $path = shift;

    my $parser = XML::LibXML->new();

    my $doc;
    eval { $doc = $parser->parse_file($path) };
    die "Content type file $path could not be parsed:\n$@\n" if $@;

    return $doc;
}

=back

=head2 Private Functions

=over 4

=cut

=item _sanitize($str)

=cut

sub _sanitize {
    my ($string) = @_;
    return '' unless defined $string;
    $string =~ s/;.*$//;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return lc $string;
}

=item _getClassName()

Return the class name. Overridden to avoid a ref() in the superclass.

=cut

sub _getClassName {
    return 'Solstice::ContentTypeService';
}

1;
__END__

=back

=head2 Modules Used

L<Solstice::Service::Memory|Solstice::Service::Memory>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 2257 $



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
