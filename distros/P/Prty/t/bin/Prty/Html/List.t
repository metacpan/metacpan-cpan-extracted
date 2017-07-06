#!/usr/bin/env perl

package Prty::Html::List::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Html::List');
}

# -----------------------------------------------------------------------------

sub test_html_unordered : Test(2) {
    my $self = shift;

    my $html01 = Prty::String->removeIndentationNl(q|
        <ul id="list01" class="list">
          <li>Apfel &amp; Birne</li>
          <li>Orange</li>
          <li>Pflaume</li>
          <li>Zitrone</li>
        </ul>
    |);

    my $h = Prty::Html::Tag->new;

    # Unordered List

    my $c = Prty::Html::List->new(
        id=>'list01',
        class=>'list',
        isText=>1,
        items=>['Apfel & Birne','Orange','Pflaume','Zitrone'],
    );
    $self->is(ref($c),'Prty::Html::List');

    my $html = $c->html($h);
    $self->is($html,$html01);
}

sub test_html_ordered : Test(2) {
    my $self = shift;

    my $html01 = Prty::String->removeIndentationNl(q|
        <ol id="list01" class="list">
          <li>Apfel &amp; Birne</li>
          <li>Orange</li>
          <li>Pflaume</li>
          <li>Zitrone</li>
        </ol>
    |);

    my $h = Prty::Html::Tag->new;

    # Unordered List

    my $c = Prty::Html::List->new(
        type=>'ordered',
        id=>'list01',
        class=>'list',
        isText=>1,
        items=>['Apfel & Birne','Orange','Pflaume','Zitrone'],
    );
    $self->is(ref($c),'Prty::Html::List');

    my $html = $c->html($h);
    $self->is($html,$html01);
}

# -----------------------------------------------------------------------------

package main;
Prty::Html::List::Test->runTests;

# eof
