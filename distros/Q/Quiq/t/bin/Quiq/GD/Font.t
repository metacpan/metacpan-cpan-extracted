#!/usr/bin/env perl

package Quiq::GD::Font::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;
use utf8;

# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------

sub initMethod : Init(2) {
    my $self = shift;

    eval {require GD};
    if ($@) {
        $self->skipAllTests('GD not installed');
        return;
    }
    $self->ok(1);

    $self->useOk('Quiq::GD::Font');
}

# -----------------------------------------------------------------------------

sub test_new_ttf : Test(2) {
    my $self = shift;

    eval {Quiq::GD::Font->new('/tmp/abcd.ttf',20)};
    $self->like($@,qr/GDFONT-00001/);

    # TrueType-Font - wir brauchen den absoluten Pfad
    my $file = Quiq::Test::Class->testPath('quiq/test/data/font/pala.ttf');

    my $fnt = Quiq::GD::Font->new($file,20);
    $self->is(ref($fnt),'Quiq::GD::Font');

    $self->set(ttFont=>$fnt);
}

sub test_new_gd : Test(5) {
    my $self = shift;

    # die 5 Standard-GD-Fonts

    my $fnt = Quiq::GD::Font->new('gdTinyFont');
    $self->is(ref($fnt),'Quiq::GD::Font');
    $self->set(gdTinyFont=>$fnt);

    $fnt = Quiq::GD::Font->new('gdSmallFont');
    $self->is(ref($fnt),'Quiq::GD::Font');
    $self->set(gdSmallFont=>$fnt);

    $fnt = Quiq::GD::Font->new('gdMediumBoldFont');
    $self->is(ref($fnt),'Quiq::GD::Font');
    $self->set(gdMediumBoldFont=>$fnt);

    $fnt = Quiq::GD::Font->new('gdLargeFont');
    $self->is(ref($fnt),'Quiq::GD::Font');
    $self->set(gdLargeFont=>$fnt);

    $fnt = Quiq::GD::Font->new('gdGiantFont');
    $self->is(ref($fnt),'Quiq::GD::Font');
    $self->set(gdGiantFont=>$fnt);
}

# -----------------------------------------------------------------------------

sub test_name_ttf : Test(1) {
    my $self = shift;

    my $fnt = $self->get('ttFont');
    $self->is($fnt->name,'pala20');
}

sub test_name_gd : Test(1) {
    my $self = shift;

    my $fnt = $self->get('gdTinyFont');
    $self->is($fnt->name,'gdTinyFont');
}

# -----------------------------------------------------------------------------

sub test_pt_ttf : Test(1) {
    my $self = shift;

    my $fnt = $self->get('ttFont');
    $self->is($fnt->pt,20);
}

sub test_pt_gd : Test(1) {
    my $self = shift;

    my $fnt = $self->get('gdTinyFont');
    $self->is($fnt->pt,undef);
}

# -----------------------------------------------------------------------------

sub test_isTrueType_ttf : Test(1) {
    my $self = shift;

    my $fnt = $self->get('ttFont');
    $self->is($fnt->isTrueType,1);
}

sub test_isTrueType_gd : Test(1) {
    my $self = shift;

    my $fnt = $self->get('gdTinyFont');
    $self->is($fnt->isTrueType,0);
}

# -----------------------------------------------------------------------------

sub test_stringGeometry_gdTiny : Test(12) {
    my $self = shift;

    my $fnt = $self->get('gdTinyFont');
    my ($width,$height,$xOffset,$yOffset) = $fnt->stringGeometry('X');
    $self->is($width,5);
    $self->is($height,8);
    $self->is($xOffset,0);
    $self->is($yOffset,0);

    ($width,$height,$xOffset,$yOffset) = $fnt->stringGeometry('XYZ');
    $self->is($width,15);
    $self->is($height,8);
    $self->is($xOffset,0);
    $self->is($yOffset,0);

    ($width,$height,$xOffset,$yOffset) = $fnt->stringGeometry('XYZ',-up=>1);
    $self->is($width,8);
    $self->is($height,15);
    $self->is($xOffset,0);
    $self->is($yOffset,0);
}

sub test_stringGeometry_gdSmall : Test(2) {
    my $self = shift;

    my $fnt = $self->get('gdSmallFont') ;
    my ($width,$height,$xOffset,$yOffset) = $fnt->stringGeometry('X');
    $self->is($width,6);
    $self->is($height,13);
}

