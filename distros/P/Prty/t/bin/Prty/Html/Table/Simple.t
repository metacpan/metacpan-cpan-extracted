#!/usr/bin/env perl

package Prty::Html::Table::Simple::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

use Prty::Html::Tag;
use Prty::String;
use Prty::Path;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Html::Table::Simple');
}

# -----------------------------------------------------------------------------

sub test_unitTest_1 : Test(2) {
    my $self = shift;

    my $h = Prty::Html::Tag->new;

    my $e = Prty::Html::Table::Simple->new;
    $self->is(ref($e),'Prty::Html::Table::Simple');

    my $html = $e->html($h);
    $self->is($html,qq|<table cellspacing="0"></table>\n|);
}

sub test_unitTest_2 : Test(2) {
    my $self = shift;

    my $expected = Prty::String->removeIndentationNl(<<'    __HTML__');
    <table class="my-table" border="1" cellspacing="0">
    <tr class="my-title">
      <td>A</td>
      <td colspan="2">B</td>
    </tr>
    <tr>
      <td rowspan="2">a1</td>
      <td>de</td>
      <td>Text1_de</td>
    </tr>
    <tr>
      <td>en</td>
      <td>Text1_en</td>
    </tr>
    <tr>
      <td rowspan="2">a2</td>
      <td>de</td>
      <td>Text2_de</td>
    </tr>
    <tr>
      <td>en</td>
      <td>Text2_en</td>
    </tr>
    </table>
    __HTML__

    my $h = Prty::Html::Tag->new;

    my $e = Prty::Html::Table::Simple->new(
        class=>'my-table',
        border=>1,
        rows=>[
            ['my-title',['A'],[colspan=>2,'B']],
            [[rowspan=>2,'a1'],['de'],['Text1_de']],
            [['en'],['Text1_en']],
            [[rowspan=>2,'a2'],['de'],['Text2_de']],
            [['en'],['Text2_en']],
        ],
    );
    $self->is(ref($e),'Prty::Html::Table::Simple');

    my $html = $e->html($h);
    # Prty::Path->write('/tmp/debug',$html);
    $self->is($html,$expected);
}

# -----------------------------------------------------------------------------

package main;
Prty::Html::Table::Simple::Test->runTests;

# eof
