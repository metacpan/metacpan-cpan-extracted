#!/usr/bin/env perl

package Quiq::JQuery::Tabs::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Quiq::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::JQuery::Tabs');
}

# -----------------------------------------------------------------------------

sub test_html_1 : Test(2) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new;

    my $e = Quiq::JQuery::Tabs->new;;
    $self->is(ref($e),'Quiq::JQuery::Tabs');

    my $html = $e->html($h);
    $self->is($html,'');
}

sub test_html_2 : Test(1) {
    my $self = shift;

    my $expected = Quiq::String->removeIndentationNl(q|
        <div id="tabs">
          <ul>
            <li><a href="#a">A</a></li>
            <li><a href="b">B</a></li>
          </ul>
          <div id="a">
            <p>
              Text des Reiters A
            </p>
          </div>
        </div>
    |);

    my $h = Quiq::Html::Tag->new;

    my $html = Quiq::JQuery::Tabs->html($h,
        id => 'tabs',
        tabs => [
            {
                label => 'A',
                link => '#a',
                content => $h->tag('p',
                    -text => 1,
                    'Text des Reiters A',
                ),
            },{
                label => 'B',
                link => 'b',
            },
        ],
    );
    # Quiq::Path->write('/tmp/debug',$html);
    $self->is($html,$expected);
}

# -----------------------------------------------------------------------------

package main;
Quiq::JQuery::Tabs::Test->runTests;

# eof
