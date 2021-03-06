#!/usr/bin/perl -w
#=============================================================================
# test01_write.t        lpOD-Perl installation test     2012-02-21T09:34:32
#=============================================================================
use 5.010_000;
use strict;
use Test;
BEGIN   { plan tests => 16 }

use ODF::lpOD;

#--- test parameters ---------------------------------------------------------

our $filename   = $ARGV[0] // "lpod_test.odt";
our $title      = "lpOD test";
our $subject    = "lpOD generated test document";

our %desc = (
        "lpOD version"                  => $ODF::lpOD::VERSION,
        "lpOD build"                    => ODF::lpOD->PACKAGE_DATE,
        "lpOD installation path"        => lpod->installation_path,
        "XML::Twig version"             => $XML::Twig::VERSION,
        "Archive::Zip version"          => $Archive::Zip::VERSION,
        "Perl version"                  => $],
        "Platform"                      => $^O
        );

our $announce    =
        "This document has been generated by the lpOD-Perl installation " .
        "test program. The main characteristics of your environment are " .
        "listed below.";

lpod->debug(TRUE);
my $elt;

#--- document initialization -------------------------------------------------

# Document creation check
my $doc = odf_new_document('text')
        or die "# Document initialisation failure. Stopped";
ok($doc && $doc->isa(odf_document), TRUE, "Document creation");

# Main context access check
my $context = $doc->get_body;
ok($context && $context->isa(odf_element));

# Metadata access check
my $meta = $doc->get_part(META);
ok($meta && $meta->isa(odf_xmlpart));

# Styles context access check
my $styles = $doc->get_part(STYLES);
ok($styles && $styles->isa(odf_xmlpart));

#--- metadata settings -------------------------------------------------------

$meta->set_generator(scalar lpod->info);
$meta->set_title($title);
$meta->set_subject($subject);
$meta->set_user_field("Project name", "lpOD", "string");
$meta->set_keywords("ODF", "Perl");

#--- paragraph style definitions ---------------------------------------------

# Default paragraph style creation
$elt = $doc->insert_style(
        odf_create_style(
                'paragraph',
                align           => 'justify',
                margin_top      => '2mm',
                margin_bottom   => '2mm',
                orphans         => 2,
                widows          => 2
                ),
        default => TRUE
        );
$elt->set_properties(
        area            => 'text',
        language        => 'en',
        country         => 'US'
        );
ok($elt && $elt->isa(odf_paragraph_style));

# Basic paragraph style creation
$elt = $doc->insert_style(
        odf_create_style(
                'paragraph',
                name            => "Basic",
                margin_top      => "0mm",
                margin_left     => "0mm"
                )
        );
ok($elt && $elt->isa(odf_paragraph_style));

# Level 2 Heading style creation
my $heading_style = $doc->insert_style(
        odf_create_style(
                'paragraph',
                name            => "Level 2 Heading",
                keep_with_next  => 'always',
                margin_top      => '1cm',
                margin_bottom   => '4mm'
                )
        );
$heading_style->set_properties(
        area            => 'text',
        size            => '16pt',
        weight          => 'bold',
        style           => 'italic',
        color           => 'navy blue'
        );
ok($heading_style && $heading_style->isa(odf_paragraph_style));

# top title style
$doc->insert_style(
        odf_create_style(
                'paragraph',
                name            => "Top title",
                align           => 'center',
                margin_top      => '0cm',
                margin_bottom   => '1cm'
                )
        )->set_properties(
                area            => 'text',
                size            => '200%',
                weight          => 'bold',
                color           => 'navy blue'
                );

# middle title style
$doc->insert_style(
        odf_create_style(
                'paragraph',
                name            => "Middle title",
                parent          => "Top title",
                margin_top      => '1cm',
                margin_bottom   => '8mm',
                master_page     => 'StdMaster'
                )
        )->set_background(color => 'light blue');

# style for the labels in the left column
$doc->insert_style(
        odf_create_style(
                'paragraph',
                name            => "Label",
                margin_left     => "3mm"
                )
        )->set_properties(
                area            => 'text',
                style           => 'italic'
                );

# style for the values in the right column
$doc->insert_style(
        odf_create_style(
                'paragraph',
                name            => "Content",
                margin_left     => "3mm"
                )
        )->set_properties(
                area            => 'text',
                weight          => 'bold'
                );

# footer paragraph style
$doc->insert_style(
        odf_create_style(
                'paragraph',
                name            => "SmallCentered",
                margin_top      => "1mm",
                margin_bottom   => "0mm",
                margin_left     => "0mm",
                margin_right    => "0mm",
                align           => 'center'
                )
        )->set_properties(
                area            => 'text',
                size            => '70%'
                );

