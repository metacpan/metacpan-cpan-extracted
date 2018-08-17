package OpenOffice::OODoc::InsertDocument;

use strict;
use warnings;

# ABSTRACT: Insert, merge or append OpenOffice::OODoc objects
#
# LICENSE: This file is covered by the EUPL license, please see the
# LICENSE file in this repository for more information

our $VERSION = '0.03';

use OpenOffice::OODoc;

use List::Util 'max';
use Readonly;


# patch the original OpenOffice::OODoc module and add these subroutines
#
*OpenOffice::OODoc::Document::insertDocument =
    \&OpenOffice::OODoc::InsertDocument::insertDocument;

Readonly my %stylefamily_map => (
    'paragraph'  => 'P',
    'text'       => 'T',
    'list-style' => 'L',
);


sub appendDocument {
    ...
}


sub insertDocument {
    my $oodoc_dest_document = shift; # or $self
    my $oodoc_path          = shift;
    my $position            = shift;
    my $oodoc_from_document = shift;

    # if we have a $oodoc_dest_test_style, it means we have a custom, local
    # style, otherwise we are using this insertDocument in 'default' styling.
    my $oodoc_dest_text_style_name =
        $oodoc_dest_document->textStyle($oodoc_path);
    my $oodoc_dest_text_style =
        $oodoc_dest_document->getStyleElement($oodoc_dest_text_style_name);

    my $transliteration_map =
        _getStyleNameTransliterationMap(
            $oodoc_dest_document,
            $oodoc_from_document,
            include_body_styles => defined($oodoc_dest_text_style),
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

    return unless defined($oodoc_dest_text_style);

    # update or create styles
    my $style_attributes = { text => {}, paragraph => {} };
    foreach my $area ( keys %$style_attributes ) {
        my $style_property = "(style:$area-properties)";
        my ($style_element) =
            $oodoc_dest_text_style->selectChildElements($style_property)
            or
            next;

        $style_attributes->{$area} =
            { $oodoc_dest_document->getStyleAttributes($style_element) }->{references} || {};
    };

    $style_attributes->{style} = { $oodoc_dest_text_style->getAttributes() };

    foreach my $style_name ( values %$transliteration_map ) {

        next if $style_name =~ /T\d+/;

        my $oodoc_style =
            $oodoc_dest_document->textStyle($style_name)
            or
            $oodoc_dest_document->createStyle( $style_name =>
                'class'        => 'text',
                'display-name' => "Default",
                'family'       => 'paragraph',
                'parent'       =>
                    $style_attributes->{style}->{'style:parent-style-name'}
                    ||
                    'Standard',
            )
            or
            next;

        $oodoc_from_document->updateStyle( $style_name =>
            'properties' => {
                '-area' => $_,
                %{$style_attributes->{$_}},
            }
        ) foreach qw/ paragraph text /;
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
    my %params = @_;

    my $family_max = {};
    my $transliteration_map = {};

    foreach my $family ( keys %stylefamily_map ) {
        $family_max->{$family}->{dest} =
            _maxUsedNumberAutoStyleFamily($oodoc_dest_document, $family);
        $family_max->{$family}->{from} =
            _maxUsedNumberAutoStyleFamily($oodoc_from_document, $family);

        $transliteration_map->{ $stylefamily_map{$family} . $_ } =
            $stylefamily_map{$family} . ( $_ + $family_max->{$family}->{dest} )
                for 1 .. $family_max->{$family}->{from}

    };

    # create aditional mappings, just in case we might need them
    if ( $params{include_body_styles} ) {
        foreach my $style_name ( qw/ Text_20_body First_20_paragraph /) {
            my @elements = $oodoc_from_document->getBody->selectChildElements(
                'text:p',,'text:style-name="'.$style_name.'"'
            );
            if ( @elements ) {
                $transliteration_map->{$style_name} = 'P' .
                    ( $family_max->{'paragraph'}{dest} + ++$family_max->{'paragraph'}{from} )
            }
        }
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

    my $xpath = sprintf './/[@%s =~ /^([LPT]\d+|Text_20_body|First_20_paragraph)$/ ]', $attribute_name;
    foreach my $node ( $oodoc_element->findnodes($xpath) ) {
        my $stylename_old = $node->getAttribute($attribute_name);
        my $stylename_new = $transliteration_map->{$stylename_old};
        $node->setAttribute($attribute_name, $stylename_new);
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenOffice::OODoc::InsertDocument - Insert, merge or append OpenOffice::OODoc objects

=head1 VERSION

version 0.03

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

=head1 METHODS

=head2 appendDocument TODO

Inserts an OpenOffice::OODoc at the end off the document.

    $oodoc_orig->appendDocument( $oodoc_from, new_page => 1 );

=head2 insertDocument

Inserts a OODoc document at location.

    $oodoc_dest_document->insertDocument( $oodoc_element, 'after', $oodoc_from );

If there is any style associated with the C<$oodoc_element>, than that will be
used for styling the document to be inserted. Otherwise, it will use default
body styles instead.

=head1 AUTHOR

Theo van Hoesel <theo@mintlab.nl>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Mintlab / Zaaksysteem.nl.

This is free software, licensed under:

  The European Union Public License (EUPL) v1.1

=cut
