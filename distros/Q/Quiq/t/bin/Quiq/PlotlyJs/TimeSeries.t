#!/usr/bin/env perl

package Quiq::PlotlyJs::TimeSeries::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;
use utf8;

use Quiq::Test::Class;
use Quiq::FileHandle;
use Quiq::Epoch;
use Quiq::Html::Producer;
use Quiq::Html::Page;
use Quiq::Path;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::PlotlyJs::TimeSeries');
}

# -----------------------------------------------------------------------------

sub test_unitTest: Test(1) {
    my $self = shift;

    # Zeitreihendaten einlesen

    my $dataFile = Quiq::Test::Class->testPath(
        'quiq/test/data/db/timeseries.dat');
    my $fh = Quiq::FileHandle->new('<',$dataFile);

    my @rows;
    while (<$fh>) {
        if (!/^2007/) {
            next;
        }
        chomp;
        s/^2007/2019/;
        push @rows, $_;
        # Begrenzung der Anzahl der Messwerte
        if (/2019-11-13 00:00:00/) {
            last;
        }
    }
    $fh->close;

    # Koordinaten erstellen

    my (@x,@y);
    for (@rows) {
        my ($iso,$val) = split /\t/;
        push @x,Quiq::Epoch->new($iso)->epoch*1000;
        push @y,$val;
    }

    # Plot-Klasse instantiieren

    my $plt = Quiq::PlotlyJs::TimeSeries->new(
        title => 'Windspeed',
        x => \@x,
        xTickFormat => '%Y-%m-%d %H:%M',
        y => \@y,
        yTitle => 'm/s',
    );
    $self->is(ref($plt),'Quiq::PlotlyJs::TimeSeries');

    # HTML-Seite generieren

    my $h = Quiq::Html::Producer->new;

    my $html = Quiq::Html::Page->html($h,
        title => 'Plotly.js example',
        load => [
            js => 'https://code.jquery.com/jquery-3.4.1.min.js',
            js => $plt->cdnUrl,
        ],
        body => $plt->html($h),
        ready => $plt->js,
    );

    # Seite speichern

    # Gesamtseite

    my $p = Quiq::Path->new;
    my $blobFile = 'Blob/doc-content/quiq-plotlyjs-timeseries.html';
    if ($p->exists('Blob/doc-content') && $p->compareData($blobFile,$html)) {
        $p->write($blobFile,$html);
    }

    # Fragment für Include

    $html =~ s|^<.*\n||mg;
    $html =~ s|^.* />\n||msg;
    $html =~ s|^  ||mg;

    $blobFile = 'Blob/doc-content/quiq-plotlyjs-timeseries-inc.html';
    if ($p->exists('Blob/doc-content') && $p->compareData($blobFile,$html)) {
        $p->write($blobFile,$html);
    }

    my $pod =  "=begin html\n\n$html\n=end html\n";
    $blobFile = 'Blob/doc-content/quiq-plotlyjs-timeseries-inc.pod';
    if ($p->exists('Blob/doc-content') && $p->compareData($blobFile,$pod)) {
        $p->write($blobFile,$pod);
    }
}

# -----------------------------------------------------------------------------

package main;
Quiq::PlotlyJs::TimeSeries::Test->runTests;

# eof
