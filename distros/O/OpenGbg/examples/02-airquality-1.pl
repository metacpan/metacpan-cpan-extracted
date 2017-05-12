#!/usr/bin/env perl

use 5.10.0;
use OpenGbg;
use DateTime;
use Try::Tiny;

main();

sub main {
    my $gbg = OpenGbg->new;

    my $response;

    try {
        $response = $gbg->air_quality->get_latest_measurement;
    }
    catch {
        my $error = $_;
        $error->does('OpenGbg::Exception') ? $error->out->fatal : die $error;
    };

    say $response->measurement->to_text;

    try {
        $response = $gbg->air_quality->get_measurements(start => DateTime->from_epoch(epoch => time - 86400 * 15)->ymd('-'),
                                                        end   => DateTime->now->ymd('-'));
    }
    catch {
        my $error = $_;
        $error->does('OpenGbg::Exception') ? $error->out->fatal : die $error;
    };

    foreach my $meas ($response->measurements->all) {
        say $meas->to_text;
    }

    say '-- Hottest hours -------';

    my @hottest_hours_first = $response->measurements->sort( sub { $_[1]->temperature <=> $_[0]->temperature });

    foreach my $i (0..9) {
        my $measurement = $hottest_hours_first[ $i ];
        say $measurement->to_text;
    }


    say '-- Worst hours -------';

    my @worst_hours_first = $response->measurements->sort( sub { $_[1]->total_index <=> $_[0]->total_index });

    foreach my $i (0..9) {
        my $measurement = $worst_hours_first[ $i ];
        say $measurement->to_text;
    }
}
