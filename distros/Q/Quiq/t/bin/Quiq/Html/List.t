#!/usr/bin/env perl

package Quiq::Html::List::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

use Quiq::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Html::List');
}

# -----------------------------------------------------------------------------

sub test_html_unordered : Test(2) {
    my $self = shift;

    my $html01 = Quiq::String->removeIndentationNl(q|
        <ul id="list01" class="list">
          <li>Apfel &amp; Birne</li>
          <li>Orange</li>
          <li>Pflaume</li>
          <li>Zitrone</li>
        </ul>
    |);

    my $h = Quiq::Html::Tag->new;

    # Unordered List

    my $c = Quiq::Html::List->new(
        id => 'list01',
        class => 'list',
        isText => 1,
        items => ['Apfel & Birne','Orange','Pflaume','Zitrone'],
    );
    $self->is(ref($c),'Quiq::Html::List');

    my $html = $c->html($h);
    $self->is($html,$html01);
}

sub test_html_ordered : Test(2) {
    my $self = shift;

    my $html01 = Quiq::String->removeIndentationNl(q|
        <ol id="list01" class="list">
          <li>Apfel &amp; Birne</li>
          <li>Orange</li>
          <li>Pflaume</li>
          <li>Zitrone</li>
        </ol>
    |);

    my $h = Quiq::Html::Tag->new;

    # Unordered List

    my $c = Quiq::Html::List->new(
        type => 'ordered',
        id => 'list01',
        class => 'list',
        isText => 1,
        items => ['Apfel & Birne','Orange','Pflaume','Zitrone'],
    );
    $self->is(ref($c),'Quiq::Html::List');

    my $html = $c->html($h);
    $self->is($html,$html01);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Html::List::Test->runTests;

# eof
