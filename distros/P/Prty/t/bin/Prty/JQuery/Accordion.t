#!/usr/bin/env perl

package Prty::JQuery::Accordion::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::JQuery::Accordion');
}

# -----------------------------------------------------------------------------

sub test_html_1 : Test(2) {
    my $self = shift;

    my $h = Prty::Html::Tag->new;

    my $e = Prty::JQuery::Accordion->new;;
    $self->is(ref($e),'Prty::JQuery::Accordion');

    my $html = $e->html($h);
    $self->is($html,'');
}

sub test_html_2 : Test(1) {
    my $self = shift;

    my $expected = Prty::String->removeIndentationNl(q|
        <div id="accordion">
          <h3><a href="a">A</a></h3>
          <div></div>
          <h3>B</h3>
          <div>
            <p>
              Text des Reiters B
            </p>
          </div>
        </div>
    |);

    my $h = Prty::Html::Tag->new;

    my $html = Prty::JQuery::Accordion->html($h,
        id=>'accordion',
        tabs=>[
            {
                label=>'A',
                link=>'a',
            },{
                label=>'B',
                content=>$h->tag('p',
                    -text=>1,
                    'Text des Reiters B',
                ),
            },
        ],
    );
    # Prty::Path->write('/tmp/debug',$html);
    $self->is($html,$expected);
}

# -----------------------------------------------------------------------------

package main;
Prty::JQuery::Accordion::Test->runTests;

# eof