sub test_stringGeometry_gdMediumBold : Test(2) {
    my $self = shift;

    my $fnt = $self->get('gdMediumBoldFont') ;
    my ($width,$height,$xOffset,$yOffset) = $fnt->stringGeometry('X');
    $self->is($width,7);
    $self->is($height,13);
}

sub test_stringGeometry_gdLarge : Test(2) {
    my $self = shift;

    my $fnt = $self->get('gdLargeFont') ;
    my ($width,$height,$xOffset,$yOffset) = $fnt->stringGeometry('X');
    $self->is($width,8);
    $self->is($height,16);
}

sub test_stringGeometry_gdGiant : Test(2) {
    my $self = shift;

    my $fnt = $self->get('gdGiantFont') ;
    my ($width,$height,$xOffset,$yOffset) = $fnt->stringGeometry('X');
    $self->is($width,9);
    $self->is($height,15);
}

# -----------------------------------------------------------------------------

sub test_charWidth_ttf : Test(1) {
    my $self = shift;

    my $fnt = $self->get('ttFont');
    # Verschiedene Ergebnisse möglich, je nach Font oder libgd-Version
    $self->in($fnt->charWidth,[20,23,26]);
}

sub test_charWidth_gd : Test(5) {
    my $self = shift;

    my $fnt = $self->get('gdTinyFont');
    $self->is($fnt->charWidth,5);

    $fnt = $self->get('gdSmallFont');
    $self->is($fnt->charWidth,6);

    $fnt = $self->get('gdMediumBoldFont');
    $self->is($fnt->charWidth,7);

    $fnt = $self->get('gdLargeFont');
    $self->is($fnt->charWidth,8);

    $fnt = $self->get('gdGiantFont');
    $self->is($fnt->charWidth,9);
}

# -----------------------------------------------------------------------------

sub test_charHeight_ttf : Test(1) {
    my $self = shift;

    my $fnt = $self->get('ttFont');
    # Verschiedene Ergebnisse möglich, je nach Font oder libgd-Version
    $self->in($fnt->charHeight,[27,28]);
}

sub test_charHeight_gd : Test(5) {
    my $self = shift;

    my $fnt = $self->get('gdTinyFont');
    $self->is($fnt->charHeight,8);

    $fnt = $self->get('gdSmallFont');
    $self->is($fnt->charHeight,13);

    $fnt = $self->get('gdMediumBoldFont');
    $self->is($fnt->charHeight,13);

    $fnt = $self->get('gdLargeFont');
    $self->is($fnt->charHeight,16);

    $fnt = $self->get('gdGiantFont');
    $self->is($fnt->charHeight,15);
}

# -----------------------------------------------------------------------------

sub test_digitWidth_ttf : Test(1) {
    my $self = shift;

    my $fnt = $self->get('ttFont');
    # Verschiedene Ergebnisse möglich, je nach Font oder libgd-Version
    $self->in($fnt->digitWidth,[14,16,18]);
}

sub test_digitWidth_gd : Test(5) {
    my $self = shift;

    my $fnt = $self->get('gdTinyFont');
    $self->is($fnt->digitWidth,5);

    $fnt = $self->get('gdSmallFont');
    $self->is($fnt->digitWidth,6);

    $fnt = $self->get('gdMediumBoldFont');
    $self->is($fnt->digitWidth,7);

    $fnt = $self->get('gdLargeFont');
    $self->is($fnt->digitWidth,8);

    $fnt = $self->get('gdGiantFont');
    $self->is($fnt->digitWidth,9);
}

# -----------------------------------------------------------------------------

sub test_digitHeight_ttf : Test(1) {
    my $self = shift;

    my $fnt = $self->get('ttFont');
    # auf vostro 20, auf kopc02 21
    $self->ok($fnt->digitHeight >= 20);
}

sub test_digitHeight_gd : Test(5) {
    my $self = shift;

    my $fnt = $self->get('gdTinyFont');
    $self->is($fnt->digitHeight,8);

    $fnt = $self->get('gdSmallFont');
    $self->is($fnt->digitHeight,13);

    $fnt = $self->get('gdMediumBoldFont');
    $self->is($fnt->digitHeight,13);

    $fnt = $self->get('gdLargeFont');
    $self->is($fnt->digitHeight,16);

    $fnt = $self->get('gdGiantFont');
    $self->is($fnt->digitHeight,15);
}

# -----------------------------------------------------------------------------

package main;
Quiq::GD::Font::Test->runTests;

# eof