# header subtitle style
$doc->insert_style(
        odf_create_style(
                'paragraph',
                name            => "LargeCentered",
                align           => 'center'
                )
        )->set_properties(
                area            => 'text',
                size            => '120%',
                style           => 'italic'
                );

#--- table style definition --------------------------------------------------

# Table style creation
$elt = $doc->insert_style(
        odf_create_style(
                'table',
                name            => "Environment",
                width           => '90%',
                align           => 'center',
                margin_top      => '8mm'
                )
        );
ok($elt && $elt->isa(odf_table_style));

$doc->insert_style(
        odf_create_style(
                'table column',
                name            => "C0",
                width           => "400*"
                )
        );

$doc->insert_style(
        odf_create_style(
                'table column',
                name            => "C1",
                width           => "600*"
                )
        );

$doc->insert_style(
        odf_create_style(
                'table cell',
                name            => "Sky"
                )
        )->set_background(color => '#E6F9FF');

#--- page style definition ---------------------------------------------------

# Page layout creation
$elt = $doc->insert_style(
        odf_create_style(
                'page layout',
                name    => "StdLayout",
                size    => "21cm, 29.7cm",
                margin  => "16mm"
                )
        );
ok($elt && $elt->isa(odf_page_layout));

# define the master page using the layout
# Master page creation
my $mp = $doc->insert_style(
        odf_create_style(
                'master page',
                name    => "StdMaster",
                layout  => "StdLayout"
                )
        );
ok($mp && $mp->isa(odf_master_page));

# define a header and a footer for the master page
my $header = $mp->set_header;
my $footer = $mp->set_footer;

# Table creation in the page header
my $ht = $header->append_element(
        odf_create_table("HeaderTable", size => "1, 2")
        );
ok($ht && $ht->isa(odf_table));

# Image frame creation
my $img_path = lpod->installation_path() . '/data/oasis_odf_logo.png';
my ($img, $size) = $doc->add_image_file($img_path);
ok($size);
my $fr = $ht->get_cell("A1")
        ->append_element(odf_create_paragraph(style => "Basic"))
        ->append_element(
                odf_create_image_frame(
                        $img,
                        name    => "Logo",
                        size    => $size,
                        title   => "OASIS ODF logo"
                        )
                );
$fr->set_hyperlink(url => 'http://opendocument.xml.org/logo');
ok($fr && $fr->isa(odf_frame));

# put 2 text paragraphs in the right cell of the table
$ht->get_cell("B1")->append_element(
        odf_create_paragraph(
                text    => "The lpOD Project",
                style   => "Top title"
                )
        );
$ht->get_cell("B1")->append_element(
        odf_create_paragraph(
                text    => "Open Document processing\nwith Perl",
                style   => "LargeCentered"
                )
        );

# put 2 centered paragraphs in the footer
$footer->append_element(
        odf_create_paragraph(
                text    => "Generated with lpOD",
                style   => "SmallCentered"
                )
        );
$footer->append_element(
        odf_create_paragraph(
                text    => scalar localtime,
                style   => "SmallCentered"
                )
        );

#--- document content providing ----------------------------------------------

# make sure that the document body is empty
$context->clear;

# put the main title
$context->append_element(
        odf_create_heading(
                level   => 1,
                text    => "Installation test",
                style   => "Middle title"
                )
        );

# Paragraph creation in document body
$elt = $context->append_element(odf_create_paragraph(text => $announce));
ok($elt && $elt->isa(odf_paragraph));

# put a bookmark in the paragraph
$elt->set_bookmark("Announce");

# Table creation in the document body
my $tbl = $context->append_element(
        odf_create_table(
                "Environment",
                length          => scalar keys %desc,
                width           => 2,
                style           => "Environment"
                )
        );
ok($tbl && $tbl->isa(odf_table));

# apply the appropriate style for each column
$tbl->get_column($_)->set_style("C$_") for (0..1);
$_->set_style("Sky") for $tbl->get_column('B')->get_cells;

# fill the table with the environment description
my $i = 0;
foreach my $k (sort keys %desc) {
        $tbl->get_cell($i, 0)->append_element(
                odf_create_paragraph(
                        text    => $k,
                        style   => "Label"
                        )
                );
        $tbl->get_cell($i, 1)->append_element(
                odf_create_paragraph(
                        text    => $desc{$k},
                        style   => "Content"
                        )
                );
        $i++;
        }

#=== COMMIT THE RESULT

# save the generated document and quit
ok($doc->save(target => $filename, pretty => TRUE));

exit 0;

#=== END
