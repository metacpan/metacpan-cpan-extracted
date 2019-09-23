#!/usr/bin/env perl

package Quiq::Timeseries::Synchronizer::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Timeseries::Synchronizer');
}

# -----------------------------------------------------------------------------

sub test_new_1 : Test(7) {
    my $self = shift;

    my $obj = Quiq::Timeseries::Synchronizer->new(600,
        qw/Latitude Longitude WindSpeed/,
    );
    $self->is(ref($obj),'Quiq::Timeseries::Synchronizer');

    my $val = $obj->get('interval');
    $self->is($val,600);

    $val = $obj->get('minTime');
    $self->is($val,undef);

    $val = $obj->get('maxTime');
    $self->is($val,undef);

    $val = $obj->get('offset');
    $self->is($val,0);

    $val = $obj->get('window');
    $self->is($val,undef);

    my @arr = $obj->parameters;
    $self->isDeeply(\@arr,[qw/Latitude Longitude WindSpeed/]);
}

sub test_new_2 : Test(7) {
    my $self = shift;

    my $obj = Quiq::Timeseries::Synchronizer->new(600,
        qw/Latitude Longitude Temperature/,
        -minTime => 1000,
        -maxTime => 2000,
        -offset => 300,
        -window => 200,
    );
    $self->is(ref($obj),'Quiq::Timeseries::Synchronizer');

    my $val = $obj->get('interval');
    $self->is($val,600);

    $val = $obj->get('minTime');
    $self->is($val,1000);

    $val = $obj->get('maxTime');
    $self->is($val,2000);

    $val = $obj->get('offset');
    $self->is($val,300);

    $val = $obj->get('window');
    $self->is($val,200);

    my @arr = $obj->parameters;
    $self->isDeeply(\@arr,[qw/Latitude Longitude Temperature/]);
}

# -----------------------------------------------------------------------------

sub test_add : Test(10) {
    my $self = shift;

    # Rasterpunkt : Werte
    #  0: 0 1 2 3 4
    # 10: 5 6 7 8 9 10 11 12 13 14
    # 20: 15 16 17 18 19 20 21 22 23 24
    # 30: 25 26 27 28 29 30 31 32 33 34
    # 40: 35 36 37 38 39 40 41 42 43 44
    # 50: 45 46 47 48 49 50 51 52 53 54
    # 60: 55 56 57 58 59

    my $tsy = Quiq::Timeseries::Synchronizer->new(10,'P1');
    my $param1 = 'P1';
    for (my $i = 0; $i < 60; $i += 1) {
        $tsy->add($i,$param1=>$i);
    }

    my @points = sort keys %{$tsy->{'raster'}};
    $self->isDeeply(\@points,[0,10,20,30,40,50,60]);

    my $arr = $tsy->{'raster'}->{0}->{'P1'}->[0];
    $self->isDeeply($arr,[0..4]);

    $arr = $tsy->{'raster'}->{10}->{'P1'}->[0];
    $self->isDeeply($arr,[5..14]);

    my $val = $tsy->{'raster'}->{10}->{'P1'}->[2];
    $self->is($val,0);

    $val = $tsy->{'raster'}->{10}->{'P1'}->[3];
    $self->is($val,10);

    $arr = $tsy->{'raster'}->{20}->{'P1'}->[0];
    $self->isDeeply($arr,[15..24]);

    $arr = $tsy->{'raster'}->{30}->{'P1'}->[0];
    $self->isDeeply($arr,[25..34]);

    $arr = $tsy->{'raster'}->{40}->{'P1'}->[0];
    $self->isDeeply($arr,[35..44]);

    $arr = $tsy->{'raster'}->{50}->{'P1'}->[0];
    $self->isDeeply($arr,[45..54]);

    $arr = $tsy->{'raster'}->{60}->{'P1'}->[0];
    $self->isDeeply($arr,[55..59]);

    $self->set(tsy=>$tsy);
}

# -----------------------------------------------------------------------------

sub test_addParameter : Test(2) {
    my $self = shift;

    my $tsy = Quiq::Timeseries::Synchronizer->new(10);

    my @params = $tsy->parameters;
    $self->isDeeply(\@params,[]);

    $tsy->addParameter('Latitude');
    $tsy->add(10,'Latitude',8.76);

    $tsy->addParameter('Longitude');
    $tsy->add(10,'Longitude',52.2);

    $tsy->addParameter('Temperature');
    $tsy->add(10,'Temperature',13.7);

    my $params = $tsy->parameters;
    $self->isDeeply($params,[qw/Latitude Longitude Temperature/]);
}

# -----------------------------------------------------------------------------

