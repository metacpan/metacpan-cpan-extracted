#!/usr/bin/env perl

package Quiq::JQuery::Accordion::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Quiq::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::JQuery::Accordion');
}

# -----------------------------------------------------------------------------

sub test_html_1 : Test(2) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new;

    my $e = Quiq::JQuery::Accordion->new;;
    $self->is(ref($e),'Quiq::JQuery::Accordion');

    my $html = $e->html($h);
    $self->is($html,'');
}

sub test_html_2 : Test(1) {
    my $self = shift;

    my $expected = Quiq::String->removeIndentationNl(q|
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

    my $h = Quiq::Html::Tag->new;

    my $html = Quiq::JQuery::Accordion->html($h,
        id => 'accordion',
        tabs => [
            {
                label => 'A',
                link => 'a',
            },{
                label => 'B',
                content => $h->tag('p',
                    -text => 1,
                    'Text des Reiters B',
                ),
            },
        ],
    );
    # Quiq::Path->write('/tmp/debug',$html);
    $self->is($html,$expected);
}

# -----------------------------------------------------------------------------

package main;
Quiq::JQuery::Accordion::Test->runTests;

# eof
