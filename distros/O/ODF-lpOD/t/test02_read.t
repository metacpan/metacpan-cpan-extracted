#!/usr/bin/perl -w
#=============================================================================
# test02_read.t         lpOD-Perl installation test     2012-02-21T09:37:57
#=============================================================================
use 5.010_000;
use strict;
use Test;
BEGIN   { plan tests => 19 }

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

lpod->debug(TRUE);
my $elt;

#--- document initialization -------------------------------------------------

# Document access check
my $doc = odf_get_document($filename)
        or die "# Document initialisation failure. Stopped";
ok($doc && $doc->isa(odf_document));

# Document body access check
my $context = $doc->get_body;
ok($context && $context->isa(odf_element));

# Metadata access check
my $meta = $doc->get_part(META);
ok($meta && $meta->isa(odf_xmlpart));

# Styles context access check
my $styles = $doc->get_part(STYLES);
ok($styles && $styles->isa(odf_xmlpart));

#--- metadata settings -------------------------------------------------------

# Generator signature check
ok($meta->get_generator(), scalar lpod->info);
# Document title check
ok($meta->get_title(), $title);
# Document subject check
ok($meta->get_subject(), $subject);
# User field check
ok($meta->get_user_field("Project name"), "lpOD");
# Document keyword check
ok($meta->check_keyword("ODF"));

#--- style definitions -------------------------------------------------------

# Basic paragraph style check
$elt = $doc->get_style('paragraph', "Basic");
ok($elt && $elt->isa(odf_paragraph_style));

#--- table style definition --------------------------------------------------

# Table style check
$elt = $doc->get_style('table', "Environment");
ok($elt && $elt->isa(odf_table_style));

#--- page style definition ---------------------------------------------------

# Page layout check
$elt = $doc->get_style('page layout', "StdLayout");
ok($elt && $elt->isa(odf_page_layout));

# Master page check
$elt = $doc->get_style('master page', "StdMaster");
ok($elt && $elt->isa(odf_master_page));

# Frame check
$elt = $elt->get_frame("Logo");
ok($elt && $elt->isa(odf_frame));

# Frame title check
ok($elt->get_title(), "OASIS ODF logo");

#--- bookmark retrieval ------------------------------------------------------

# Paragraph retrieval by bookmark
$elt = $context->get_paragraph_by_bookmark("Announce");
ok($elt && $elt->isa(odf_paragraph));

#--- table retrieval ---------------------------------------------------------

# Table retrieval check
my $tbl = $context->get_table("Environment");
ok($tbl && $tbl->isa(odf_table));

# Table size check
my ($l, $w) = $tbl->get_size;
ok($l == scalar keys %desc && $w == 2);

# Table content check
$elt = TRUE;
for (my $i = 0 ; $i < $l ; $i++) {
        my $k = $tbl->get_cell($i, 0)->get_text;
        my $v = $tbl->get_cell($i, 1)->get_text;
        unless ($v eq $desc{$k})
                {
                alert "# Error: Unexpected value in table row $i";
                $elt = FALSE;
                }
        }
ok($elt);

#--- end ---------------------------------------------------------------------

exit 0;

#=== END =====================================================================
