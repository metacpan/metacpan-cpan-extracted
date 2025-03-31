#!/usr/bin/env perl

package Quiq::Json::Code::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;
use utf8;

use Quiq::Html::Producer;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Json::Code');
}

# -----------------------------------------------------------------------------

sub test_encode : Test(13) {
    my $self = shift;

    # Instantiierung

    my $j = Quiq::Json::Code->new;
    $self->is(ref $j,'Quiq::Json::Code');

    # Skalar

    my $json = $j->encode(undef);
    $self->is($json,'undefined');

    $json = $j->encode(5);
    $self->is($json,'5');

    $json = $j->encode(3.14159);
    $self->is($json,'3.14159');

    $json = $j->encode('abc');
    $self->is($json,"'abc'");

    $json = $j->encode(\1);
    $self->is($json,'true');

    $json = $j->encode(\0);
    $self->is($json,'false');

    # Array

    $json = $j->encode([]);
    $self->is($json,'[]');

    $json = $j->encode([undef,5,3.14159,['abc',\1,\0]]);
    $self->is($json,"[undefined,5,3.14159,['abc',true,false]]");

    # Hash

    $json = $j->encode({});
    $self->is($json,'{}');

    $json = $j->encode({a=>1,b=>2});
    $self->is($json,'{a:1,b:2}');

    # Array of Hashes

    $json = $j->encode([{a=>1},{b=>2}]);
    $self->is($json,'[{a:1},{b:2}]');

    $json = $j->encode({
        pi => 3.14159,
        str => 'Hello world!',
        bool => \1,
        obj => {
            id => 4711,
            name => 'Wall',
            numbers => [1..5],
        },
        min => undef,
    });
    $self->is($json,"{bool:true,obj:{id:4711,name:'Wall',".
        "numbers:[1,2,3,4,5]},pi:3.14159,str:'Hello world!'}");
}

# -----------------------------------------------------------------------------