sub test_parameters : Test(2) {
    my $self = shift;

    my $tsy = Quiq::Timeseries::Synchronizer->new(10,
        qw/Latitude Longitude Temperature/,
    );
    $tsy->add(10,'Latitude',8.76);
    $tsy->add(10,'Longitude',52.2);
    $tsy->add(10,'Temperature',13.7);

    $tsy->add(20,'Latitude',8.76);
    $tsy->add(20,'Longitude',52.2);
    $tsy->add(20,'Temperature',14.2);

    my @params = $tsy->parameters;
    $self->isDeeply(\@params,[qw/Latitude Longitude Temperature/]);

    my $params = $tsy->parameters;
    $self->isDeeply($params,[qw/Latitude Longitude Temperature/]);
}

# -----------------------------------------------------------------------------

sub test_rows : Test(2) {
    my $self = shift;

    # Rasterpunkt : Werte
    #  0: 0 1 2 3 4
    # 10: 5 6 7 8 9 10 11 12 13 14
    # 20: 15 16 17 18 19 20 21 22 23 24
    # 30: 25 26 27 28 29 30 31 32 33 34
    # 40: 35 36 37 38 39 40 41 42 43 44
    # 50: 45 46 47 48 49 50 51 52 53 54
    # 60: 55 56 57 58 59

    my $param = 'P1';

    my $tsy = Quiq::Timeseries::Synchronizer->new(10,$param);
    for (my $i = 0; $i < 60; $i += 1) {
        $tsy->add($i,$param=>$i);
    }

    my $optA = [
        count => 1,
        meanValue => 1,
        closestValue => 1,
        closestTime => 1,
        min => 1,
        max => 1,
        stdDeviation => 1,
        roundTo => 2,
        stdDeviation => 1,
    ];
    my ($titleA,$rowA) = $tsy->rows(
        $param => $optA,
        -timeFormat => 'yyyymmddxhhmmss',
        -noValue => 'NULL',
    );

    my @expectedTitles = qw/Time P1_Count P1 P1_ClosestValue P1_ClosestTime
        P1_Min P1_Max P1_StdDev P1_StdDev/;
    $self->isDeeply($titleA,\@expectedTitles);

    my @expectedRows = (
        [qw/1970-01-01+00:00:00 5 2 0 0 0 4 1.58113883008419 1.58/],
        [qw/1970-01-01+00:00:10 10 9.5 10 0 5 14 3.02765035409749 3.03/],
        [qw/1970-01-01+00:00:20 10 19.5 20 0 15 24 3.02765035409749 3.03/],
        [qw/1970-01-01+00:00:30 10 29.5 30 0 25 34 3.02765035409749 3.03/],
        [qw/1970-01-01+00:00:40 10 39.5 40 0 35 44 3.02765035409749 3.03/],
        [qw/1970-01-01+00:00:50 10 49.5 50 0 45 54 3.02765035409749 3.03/],
        [qw/1970-01-01+00:01:00 5 57 59 1 55 59 1.58113883008419 1.58/],
    );

    # Fix: CPAN Testers
    for my $row (@$rowA) {
        $row->[7] = sprintf '%.14f',$row->[7];
    }

    $self->isDeeply($rowA,\@expectedRows);
}

# -----------------------------------------------------------------------------

sub test_rows_geoPosition : Test(2) {
    my $self = shift;

    # Rasterpunkt : Werte
    #  0: 
    # 10: 
    # 20: 

    my $param = 'Temperature';

    my $tsy = Quiq::Timeseries::Synchronizer->new(10,$param,
        -geoCoordinates => 1,
    );
    $tsy->add(2,40.7143528,-74.0059731,$param=>52);
    $tsy->add(3,41.8781136,-87.6297982,$param=>64);
    $tsy->add(4,33.7489954,-84.3879824,$param=>73);

    my $optA = [
        count => 1,
        meanValue => 1,
    ];
    my ($titleA,$rowA) = $tsy->rows(
        $param => [meanValue=>1,count=>1],
        -timeFormat => 'yyyymmddxhhmmss',
        -noValue => 'NULL',
    );

    my @expectedTitles = qw/Time Latitude Longitude Temperature
        Temperature_Count/;
    $self->isDeeply($titleA,\@expectedTitles);

    my @expectedRows = (
        [qw/1970-01-01+00:00:00 38.9224184710314 -82.0561504698106 63 3/],
    );

    # Fix: CPAN Testers
    for my $row (@$rowA) {
        $row->[1] = sprintf '%.13f',$row->[1];
        $row->[2] = sprintf '%.13f',$row->[2];
    }

    $self->isDeeply($rowA,\@expectedRows);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Timeseries::Synchronizer::Test->runTests;

# eof
