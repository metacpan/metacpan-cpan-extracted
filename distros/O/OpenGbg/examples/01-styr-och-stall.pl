#!/usr/bin/env perl

use 5.10.0;
use List::AllUtils 'sum';
use OpenGbg;
use Try::Tiny;

main();

sub main {
    my $gbg = OpenGbg->new;

    my $service;

    try {
        $service = $gbg->styr_och_stall->get_bike_stations;
    }
    catch {
        my $error = $_;
        $error->does('OpenGbg::Exception') ? $error->out->fatal : die $error;
    };

    say sprintf 'Fetched at %s.', $service->timestamp->datetime;

    say sprintf 'Total free bikes:  %4s', sum $service->stations->map( sub { $_->free_bikes });
    say sprintf 'Total free stands: %4s', sum $service->stations->map( sub { $_->free_stands });

    foreach my $station ($service->stations->all) {
        say $station->to_text;
    }

    say '---- empty';
    foreach my $station ($service->stations->filter(sub { $_->empty})) {
        say $station->to_text;
    }
    say '---- full';
    foreach my $station ($service->stations->filter(sub { $_->full})) {
        say $station->to_text;
    }


    say '---';
    my $radius = 400;
    my $lat = '57.7163';
    my $long =  '11.974';
    $service = $gbg->styr_och_stall->get_bike_stations(lat => $lat, long => $long, radius => $radius);
    say sprintf '%s stations within %s metres of %s / %s', $service->stations->count, $radius, $lat, $long;

    foreach my $station ($service->stations->all) {
        say $station->to_text;
    }

    say '----';
    say 'Just station 1:';
    say '';
    $service = $gbg->styr_och_stall->get_bike_station(1);
    say sprintf 'Status at %s', $service->timestamp;
    say $service->station->to_text;

    say 'Most bikes first ----';
    my @most_bikes_first = $gbg->styr_och_stall->get_bike_stations->stations->sort( sub { $_[1]->free_bikes <=> $_[0]->free_bikes });

    foreach my $station (@most_bikes_first) {
        say $station->to_text;
    }

}
