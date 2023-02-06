#!/usr/bin/env perl

package Quiq::Confluence::Markup::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Confluence::Markup');
}

# -----------------------------------------------------------------------------

sub test_link : Test(2) {
    my $self = shift;

    my $gen = Quiq::Confluence::Markup->new;
    
    my $markup = $gen->link('https://confluence.atlassian.com/');
    $self->is($markup,'[https://confluence.atlassian.com/]');

    $markup = $gen->link('https://confluence.atlassian.com/','Atlassian');
    $self->is($markup,'[Atlassian|https://confluence.atlassian.com/]');
}

# -----------------------------------------------------------------------------

sub test_paragraph : Test(2) {
    my $self = shift;

    my $gen = Quiq::Confluence::Markup->new;
    
    my $markup = $gen->paragraph('');
    $self->is($markup,'');

    $markup = $gen->paragraph("Ein\nTest");
    $self->is($markup,"Ein Test\n\n");
}

# -----------------------------------------------------------------------------

sub test_tableHeaderRow : Test(2) {
    my $self = shift;

    my $gen = Quiq::Confluence::Markup->new;
    
    my $markup = $gen->tableHeaderRow(qw/A B C D/);
    $self->is($markup,"||A||B||C||D||\n");

    $markup = $gen->tableHeaderRow('A','','B','C','D');
    $self->is($markup,"||A|| ||B||C||D||\n");
}

# -----------------------------------------------------------------------------

sub test_tableRow : Test(2) {
    my $self = shift;

    my $gen = Quiq::Confluence::Markup->new;
    
    my $markup = $gen->tableRow(1,2,3,4);
    $self->is($markup,"|1|2|3|4|\n");

    $markup = $gen->tableRow(1,undef,2,3,4);
    $self->is($markup,"|1| |2|3|4|\n");
}

# -----------------------------------------------------------------------------

sub test_section : Test(2) {
    my $self = shift;

    my $gen = Quiq::Confluence::Markup->new;
    
    my $markup = $gen->section(1,'Test');
    $self->is($markup,"h1. Test\n\n");

    $markup = $gen->section(1,'Test',"Ein\nTest");
    $self->is($markup,"h1. Test\n\nEin\nTest\n\n");
}

# -----------------------------------------------------------------------------

sub test_code : Test(1) {
    my $self = shift;

    my $gen = Quiq::Confluence::Markup->new;
    
    my $wiki = $gen->code('html/xml',"\nEin\nTest\n\n");
    $self->is($wiki,"\{code:language=html/xml\}\nEin\nTest\n\{code\}\n\n");
}

# -----------------------------------------------------------------------------

sub test_noFormat : Test(1) {
    my $self = shift;

    my $gen = Quiq::Confluence::Markup->new;

    my $text = 'm|/([^/]+)xxx{5}$|';
    my $wiki = $gen->noFormat($text);
    $self->is($wiki,"{noformat:}${text}{noformat}\n\n");
}

# -----------------------------------------------------------------------------

sub test_panel : Test(2) {
    my $self = shift;

    my $gen = Quiq::Confluence::Markup->new;
    
    my $wiki = $gen->panel;
    $self->is($wiki,"\{panel:}\n{panel\}\n\n");

    $wiki = $gen->panel("\nEin\nTest\n\n",-title=>'Test');
    $self->is($wiki,"\{panel:title=Test}\nEin\nTest\n{panel\}\n\n");
}

# -----------------------------------------------------------------------------

sub test_tableOfContents : Test(1) {
    my $self = shift;

    my $gen = Quiq::Confluence::Markup->new;
    
    my $wiki = $gen->tableOfContents;
    $self->is($wiki,"\{toc:\}\n\n");
}

# -----------------------------------------------------------------------------

sub test_fmt : Test(2) {
    my $self = shift;

    my $text = 'Ein Test';
    my $val = Quiq::Confluence::Markup->fmt('bold',$text);
    $self->is($val,"*$text*");

    $val = Quiq::Confluence::Markup->fmt('red',$text);
    $self->is($val,"{color:red}$text\{color}");
}

# -----------------------------------------------------------------------------

package main;
Quiq::Confluence::Markup::Test->runTests;

# eof
