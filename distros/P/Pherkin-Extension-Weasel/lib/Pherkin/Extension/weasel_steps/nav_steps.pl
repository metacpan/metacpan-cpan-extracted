#!perl

use strict;
use warnings;

use Test::BDD::Cucumber::StepFile;

When qr/I navigate to '(.*)'/, sub {
    my $url = $1;

    S->{ext_wsl}->get($url);
};

1;
