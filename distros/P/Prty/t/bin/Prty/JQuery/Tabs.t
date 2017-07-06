#!/usr/bin/env perl

package Prty::JQuery::Tabs::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::JQuery::Tabs');
}

# -----------------------------------------------------------------------------

sub test_html_1 : Test(2) {
    my $self = shift;

    my $h = Prty::Html::Tag->new;

    my $e = Prty::JQuery::Tabs->new;;
    $self->is(ref($e),'Prty::JQuery::Tabs');

    my $html = $e->html($h);
    $self->is($html,'');
}

sub test_html_2 : Test(1) {
    my $self = shift;

    my $expected = Prty::String->removeIndentationNl(q|
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

    my $h = Prty::Html::Tag->new;

    my $html = Prty::JQuery::Tabs->html($h,
        id=>'tabs',
        tabs=>[
            {
                label=>'A',
                link=>'#a',
                content=>$h->tag('p',
                    -text=>1,
                    'Text des Reiters A',
                ),
            },{
                label=>'B',
                link=>'b',
            },
        ],
    );
    # Prty::Path->write('/tmp/debug',$html);
    $self->is($html,$expected);
}

# -----------------------------------------------------------------------------

package main;
Prty::JQuery::Tabs::Test->runTests;

# eof
