#!/usr/bin/env perl

package Quiq::Gnuplot::Process::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Quiq::Path;
use Quiq::Gnuplot::Plot;
use Quiq::Gnuplot::Graph;
use Quiq::FileHandle;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Gnuplot::Process');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(1) {
    my $self = shift;

    if (!Quiq::Path->findProgram('gnuplot',1)) {
        $self->skipAllTests('Program gnuplot not found');
        return;
    }

    my $gnu = Quiq::Gnuplot::Process->new(
        debug => 0, # 1 schreibt Kommandos nach STDERR
    );
    $self->is(ref($gnu),'Quiq::Gnuplot::Process');

    # XY-Plot

    my $file = '/tmp/graph1.png';
    Quiq::Path->delete($file);

    my $plt = Quiq::Gnuplot::Plot->new(
        terminal => 'png large',
        width => 800,
        height => 500,
        output => $file,
        title => 'Lastverhalten Inkassoserver',
        xlabel => 'Prozesse (lpt-client)',
        ylabel => 'Requests/Sekunde',
        myTics => 0,
    );
    
    my $gph = Quiq::Gnuplot::Graph->new(
        title => undef,
        with => 'linespoints',
        data => [qw/
            1 24
            10 251
            20 524
            30 807
            80 963
        /],
    );
    $plt->add($gph);

    $gph = Quiq::Gnuplot::Graph->new(
        title => 'Lastgrenze System',
        with => 'lines',
        data => [qw/
            0 850
            80 850
        /],
    );
    $plt->add($gph);

    $gph = Quiq::Gnuplot::Graph->new(
        title => 'maximale Tageslast',
        with => 'lines',
        data => [qw/
            0 200
            80 200
        /],
    );
    $plt->add($gph);

    $gph = Quiq::Gnuplot::Graph->new(
        title => 'mittlere Tageslast',
        with => 'lines',
        data => [qw/
            0 130
            80 130
        /],
    );
    $plt->add($gph);

    $gnu->render($plt);

    # Zeitreihe

    $plt = Quiq::Gnuplot::Plot->new(
        timeSeries => 1,
        terminal => 'png large',
        width => 800,
        height => 500,
        output => '/tmp/graph2.png',
        title => 'Zeitreihentest',
        xlabel => 'Zeit',
        ylabel => 'Wert',
    );

    $gph = Quiq::Gnuplot::Graph->new(
        title => '',
        with => 'linespoints',
        data => [
            '2013-10-23 13:26:16',10.3,
            '2013-10-23 13:29:16',10.4,
            '2013-10-23 14:12:16',10.5,
            '2013-10-23 17:34:16',10.6,
        ],
    );
    $plt->add($gph);

    $gnu->render($plt);

    # Performace-Daten

    $plt = Quiq::Gnuplot::Plot->new(
        timeSeries => 1,
        terminal => 'png large',
        width => 1400,
        height => 600,
        output => '/tmp/graph3.png',
        title => 'CPU ALL inka-batch-01',
        xlabel => 'Zeit',
        ylabel => 'Sys% + User%',
        yMin => 0,
        yMax => 100,
        ytics => 10,
        myTics => 0,
    );

    my @data;
    my $datFile = $self->testPath(
        't/data/gnuplot/process/processes.dat');
    my $fh = Quiq::FileHandle->new('<',$datFile);
    while (<$fh>) {
        chomp;
        push @data,(split /\|/)[0,1];
    }
    # warn "@data\n" ;
    $gph = Quiq::Gnuplot::Graph->new(
        title => 'Batch-Prozesse',
        with => 'linespoints',
        data => [@data],
    );
    $plt->add($gph);

    $datFile = $self->testPath(
        't/data/gnuplot/process/cpu_percent.dat');
    @data = split /[|\n]/,Quiq::Path->read($datFile); 
    $gph = Quiq::Gnuplot::Graph->new(
        title => 'Sys% + User% (1 CPU = 6.25%)',
        with => 'lines',
        data => [@data],
    );
    $plt->add($gph);

    $gnu->render($plt);

    # Performace-Daten

    $plt = Quiq::Gnuplot::Plot->new(
        timeSeries => 1,
        terminal => 'png large',
        width => 1400,
        height => 600,
        output => '/tmp/graph4.png',
        title => 'Genutzte CPUs inka-batch-01' ,
        xlabel => 'Zeit',
        ylabel => 'CPUs',
        yMin => 0,
        yMax => 16,
        ytics => 1,
        myTics => 0,
    );

    $datFile = $self->testPath(
        't/data/gnuplot/process/cpu_count.dat');
    @data = split /[|\n]/,Quiq::Path->read($datFile);
    $gph = Quiq::Gnuplot::Graph->new(
        title => 'Genutzte CPUs (mit: Sys + User > 5%)',
        with => 'lines',
        data => [@data],
    );
    $plt->add($gph);

    @data = ();
    $datFile = $self->testPath(
        't/data/gnuplot/process/processes.dat');
    $fh = Quiq::FileHandle->new('<',$datFile);
    while (<$fh>) {
        chomp;
        push @data,(split /\|/)[0,1];
    }
    # warn "@data\n" ;
    $gph = Quiq::Gnuplot::Graph->new(
        title => 'Batch-Prozesse',
        with => 'linespoints',
        # style => 27, # Style-Angabe funktioniert nicht mehr
        data => [@data],
    );
    $plt->add($gph);

    $gnu->render($plt);

    for my $i (1..4) {
        Quiq::Path->delete("/tmp/graph$i.png");
    }
}

# -----------------------------------------------------------------------------

package main;
Quiq::Gnuplot::Process::Test->runTests;

# eof