sub test_object : Test(6) {
    my $self = shift;

    # Instantiierung

    my $j = Quiq::Json::Code->new;
    $self->is(ref $j,'Quiq::Json::Code');

    # Object

    my $json = $j->object(
        a => 1,
        b => 'xyz',
    );
    $self->isText("$json\n",q~
        {
            a: 1,
            b: 'xyz',
        }
    ~);

    # Objekt (ohne Einrückung)

    $json = $j->object(
        -indent => 0,
        a => 1,
        b => 2,
    );
    $self->is($json,'{a:1,b:2}');

    # Geschachtelte Objekte

    $json = $j->object(
        a => 1,
        b => $j->object(
            c => 2,
        ),
    );
    $self->isText("$json\n",q~
        {
            a: 1,
            b: {
                c: 2,
            },
        }
    ~);

    # Kompliziertere Struktur

    $json = $j->object(
        pi => 3.14159,
        str => 'Hello world!',
        bool => \1,
        obj => $j->object(
            id => 4711,
            name => 'Wall',
            numbers => [1..5],
        ),
        min => undef,
    );
    #$self->isText("$json\n",q~
    #    {
    #        pi: 3.14159,
    #        str: 'Hello world!',
    #        bool: true,
    #        obj: {
    #            id: 4711,
    #            name: 'Wall',
    #            numbers: [1,2,3,4,5],
    #        },
    #        min: undefined,
    #    }
    #~);
    $self->isText("$json\n",q~
        {
            pi: 3.14159,
            str: 'Hello world!',
            bool: true,
            obj: {
                id: 4711,
                name: 'Wall',
                numbers: [1,2,3,4,5],
            },
        }
    ~);

    my @dataSets;
    my $name = 'Windspeed';
    my $title = $name;
    my $unit = 'm/s';
    my $tMin = undef;
    my $tMax = undef;
    my $yMin = 0;
    my $yMax = undef;

    $json = $j->o(
        type => 'line',
        data => $j->o(
            datasets => \@dataSets,
        ),
        options => $j->o(
            maintainAspectRatio => \'false',
            title => $j->o(
                display => \'true',
                text => $title,
                fontSize => 16,
                fontStyle => 'normal',
            ),
            tooltips => $j->o(
                intersect => \'false',
                displayColors => \'false',
                backgroundColor => 'rgb(0,0,0,0.6)',
                titleMarginBottom => 2,
                callbacks => $j->o(
                    label => $j->c(qq~
                        function(tooltipItem,data) {
                            var i = tooltipItem.datasetIndex;
                            var label = data.datasets[i].label || '';
                            if (label)
                                label += ': ';
                            label += tooltipItem.value + ' $unit';
                            return label;
                        }
                    ~),
                ),
            ),
            legend => $j->o(
                display => \'false',
            ),
            scales => $j->o(
                xAxes => [$j->o(
                    type => 'time',
                    ticks => $j->o(
                        minRotation => 30,
                        maxRotation => 60,
                    ),
                    time => $j->o(
                        min => $tMin,
                        max => $tMax,
                        minUnit => 'second',
                        displayFormats => $j->o(
                            second => 'YYYY-MM-DD HH:mm:ss',
                            minute => 'YYYY-MM-DD HH:mm',
                            hour => 'YYYY-MM-DD HH',
                            day => 'YYYY-MM-DD',
                            week => 'YYYY-MM-DD',
                            month => 'YYYY-MM',
                            quarter => 'YYYY [Q]Q',
                            year => 'YYYY',
                        ),
                        tooltipFormat => 'YYYY-MM-DD HH:mm:ss',
                    ),
                )],
                yAxes => [$j->o(
                    ticks => $j->o(
                        min => $yMin,
                        max => $yMax,
                    ),
                    scaleLabel => $j->o(
                        display => \'true',
                        labelString => $unit,
                    ),
                )],
            ),
        ),
    );
    $self->isText("$json\n",q~
        {
            type: 'line',
            data: {
                datasets: [],
            },
            options: {
                maintainAspectRatio: false,
                title: {
                    display: true,
                    text: 'Windspeed',
                    fontSize: 16,
                    fontStyle: 'normal',
                },
                tooltips: {
                    intersect: false,
                    displayColors: false,
                    backgroundColor: 'rgb(0,0,0,0.6)',
                    titleMarginBottom: 2,
                    callbacks: {
                        label: function(tooltipItem,data) {
                            var i = tooltipItem.datasetIndex;
                            var label = data.datasets[i].label || '';
                            if (label)
                                label += ': ';
                            label += tooltipItem.value + ' m/s';
                            return label;
                        },
                    },
                },
                legend: {
                    display: false,
                },
                scales: {
                    xAxes: [{
                        type: 'time',
                        ticks: {
                            minRotation: 30,
                            maxRotation: 60,
                        },
                        time: {
                            minUnit: 'second',
                            displayFormats: {
                                second: 'YYYY-MM-DD HH:mm:ss',
                                minute: 'YYYY-MM-DD HH:mm',
                                hour: 'YYYY-MM-DD HH',
                                day: 'YYYY-MM-DD',
                                week: 'YYYY-MM-DD',
                                month: 'YYYY-MM',
                                quarter: 'YYYY [Q]Q',
                                year: 'YYYY',
                            },
                            tooltipFormat: 'YYYY-MM-DD HH:mm:ss',
                        },
                    }],
                    yAxes: [{
                        ticks: {
                            min: 0,
                        },
                        scaleLabel: {
                            display: true,
                            labelString: 'm/s',
                        },
                    }],
                },
            },
        }
    ~);

    # Zusammenspiel ausprobieren
    #
    # my $h = Quiq::Html::Producer->new;
    # my $html = $h->tag('script',
    #     -placeholders => [
    #         __NAME__ => 'plot',
    #         __CONFIG__ => $json,
    #     ],q~
    #     Chart.defaults.global.defaultFontSize = 12;
    #     Chart.defaults.global.animation.duration = 1000;
    #
    #     var __NAME__ = new Chart('__NAME__',__CONFIG__);
    # ~);
    # $self->diag($html);
}

# -----------------------------------------------------------------------------

sub test_key : Test(2) {
    my $self = shift;

    my $j = Quiq::Json::Code->new;
 
    my $json = $j->key('borderWidth');
    $self->is($json,'borderWidth');

    $json = $j->key('border-width');
    $self->is($json,"'border-width'");
}

# -----------------------------------------------------------------------------

package main;
Quiq::Json::Code::Test->runTests;

# eof
