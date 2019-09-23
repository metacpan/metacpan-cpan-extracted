#!/usr/bin/env perl

package Quiq::Section::Parser::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

use Quiq::Path;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Section::Parser');
}

# -----------------------------------------------------------------------------

sub test_unitTest_statistic : Ignore(1) {
    my $self = shift;

    use Time::HiRes;

    my $par = Quiq::Section::Parser->new;
    $self->is(ref($par),'Quiq::Section::Parser');

    my @files = Quiq::Path->find('jaz',
        -type => 'f',
    );
    for my $file (@files) {
        $par->parse($file);
    }
    
    #my $t0 = Time::HiRes::gettimeofday;
    #my $objA = $par->parse($file);
    #my $time = Time::HiRes::gettimeofday-$t0;

    # warn sprintf "%s %.3f sec, %d objects\n",$file,$time,scalar(@$objA);
}

sub test_unitTest_empty1 : Test(1) {
    my $self = shift;

    my $par = Quiq::Section::Parser->new;
    my $objA = $par->parse(\'');
    $self->is(scalar(@$objA),0);
}

sub test_unitTest_empty2 : Test(8) {
    my $self = shift;

    my $text = <<'    __EOT__';
    # [Class]

    __EOT__
    $text =~ s/^    //mg;

    my $par = Quiq::Section::Parser->new;
    my $objA = $par->parse(\$text);
    $self->is(scalar(@$objA),1);

    my $obj = $objA->[0];

    $self->is($obj->type,'Class');
    $self->is($obj->brackets,'[]');

    my ($file,$lineNumber) = $obj->fileInfo;
    $self->is($file,'(source)');
    $self->is($lineNumber,1);

    my $hash = $obj->keyValHash;
    $self->is($hash->hashSize,0);

    $self->is($obj->content,'');
    $self->is($obj->source,$text);
}

sub test_unitTest_keyValContent : Test(10) {
    my $self = shift;

    my $text = <<'    __EOT__';
    # [Class]

    Language:
        Perl

    Name:
        Object

    Description:
        Dies ist die Basisklasse aller
        Klassen.

    Dies ist ein beliebiger
    Test-Text.

    __EOT__
    $text =~ s/^    //mg;

    my $par = Quiq::Section::Parser->new;
    my $objA = $par->parse(\$text);
    $self->is(scalar(@$objA),1);

    my $obj = $objA->[0];
    $self->is($obj->type,'Class');
    $self->is($obj->brackets,'[]');

    my ($file,$lineNumber) = $obj->fileInfo;
    $self->is($file,'(source)');
    $self->is($lineNumber,1);

    $self->is($obj->get('Language'),'Perl');
    $self->is($obj->get('Name'),'Object');
    $self->is($obj->get('Description'),
        "Dies ist die Basisklasse aller\nKlassen.");

    $self->is($obj->content,"Dies ist ein beliebiger\nTest-Text.");
    $self->is($obj->source,$text);
}

sub test_unitTest_condensed : Test(9) {
    my $self = shift;

    my $text = <<'    __EOT__';
    # [Class]

    Language:
      Perl
    Name:
      Object
    Description:
      Dies ist die Basisklasse aller
      Klassen.

    Dies ist ein beliebiger
    Test-Text.

    __EOT__
    $text =~ s/^    //mg;

    my $par = Quiq::Section::Parser->new;
    my $objA = $par->parse(\$text);
    $self->is(scalar(@$objA),1);

    my $obj = $objA->[0];
    $self->is($obj->type,'Class');
    $self->is($obj->brackets,'[]');
    my ($file,$lineNumber) = $obj->fileInfo;
    $self->is($file,'(source)');
    $self->is($lineNumber,1);
    $self->is($obj->get('Language'),'Perl');
    $self->is($obj->get('Name'),'Object');
    $self->is($obj->content,"Dies ist ein beliebiger\nTest-Text.");
    $self->is($obj->source,$text);
}

sub test_unitTest_content1 : Test(2) {
    my $self = shift;

    my $text = <<'    __EOT__';
    # [Class]

    Language:
        Perl

    Name:
        Object

    Description:
        Dies ist die Basisklasse aller
        Klassen.

    --BEGIN--


    Dies ist ein beliebiger
    Test-Text.

    __EOT__
    $text =~ s/^    //mg;

    my $obj = Quiq::Section::Parser->new->parse(\$text)->[0];
    $self->is($obj->content,"\n\nDies ist ein beliebiger\nTest-Text.");
    $self->is($obj->source,$text);
}

sub test_unitTest_content2 : Test(2) {
    my $self = shift;

    my $text = <<'    __EOT__';
    # [Class]

    Language:
        Perl

    Name:
        Object

    Description:
        Dies ist die Basisklasse aller
        Klassen.

    # ---


    Dies ist ein beliebiger
    Test-Text.

    __EOT__
    $text =~ s/^    //mg;

    my $obj = Quiq::Section::Parser->new->parse(\$text)->[0];
    $self->is($obj->content,"\nDies ist ein beliebiger\nTest-Text.");
    $self->is($obj->source,$text);
}

sub test_unitTest_content3 : Test(2) {
    my $self = shift;

    my $text = <<'    __EOT__';
    # [Class]

    Language:
        Perl

    Name:
        Object

    Description:
        Dies ist die Basisklasse aller
        Klassen.

    # ---
    Dies ist ein beliebiger
    Test-Text.

    __EOT__
    $text =~ s/^    //mg;

    my $obj = Quiq::Section::Parser->new->parse(\$text)->[0];
    $self->is($obj->content,"Dies ist ein beliebiger\nTest-Text.");
    $self->is($obj->source,$text);
}

sub test_unitTest_stop : Test(1) {
    my $self = shift;

    my $text = <<'    __EOT__';
    # [Class]

    Language:
        Perl

    Name:
        Object

    Description:
        Dies ist die Basisklasse aller
        Klassen.

    Stop:
        --END--

    --BEGIN--

    Dies ist ein beliebiger
    Test-Text.

    --END--

    __EOT__
    $text =~ s/^    //mg;

    my $par = Quiq::Section::Parser->new;
    my $obj = $par->parse(\$text)->[0];
    $self->is($obj->content,"\nDies ist ein beliebiger\nTest-Text.\n\n");
}

sub test_unitTest_comment1 : Test(11) {
    my $self = shift;

    my $text = <<"    __EOT__";
    # [Class]

    Language:
        Perl

    Name:
        Object

    Imports:
        \!\! Module1
        Module2 \!\! ist besser

    \!\! Description:
    \!\!    Dies ist die Basisklasse aller
    \!\!    Klassen.

    Dies ist ein beliebiger
    Test-Text.

    __EOT__
    $text =~ s/^    //mg;

    my $par = Quiq::Section::Parser->new;
    my $objA = $par->parse(\$text);
    $self->is(scalar(@$objA),1);

    my $obj = $objA->[0];
    $self->is($obj->type,'Class');
    $self->is($obj->brackets,'[]');

    my ($file,$lineNumber) = $obj->fileInfo;
    $self->is($file,'(source)');
    $self->is($lineNumber,1);

    $self->is($obj->get('Language'),'Perl');
    $self->is($obj->get('Name'),'Object');
    $self->is($obj->get('Imports'),'Module2');
    $self->is($obj->get('Description'),undef);

    $self->is($obj->content,"Dies ist ein beliebiger\nTest-Text.");
    $self->is($obj->source,$text);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Section::Parser::Test->runTests;

# eof
