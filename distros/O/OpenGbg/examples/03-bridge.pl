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
        $response = $gbg->bridge->get_is_currently_open;
    }
    catch {
        my $error = $_;
        $error->does('OpenGbg::Exception') ? $error->out->fatal : die $error;
    };

    say $response->is_open;

    try {
        $response = $gbg->bridge->get_opened_status(DateTime->from_epoch(epoch => time - 86400 * 14)->ymd, DateTime->now->ymd);
    }
    catch {
        my $error = $_;
        $error->does('OpenGbg::Exception') ? $error->out->fatal : die $error;
    };

    for my $index (0..10) {
        my $opening = $response->bridge_openings->get_by_index($index);
        say sprintf '%s %s: %s', $opening->timestamp->ymd, $opening->timestamp->hms, $opening->was_open ? 'open' : 'closed';
        say '' if !$opening->was_open;
    }
    say sprintf 'it was open %s times.', scalar $response->bridge_openings->filter(sub { $_->was_open });

}
