#!/usr/bin/env perl
use strict;
use warnings;
use MyApp;
use Plack::Builder;

MyApp->setup_engine('PSGI');
my $app = sub { MyApp->run(@_) };

builder {
    enable "Plack::Middleware::AutoRefresh", dirs => [ 'root' ];
    $app;
}

