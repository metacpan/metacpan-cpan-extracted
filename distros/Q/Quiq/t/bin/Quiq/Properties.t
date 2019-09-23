#!/usr/bin/env perl

package Quiq::Properties::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Properties');
}

# -----------------------------------------------------------------------------

sub test_new_1 : Test(1) {
    my $self = shift;

    my @values = (
        234.567,
          5.45,
      92345.6,
         42.56739,
    );

    my $prp = Quiq::Properties->new(\@values);

    my $text;
    for (@values) {
        $text .= $prp->format('text',$_)."\n";
    }

    $self->is($text,Quiq::Unindent->string('
        234.56700
          5.45000
      92345.60000
         42.56739
    '));
}

sub test_new_2 : Test(1) {
    my $self = shift;

    my @values = (
        234.567,
          5.45,
      92345.6,
         42.56739,
    );

    my $prp = Quiq::Properties->new(\@values,-noTrailingZeros=>1);

    my $text;
    for (@values) {
        $text .= '|'.$prp->format('text',$_)."|\n";
    }

    $self->is($text,Quiq::Unindent->string('
        |  234.567  |
        |    5.45   |
        |92345.6    |
        |   42.56739|
    '));
}

sub test_new_3 : Test(1) {
    my $self = shift;

    my @values = (
        234.567,
          5.45,
      92345.6,
         42.56739,
    );

    my $prp = Quiq::Properties->new(\@values,-noTrailingZeros=>1);

    my $text;
    for (@values) {
        $text .= '|'.$prp->format('html',$_)."|\n";
    }

    $self->is($text,Quiq::Unindent->string('
        |234.567&nbsp;&nbsp;|
        |5.45&nbsp;&nbsp;&nbsp;|
        |92345.6&nbsp;&nbsp;&nbsp;&nbsp;|
        |42.56739|
    '));
}

# -----------------------------------------------------------------------------

sub test_analyze_1 : Test(10) {
    my $self = shift;

    my $prp = Quiq::Properties->new;

    $prp->analyze(5.12345);
    $self->is($prp->type,'f');
    $self->is($prp->width,7);
    $self->is($prp->[2],2); # floatPrefix
    $self->is($prp->scale,5);
    $self->is($prp->align,'r');

    $prp->analyze(345.123);
    $self->is($prp->type,'f');
    $self->is($prp->width,9);
    $self->is($prp->[2],4); # floatPrefix
    $self->is($prp->scale,5);
    $self->is($prp->align,'r');
}

sub test_analyze_2 : Test(35) {
    my $self = shift;

    my $prp = Quiq::Properties->new;

    $self->is($prp->type,'s');
    $self->is($prp->width,0);
    $self->is($prp->[2],0); # floatPrefix
    $self->is($prp->scale,0);
    $self->is($prp->align,'l');

    $prp->analyze(58);
    $self->is($prp->type,'d');
    $self->is($prp->width,2);
    $self->is($prp->[2],0); # floatPrefix
    $self->is($prp->scale,0);
    $self->is($prp->align,'r');

    $prp->analyze(777.932);
    $self->is($prp->type,'f');
    $self->is($prp->width,7);
    $self->is($prp->[2],4); # floatPrefix
    $self->is($prp->scale,3);
    $self->is($prp->align,'r');

    $prp->analyze(-1234.0);
    $self->is($prp->type,'f');
    $self->is($prp->width,9);
    $self->is($prp->[2],6); # floatPrefix
    $self->is($prp->scale,3);
    $self->is($prp->align,'r');

    $prp->analyze(1.23456);
    $self->is($prp->type,'f');
    $self->is($prp->width,11);
    $self->is($prp->[2],6); # floatPrefix
    $self->is($prp->scale,5);
    $self->is($prp->align,'r');

    $prp->analyze('');
    $self->is($prp->type,'f');
    $self->is($prp->width,11);
    $self->is($prp->[2],6); # floatPrefix
    $self->is($prp->scale,5);
    $self->is($prp->align,'r');

    $prp->analyze('hello world');
    $self->is($prp->type,'s');
    $self->is($prp->width,11);
    $self->is($prp->[2],0); # floatPrefix
    $self->is($prp->scale,0);
    $self->is($prp->align,'l');
}

# -----------------------------------------------------------------------------

sub test_format_1 : Test(15) {
    my $self = shift;

    my $prp = Quiq::Properties->new;

    $prp->analyze('Berlin');
    $prp->analyze('Hamburg');
    $prp->analyze('München');
    $prp->analyze('Rellingen');

    $self->is($prp->format('text','Berlin'),   'Berlin   ');
    $self->is($prp->format('text','Hamburg'),  'Hamburg  ');
    $self->is($prp->format('text','München'),  'München  ');
    $self->is($prp->format('text','Rellingen'),'Rellingen');

    $prp = Quiq::Properties->new;

    $prp->analyze(891.7);
    $prp->analyze(755.21);
    $prp->analyze(370.71);
    $prp->analyze(13.18);

    $self->is($prp->format('text','891.7'), '891.70');
    $self->is($prp->format('text','755.21'),'755.21');
    $self->is($prp->format('text','370.71'),'370.71');
    $self->is($prp->format('text','13.18'), ' 13.18');

    $prp = Quiq::Properties->new;

    $prp->analyze('3421829');
    $prp->analyze('1746342');
    $prp->analyze('1407836');
    $prp->analyze('13691');

    $self->is($prp->format('text','3421829'),'3421829');
    $self->is($prp->format('text','1746342'),'1746342');
    $self->is($prp->format('text','1407836'),'1407836');
    $self->is($prp->format('text','13691'),  '  13691');

    $prp = Quiq::Properties->new;

    $prp->analyze(370.7);
    $prp->analyze(13.18);
    $self->is($prp->format('html',370.7),'370.70');
    $self->is($prp->format('html',13.18), '13.18');

    $prp = Quiq::Properties->new;

    $prp->analyze('1234567890');
    $prp->analyze('22 > 11');
    $self->is($prp->format('html','22 > 11'),'22 &gt; 11');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Properties::Test->runTests;

# eof
