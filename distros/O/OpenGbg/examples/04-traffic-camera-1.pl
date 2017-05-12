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
        $response = $gbg->traffic_camera->get_traffic_cameras;
    }
    catch {
        my $error = $_;
        $error->does('OpenGbg::Exception') ? $error->out->fatal : die $error;
    };

    say $response->camera_devices->get_by_index(1)->to_text;

    foreach my $device ($response->camera_devices->all) {
        say $device->to_text;
    }


    try {
        $response = $gbg->traffic_camera->get_camera_image(1);
    }
    catch {
        my $error = $_;
        $error->does('OpenGbg::Exception') ? $error->out->fatal : die $error;
    };

    say $response->image_size;


}
