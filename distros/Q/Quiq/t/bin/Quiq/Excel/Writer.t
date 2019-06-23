#!/usr/bin/env perl

package Quiq::Excel::Writer::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Quiq::TempFile;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Excel::Writer');
}

# -----------------------------------------------------------------------------

sub test_unitTest: Test(1) {
    my $self = shift;

    my $file = Quiq::TempFile->new(
        -suffix => '.xlsx',
        # Die folgenden beiden Zeilen einkommentieren, um das
        # von diesem Test erzeugte Excelsheet anzusehen
        # -dir => '~/tmp',
        # -unlink => 0,
    );

    # * Code aus dem Abschnitt SYNOPSIS des Moduls Excel::Writer::XLSX *

    # Create a new Excel workbook
    my $wkb = Quiq::Excel::Writer->new("$file");
    $self->is(ref($wkb),'Quiq::Excel::Writer');

    # Add a worksheet
    my $wks = $wkb->add_worksheet;
 
    # Add and define a format

    my $fmt = $wkb->add_format;
    $fmt->set_bold;
    $fmt->set_color('red');
    $fmt->set_align('center');
 
    # Write a formatted and unformatted string, row and column notation.

    my $col = my $row = 0;
    $wks->write($row,$col,'Hi Excel!',$fmt );
    $wks->write(1,$col,'Hi Excel!');
 
    # Write a number and a formula using A1 notation

    $wks->write('A3',1.2345);
    $wks->write('A4','=SIN(PI()/4)');

    $wkb->close;
}

# -----------------------------------------------------------------------------

package main;
Quiq::Excel::Writer::Test->runTests;

# eof
