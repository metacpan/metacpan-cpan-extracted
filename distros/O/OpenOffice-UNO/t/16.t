#!/usr/bin/perl -w

use strict;
use warnings;
use lib qw(t/lib);
use Test::More tests => 1;

use UnoTest;

my ($pu, $smgr) = get_service_manager();

my $rc = $smgr->getPropertyValue("DefaultContext");

my $dt = $smgr->createInstanceWithContext("com.sun.star.frame.Desktop", $rc);

my @args = ();

my $sdoc = $dt->loadComponentFromURL("private:factory/swriter", "_blank", 0, \@args);

my $oText = $sdoc->getText();

my $oCursor = $oText->createTextCursor();

my $table = $sdoc->createInstance("com.sun.star.text.TextTable");

$table->initialize(4, 4);
$oText->insertTextContent($oCursor, $table, 0);

my $rows = $table->getRows();

$table->setPropertyValue("BackTransparent", new OpenOffice::UNO::Boolean(0));
$table->setPropertyValue("BackColor", new OpenOffice::UNO::Int32(13421823) );
my $row = $rows->getByIndex(0);
$row->setPropertyValue("BackTransparent", new OpenOffice::UNO::Boolean(0));
$row->setPropertyValue("BackColor", new OpenOffice::UNO::Int32(6710932) );
my $textColor = 16777215;

&insertTextIntoCell($table, "A1", "FirstColumn", $textColor);
&insertTextIntoCell($table, "B1", "SecondColumn", $textColor);
&insertTextIntoCell($table, "C1", "ThirdColumn", $textColor);
&insertTextIntoCell($table, "D1", "SUM", $textColor);

$table->getCellByName("A2")->setValue(22.5);
$table->getCellByName("B2")->setValue(5615.3);
$table->getCellByName("C2")->setValue(-2315.7);
$table->getCellByName("D2")->setFormula("sum <A2:C2>");

$table->getCellByName("A3")->setValue(21.5);
$table->getCellByName("B3")->setValue(615.3);
$table->getCellByName("C3")->setValue(-315.7);
$table->getCellByName("D3")->setFormula("sum <A3:C3>");

$table->getCellByName("A4")->setValue(121.5);
$table->getCellByName("B4")->setValue(-615.3);
$table->getCellByName("C4")->setValue(415.7);
$table->getCellByName("D4")->setFormula("sum <A4:C4>");

$sdoc->dispose();

ok( 1, 'Got there' );

sub insertTextIntoCell {
    my ($tabl, $cellName, $text, $color) = @_;

    my $tableText = $tabl->getCellByName( $cellName );
    my $cursor = $tableText->createTextCursor();
    $cursor->setPropertyValue( "CharColor", new OpenOffice::UNO::Int32($color) );
    $tableText->setString( $text );
}
