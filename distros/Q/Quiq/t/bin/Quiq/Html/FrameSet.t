#!/usr/bin/env perl

package Quiq::Html::FrameSet::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

use Quiq::Html::Producer;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Html::FrameSet');
}

# -----------------------------------------------------------------------------

sub test_html : Test(5) {
    my $self = shift;

    my $h = Quiq::Html::Producer->new;

    my $html = Quiq::Html::FrameSet->html($h,
        comment => 'Test-Kommentar',
        title => 'Test-Titel',
        frames => [{
                name => 'google1',
                size => '50%',
                url => 'http://google.de',
            },{
                name => 'google2',
                size => '50%',
                url => 'http://google.de',
        }],
    );
    # warn $html;
    $self->like($html,qr/DOCTYPE/,'html: DOCTYPE');
    $self->like($html,qr/<html>/,'html: html');
    $self->like($html,qr/<head>/,'html: head');
    $self->like($html,qr/<frameset/,'html: frameset');
    $self->like($html,qr/<frame/,'html: frame');
}

# -----------------------------------------------------------------------------

package main;
Quiq::Html::FrameSet::Test->runTests;

# eof
