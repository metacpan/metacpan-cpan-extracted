#!/usr/bin/env perl

package Prty::Html::Listing::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Html::Listing');
}

# -----------------------------------------------------------------------------

sub test_newNoParameters : Test(2) {
    my $self = shift;

    my $obj = Prty::Html::Listing->new;
    $self->is(ref($obj),'Prty::Html::Listing','new: Klasse');

    my $val = $obj->get('lineNumbers');
    $self->is($val,1,'new: lineNumbers');
}

sub test_newAllParameters : Test(2) {
    my $self = shift;

    my $obj = Prty::Html::Listing->new(
        lineNumbers=>0,
        source=>'/tmp/test.pl',
    );

    my $val = $obj->get('lineNumbers');
    $self->is($val,0,'new: lineNumbers');

    $val = $obj->get('source');
    $self->is($val,'/tmp/test.pl','new: source');
}

# -----------------------------------------------------------------------------

sub test_html : Test(9) {
    my $self = shift;

    my $source = "Zeile 1\nZeile 2\nZeile 3\n";

    use Prty::Html::Tag;
    my $h = Prty::Html::Tag->new;

    my $html = Prty::Html::Listing->html($h,
        id=>'t45',
        cssPrefix=>'xxx',
        source=>\$source,
    );

    $self->like($html,qr/id="t45"/,'html: id');
    $self->like($html,qr/xxx-table/,'html: table');
    $self->like($html,qr/xxx-tr-odd/,'html: tr-odd');
    $self->like($html,qr/xxx-tr-even/,'html: tr-even');
    $self->like($html,qr/xxx-td-ln/,'html: td-ln');
    $self->like($html,qr/xxx-td-line/,'html: td-line');

    $self->like($html,qr/Zeile 1/,'html: Zeile 1');
    $self->like($html,qr/Zeile 2/,'html: Zeile 2');
    $self->like($html,qr/Zeile 3/,'html: Zeile 3');
}

# -----------------------------------------------------------------------------

package main;
Prty::Html::Listing::Test->runTests;

# eof
