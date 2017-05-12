#!/usr/bin/perl -w

use strict;
use warnings;
use lib qw(t/lib);
use Test::More tests => 1;

use UnoTest;

my ($pu, $smgr) = get_service_manager();

my $rc = $smgr->getPropertyValue("DefaultContext");

my $dt = $smgr->createInstanceWithContext("com.sun.star.frame.Desktop", $rc);

my $pv = $pu->createIdlStruct("com.sun.star.beans.PropertyValue");

$pv->Name("Hidden");
$pv->Value(1);

my $sdoc = $dt->loadComponentFromURL(get_file("test2.sxw"), "_blank", 0, [$pv]);

my $pv1 = $pu->createIdlStruct("com.sun.star.beans.PropertyValue");
$pv1->Name("Overwrite");
$pv1->Value(1);

my $pv2 = $pu->createIdlStruct("com.sun.star.beans.PropertyValue");
$pv2->Name("FilterName");
$pv2->Value("writer_pdf_Export");

my $layout = $pu->createIdlStruct("com.sun.star.beans.PropertyValue");
$layout->Name("PageLayout");
$layout->Value(new OpenOffice::UNO::Int32(3));

my $pages = $pu->createIdlStruct("com.sun.star.beans.PropertyValue");
$pages->Name("PageRange");
$pages->Value("2-3");

my $pv3 = $pu->createIdlStruct("com.sun.star.beans.PropertyValue");
$pv3->Name("FilterData");
$pv3->Value(new OpenOffice::UNO::Any("[]com.sun.star.beans.PropertyValue",
                                     [$layout, $pages]));

# Save as
$sdoc->storeAsURL(get_file("test2_save.sxw"), [ $pv1 ] );
# Export to PDF, with filter data
$sdoc->storeToURL(get_file("test2_export.pdf"), [ $pv1, $pv2, $pv3 ] );

# Close doc
$sdoc->dispose();

ok( 1, 'Got there' );
