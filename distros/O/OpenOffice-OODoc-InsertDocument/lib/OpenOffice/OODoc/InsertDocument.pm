package OpenOffice::OODoc::InsertDocument;

use strict;
use warnings;

=head1 NAME

OpenOffice::OODoc::InsertDocument - insert, merge or append OpenOffice::OODoc objects

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

use OpenOffice::OODoc;

use List::Util 'max';
use Readonly;

=head1 SYNOPSIS

    use OpenOffice::OODoc;
    
    my $oodoc_dest_document = odfDocument(file => "MyDestFile.odt");
    my $oodoc_from_document = odfDocument(file => "MyFromFile.odt");
    
    my $replace_me_element = $oodoc_dest_document
        ->selectElementByContent("[[ replace_me ]]");
    $oodoc_dest_document
        ->insertDocument( $replace_me_element, 'before', $oodoc_from_document );
    $replace_me_element->delete;

=head1 DESCRIPTION

This module will enable to merge the content from one L<OpenOffice::OODoc> into
another.

=cut

# patch the original OpenOffice::OODoc module and add these subroutines
#
*OpenOffice::OODoc::Document::insertDocument =
    \&OpenOffice::OODoc::InsertDocument::insertDocument;

Readonly my %stylefamily_map => (
    'paragraph'  => 'P',
    'text'       => 'T',
    'list-style' => 'L',
);

=head1 METHODS

=head2 appendDocument TODO

Inserts an OpenOffice::OODoc at the end off the document.

    $oodoc_orig->appendDocument( $oodoc_from, new_page => 1 );

=cut

sub appendDocument {
    ...
}

=head2 insertDocument

Inserts a OODoc document at location.

    $oodoc_dest_document->insertDocument( $oodoc_element, 'after', $oodoc_from );

=cut

sub insertDocument {
    my $oodoc_dest_document = shift; # or $self
    my $oodoc_path          = shift;
    my $position            = shift;
    my $oodoc_from_document = shift;

        my $transliteration_map =
        _getStyleNameTransliterationMap(
            $oodoc_dest_document,
            $oodoc_from_document,
        );

    # rename, select, and paste the auto-style definitions
    _transliterateStyleNames(
        $oodoc_from_document->getAutoStyleRoot,
        $transliteration_map,
    );
    my @oodoc_from_auto_style_nodes =
        $oodoc_from_document->getAutoStyleRoot->selectChildElements(
            '(style:style|text:list-style)'
        );
    foreach my $oodoc_from_auto_style_node (@oodoc_from_auto_style_nodes) {
        $oodoc_from_auto_style_node->paste_last_child(
            $oodoc_dest_document->getAutoStyleRoot );
    }

    # rename, select, and paste the document's text elements
    _transliterateStyleNames(
        $oodoc_from_document->getBody,
        $transliteration_map,
    );
    my @oodoc_from_text_elements =
        $oodoc_from_document->getBody->selectChildElements(
            'text:(p|h|list)'
        );
    foreach my $oodoc_from_text_element (@oodoc_from_text_elements) {
        $oodoc_dest_document->insertElement( $oodoc_path,
            $oodoc_from_text_element, position => $position, );
    }

}

# _getStyleNameTransliterationMap
#
# Returns a HashRef that explains how to transliterate autostyles, such that two
# documents can be merged without conflicting style names.
#
sub _getStyleNameTransliterationMap {
    my $oodoc_dest_document = shift;
    my $oodoc_from_document = shift;

    my $transliteration_map = {};
    foreach my $family ( keys %stylefamily_map ) {
        my $family_dest_max = _maxUsedNumberAutoStyleFamily($oodoc_dest_document, $family);
        $transliteration_map->{ $stylefamily_map{$family} . $_ } =
            $stylefamily_map{$family} . ( $_ + $family_dest_max )
                for 1 .. _maxUsedNumberAutoStyleFamily($oodoc_from_document, $family)
    }
    return $transliteration_map
}

# _maxUsedNumberAutoStyleFamily
#
# returns the highest used numberr for a given style family (must be one of the
# stylefamily_map families)
#
sub _maxUsedNumberAutoStyleFamily {
    my $oodoc_document = shift;
    my $family         = shift;

    my @oodoc_styles = $oodoc_document
        ->getAutoStyleRoot
        ->selectChildElements('(style:style|text:list-style)');

    return max ( 
        map {
            $oodoc_document->getAttribute($_, 'style:name') =~ /$stylefamily_map{$family}(\d+)/
        } @oodoc_styles
    ) || 0
}

# _transliterateStyleNames
#
# Renames every Auto Style in the given OODoc Element and it's decendants
#
sub _transliterateStyleNames {
    my $oodoc_element       = shift;
    my $transliteration_map = shift;

    _transliterateStyleNamesAtrr($oodoc_element, $transliteration_map, $_)
        for qw/
            text:style-name
            style:name
            style:list-style-name
        /
    ;

    return
}

# _transliterateStyleNamesAtrr
#
# set the style name attributes to a new value, based on the transliteration_map
#
sub _transliterateStyleNamesAtrr{
    my $oodoc_element       = shift;
    my $transliteration_map = shift;
    my $attribute_name      = shift;

    my $xpath = sprintf './/[@%s =~ /^[LPT]\d+$/ ]', $attribute_name;
    foreach my $node ( $oodoc_element->findnodes($xpath) ) {
        my $stylename_old = $node->getAttribute($attribute_name);
        my $stylename_new = $transliteration_map->{$stylename_old};
        $node->setAttribute($attribute_name, $stylename_new);
    }
}

1;

__END__

=head1 CAVEAT



=head1 COPYRIGHT

Copyright (c) 2018, Th. J. van Hoesel - Mintlab B.V.

=head1 LICENCE

This software is distributed, subject to the EUPL. You may not use this file
except in compliance with the License. You may obtain a copy of the License at
<http://joinup.ec.europa.eu/software/page/eupl>

Software distributed under the License is distributed on an "AS IS"vbasis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the
specific language governing rights and limitations under the License.
